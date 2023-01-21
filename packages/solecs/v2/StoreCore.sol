// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { SchemaType } from "./SchemaType.sol";
import { memToStorage, storageToMem } from "./storage.sol";
import { Pack } from "./Pack.sol";

library StoreCore {
  error StoreCore__InvalidDataLength();
  error StoreCore__SchemaSizeOverflow();
  error StoreCore__DynamicColumnDataIndexOutOfBounds();

  // note: the preimage of the tuple of keys used to index is part of the event, so it can be used by indexers
  event StoreUpdate(bytes32 table, bytes32[] key, bytes data, uint8 schemaIndex, uint16 dataIndex);

  // Schema fits into a word: 1 byte for length, 31 for values
  uint256 constant MAX_SCHEMA_LENGTH = 31;

  bytes32 constant _salt_schema = keccak256("mud.store.table.schema");
  bytes32 constant _salt_data = keccak256("mud.store");

  function _slot_schema(bytes32 table) private pure returns (uint256) {
    return uint256(keccak256(abi.encode(_salt_schema, table)));
  }

  function _slot_data(bytes32 table, bytes32[] memory key) private pure returns (uint256) {
    return uint256(keccak256(abi.encode(_salt_data, table, key)));
  }

  function _slot_dataSeparate(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaIndex
  ) private pure returns (uint256) {
    return uint256(keccak256(abi.encode(_salt_data, table, key, schemaIndex)));
  }

  /*//////////////////////////////////////////////////////////////////////////
                                  Schema
  //////////////////////////////////////////////////////////////////////////*/

  // Register a new schema
  // Stores the schema in the default "schema table", indexed by table id
  function registerSchema(bytes32 table, SchemaType[] memory schema) internal {
    if (schema.length > MAX_SCHEMA_LENGTH) revert StoreCore__SchemaSizeOverflow();

    uint256 value;
    // store length in MSB
    value = schema.length << (31 * 8);
    // store values after MSB, sequentially moving to LSB
    for (uint256 i; i < schema.length; i++) {
      uint256 shift = (32 - i - 2) * 8;
      value = value | (uint256(schema[i]) << shift);
    }

    uint256 slot = _slot_schema(table);
    assembly {
      sstore(slot, value)
    }
  }

  // Return the schema of a table
  function getSchema(bytes32 table) internal view returns (SchemaType[] memory schema) {
    uint256 slot = _slot_schema(table);

    bytes32 value;
    uint256 length;
    assembly {
      value := sload(slot)
      // get length from MSB
      length := byte(0, value)
    }

    schema = new SchemaType[](length);
    // get values after MSB, sequentially moving to LSB
    for (uint256 i; i < length; i++) {
      schema[i] = SchemaType(uint8(value[i + 1]));
    }
  }

  // Check whether a schema exists for a given table
  function hasSchema(bytes32 table) internal view returns (bool) {
    uint256 slot = _slot_schema(table);

    uint256 length;
    assembly {
      // get length from MSB
      length := byte(0, sload(slot))
    }
    return length > 0;
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Static data setters
  //////////////////////////////////////////////////////////////////////////*/

  // Set full static data
  function setStaticData(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data
  ) internal {
    // Verify data matches schema length
    SchemaType[] memory schema = getSchema(table);
    if (data.length != _getStaticSliceLength(schema, 0, schema.length)) {
      revert StoreCore__InvalidDataLength();
    }

    // Store the provided value in storage
    uint256 slot = _slot_data(table, key);
    memToStorage(slot, 0, data, false);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, data, 0, 0);
  }

  // Set an individual static data column
  function setStaticDataColumn(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data,
    uint256 schemaIndex
  ) internal {
    // Verify data matches schema length
    SchemaType[] memory schema = getSchema(table);
    if (data.length != schema[schemaIndex].staticLength()) {
      revert StoreCore__InvalidDataLength();
    }

    // Get offset storage slot
    uint256 slot = _slot_data(table, key);
    uint256 slotByteOffset = _getStaticSliceLength(schema, 0, schemaIndex);

    // Store the provided value in storage
    memToStorage(slot, slotByteOffset, data, true);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, data, uint8(schemaIndex), 0);
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Static data getters
  //////////////////////////////////////////////////////////////////////////*/

  // Get full static data
  function getStaticData(bytes32 table, bytes32[] memory key) internal view returns (bytes memory) {
    // Get storage slot
    uint256 slot = _slot_data(table, key);
    // Get data length using schema
    SchemaType[] memory schema = getSchema(table);
    uint256 length = _getStaticSliceLength(schema, 0, schema.length);
    // Get data from storage
    return storageToMem(slot, 0, length);
  }

  // Get full static data using the provided length
  function getStaticData(
    bytes32 table,
    bytes32[] memory key,
    uint256 length
  ) internal view returns (bytes memory) {
    // Get storage slot
    uint256 slot = _slot_data(table, key);
    // Get data from storage
    return storageToMem(slot, 0, length);
  }

  // Get an individual static data column
  function getStaticDataColumn(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaIndex
  ) internal view returns (bytes memory data) {
    // Get schema to compute storage offset and provide static cell sizes
    SchemaType[] memory schema = getSchema(table);

    // Get offset storage slot
    uint256 slot = _slot_data(table, key);
    uint256 slotByteOffset = _getStaticSliceLength(schema, 0, schemaIndex);
    // Get data length
    uint256 length = schema[schemaIndex].staticLength();

    // Get data from storage
    return storageToMem(slot, slotByteOffset, length);
  }

  // TODO this method is possibly unnecessary and mostly untested
  // Get a slice of static columns
  function getStaticDataSlice(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaStart,
    uint256 schemaEnd
  ) internal view returns (bytes memory data) {
    // Get schema to compute storage offset and provide static cell sizes
    SchemaType[] memory schema = getSchema(table);

    // Get offset storage slot
    uint256 slot = _slot_data(table, key);
    uint256 slotByteOffset = _getStaticSliceLength(schema, 0, schemaStart);
    // Get data length
    uint256 length = _getStaticSliceLength(schema, schemaStart, schemaEnd);

    // Get data from storage
    return storageToMem(slot, slotByteOffset, length);
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Dynamic data setters
  //////////////////////////////////////////////////////////////////////////*/

  // Set a dynamic data column
  function setDynamicDataColumn(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data,
    uint256 schemaIndex
  ) internal {
    // Verify data matches schema and is correctly packed
    SchemaType[] memory schema = getSchema(table);
    schema[schemaIndex].requireDynamic();
    Pack.verifyDynamicValue(data);

    // Store the provided value in storage
    uint256 slot = _slot_dataSeparate(table, key, schemaIndex);
    memToStorage(slot, 0, data, false);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, data, uint8(schemaIndex), 0);
  }

  // TODO untested
  // Set an individual item of a dynamic data column
  function setDynamicDataColumnItem(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data,
    uint256 schemaIndex,
    uint256 dataIndex
  ) internal {
    // Verify data fits in one item of schema type (`unitStaticLength` reverts if not dynamic)
    SchemaType[] memory schema = getSchema(table);
    uint256 unitLength = schema[schemaIndex].unitStaticLength();
    if (data.length != unitLength) {
      revert StoreCore__InvalidDataLength();
    }

    // Get offset storage slot
    uint256 slot = _slot_dataSeparate(table, key, schemaIndex);
    uint256 slotByteOffset = unitLength * dataIndex;

    // Data index must be within bounds
    uint256 length = _getDynamicCellLength(slot);
    if (slotByteOffset >= length) {
      revert StoreCore__DynamicColumnDataIndexOutOfBounds();
    }

    // Store the provided value in storage
    memToStorage(slot, slotByteOffset, data, true);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, data, uint8(schemaIndex), uint16(dataIndex));
  }

  // TODO untested
  // Push an individual item into a dynamic data column
  function pushDynamicDataColumnItem(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data,
    uint256 schemaIndex
  ) internal {
    // Verify data fits in one item of schema type (`unitStaticLength` reverts if not dynamic)
    SchemaType[] memory schema = getSchema(table);
    uint256 unitLength = schema[schemaIndex].unitStaticLength();
    if (data.length != unitLength) {
      revert StoreCore__InvalidDataLength();
    }

    // Get storage slot
    uint256 slot = _slot_dataSeparate(table, key, schemaIndex);

    // Get the current byte length, which is used for the new index
    uint256 length = _getDynamicCellLength(slot);
    uint256 dataIndex = length / unitLength;
    // Increment length
    memToStorage(slot, 0, Pack.packLength(length + unitLength), true);

    // Store the provided value in storage
    memToStorage(slot, length, data, true);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, data, uint8(schemaIndex), uint16(dataIndex));
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Dynamic data getters
  //////////////////////////////////////////////////////////////////////////*/

  // Get an individual dynamic data column
  function getDynamicDataColumn(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaIndex
  ) internal view returns (bytes memory data) {
    // Get schema to compute storage offset and verify data
    SchemaType[] memory schema = getSchema(table);
    schema[schemaIndex].requireDynamic();

    // Get storage slot
    uint256 slot = _slot_dataSeparate(table, key, schemaIndex);
    // Get dynamic data length
    uint256 length = _getDynamicCellLength(slot);

    // Get data from storage
    data = storageToMem(slot, 0, length);
  }

  // TODO untested
  // Get an individual item from a dynamic data column
  function getDynamicDataColumnItem(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaIndex,
    uint256 dataIndex
  ) internal view returns (bytes memory data) {
    SchemaType[] memory schema = getSchema(table);
    // Get unit length and verify data (`unitStaticLength` reverts if not dynamic)
    uint256 unitLength = schema[schemaIndex].unitStaticLength();

    // Get offset storage slot
    uint256 slot = _slot_dataSeparate(table, key, schemaIndex);
    uint256 slotByteOffset = unitLength * dataIndex;

    // Data index must be within bounds
    uint256 length = _getDynamicCellLength(slot);
    if (slotByteOffset >= length) {
      revert StoreCore__DynamicColumnDataIndexOutOfBounds();
    }

    // Get data from storage
    data = storageToMem(slot, slotByteOffset, unitLength);
  }

  /*//////////////////////////////////////////////////////////////////////////
                                  Utilities
  //////////////////////////////////////////////////////////////////////////*/

  /**
   * Get the length of a slice of cells, reading storage for dynamic cells.
   * @param end must be <= schema.length.
   */
  function _getStaticSliceLength(
    SchemaType[] memory schema,
    uint256 start,
    uint256 end
  ) private pure returns (uint256 length) {
    for (uint256 i = start; i < end; i++) {
      SchemaType schemaType = schema[i];
      if (!schemaType.isDynamic()) {
        length += schemaType.staticLength();
      }
    }
  }

  /**
   * Get the stored length of a single dynamic cell.
   */
  function _getDynamicCellLength(uint256 slot) private view returns (uint256 length) {
    // length
    length = _sloadDynamicLength(slot);
    // + bytes to store the length
    length += Pack.DYNAMIC_LENGTH_BYTES;

    return length;
  }

  function _sloadDynamicLength(uint256 slot) private view returns (uint256) {
    bytes32 packedLength;
    assembly {
      packedLength := sload(slot)
    }
    return Pack.unpackLength(packedLength);
  }
}
