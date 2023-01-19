// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { SchemaType } from "./SchemaType.sol";
import { memToStorage, storageToMem } from "./storage.sol";
import { Pack } from "./Pack.sol";

library StoreCore {
  error StoreCore__SchemaSizeOverflow();

  // note: the preimage of the tuple of keys used to index is part of the event, so it can be used by indexers
  event StoreUpdate(bytes32 table, bytes32[] key, uint8 schemaIndex, bytes data);

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

  // Update full data
  function setData(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data
  ) internal {
    //SchemaType[] memory schema = getSchema(table);
    // TODO Verify data for schema

    setDataUnsafe(table, key, data);
  }

  // Update full data
  function setDataUnsafe(
    bytes32 table,
    bytes32[] memory key,
    bytes memory data
  ) internal {
    // Store the provided value in storage
    uint256 slot = _slot_data(table, key);
    memToStorage(slot, data, false);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, 0, data);
  }

  // Update partial data (minimize sstore if full data wraps multiple evm words)
  function setData(
    bytes32 table,
    bytes32[] memory key,
    uint8 schemaIndex,
    bytes memory data
  ) internal {
    // Get schema to compute storage offset
    SchemaType[] memory schema = getSchema(table);
    // TODO Verify data for schema

    // Get offset storage slot
    uint256 slot = _slot_data(table, key);
    uint256 offset = _getSliceLength(slot, schema, schemaIndex);
    slot += offset;

    // Store the provided value in storage
    memToStorage(slot, data, false);

    // Emit event to notify indexers
    emit StoreUpdate(table, key, schemaIndex, data);
  }

  /**
   * Get full data for the given table and key tuple (compute length from schema)
   */
  function getData(bytes32 table, bytes32[] memory key) internal view returns (bytes memory data) {
    // Get storage slot
    uint256 slot = _slot_data(table, key);
    // Get data length using schema for static cells
    SchemaType[] memory schema = getSchema(table);
    uint256 length = _getSliceLength(slot, schema, schema.length);
    // Get data from storage
    return storageToMem(slot, length);
  }

  /**
   * Get full data for the given table and key tuple, with the given length
   */
  function getData(
    bytes32 table,
    bytes32[] memory key,
    uint256 length
  ) internal view returns (bytes memory) {
    // Get storage slot
    uint256 slot = _slot_data(table, key);
    // Get data from storage
    return storageToMem(slot, length);
  }

  // Get partial data based on schema key
  // (Only access the minimum required number of storage slots)
  function getPartialData(
    bytes32 table,
    bytes32[] memory key,
    uint256 schemaIndex
  ) internal view returns (bytes memory data) {
    // Get schema to compute storage offset and provide static cell sizes
    SchemaType[] memory schema = getSchema(table);

    // Get offset storage slot
    uint256 slot = _slot_data(table, key);
    uint256 offset = _getSliceLength(slot, schema, schemaIndex);
    slot += offset;
    // Get data length
    uint256 length = _getCellLength(slot, schema[schemaIndex]);

    // Get data from storage
    return storageToMem(slot, length);
  }

  /**
   * Get the length of a slice of cells, reading storage for dynamic cells.
   * @param end must be <= schema.length.
   */
  function _getSliceLength(
    uint256 slot,
    SchemaType[] memory schema,
    uint256 end
  ) private view returns (uint256 length) {
    for (uint256 i; i < end; i++) {
      length += _getCellLength(slot + length, schema[i]);
    }
  }

  /**
   * Get the length of a single cell, reading storage if it's dynamic.
   */
  function _getCellLength(uint256 slot, SchemaType schemaType) private view returns (uint256 length) {
    if (schemaType.isDynamic()) {
      // length
      length = _sloadDynamicLength(slot);
      // + bytes to store the length
      length += Pack.DYNAMIC_LENGTH_BYTES;
    } else {
      length = schemaType.staticLength();
    }
  }

  function _sloadDynamicLength(uint256 slot) private view returns (uint256) {
    bytes32 packedLength;
    assembly {
      packedLength := sload(slot)
    }
    return Pack.unpackLength(packedLength);
  }
}
