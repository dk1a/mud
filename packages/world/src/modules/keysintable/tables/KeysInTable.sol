// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { Schema, SchemaLib } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter, PackedCounterLib } from "@latticexyz/store/src/PackedCounter.sol";

bytes32 constant _tableId = bytes32(abi.encodePacked(bytes16(""), bytes16("KeysInTable")));
bytes32 constant KeysInTableTableId = _tableId;

struct KeysInTableData {
  uint32 length;
  bytes32[] keys;
}

library KeysInTable {
  /** Get the table's schema */
  function getSchema() internal pure returns (Schema) {
    SchemaType[] memory _schema = new SchemaType[](2);
    _schema[0] = SchemaType.UINT32;
    _schema[1] = SchemaType.BYTES32_ARRAY;

    return SchemaLib.encode(_schema);
  }

  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _schema = new SchemaType[](1);
    _schema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_schema);
  }

  /** Get the table's metadata */
  function getMetadata() internal pure returns (string memory, string[] memory) {
    string[] memory _fieldNames = new string[](2);
    _fieldNames[0] = "length";
    _fieldNames[1] = "keys";
    return ("KeysInTable", _fieldNames);
  }

  /** Register the table's schema */
  function registerSchema() internal {
    StoreSwitch.registerSchema(_tableId, getSchema(), getKeySchema());
  }

  /** Register the table's schema (using the specified store) */
  function registerSchema(IStore _store) internal {
    _store.registerSchema(_tableId, getSchema(), getKeySchema());
  }

  /** Set the table's metadata */
  function setMetadata() internal {
    (string memory _tableName, string[] memory _fieldNames) = getMetadata();
    StoreSwitch.setMetadata(_tableId, _tableName, _fieldNames);
  }

  /** Set the table's metadata (using the specified store) */
  function setMetadata(IStore _store) internal {
    (string memory _tableName, string[] memory _fieldNames) = getMetadata();
    _store.setMetadata(_tableId, _tableName, _fieldNames);
  }

  /** Get length */
  function getLength(bytes32 sourceTable) internal view returns (uint32 length) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = StoreSwitch.getField(_tableId, _keyTuple, 0);
    return (uint32(Bytes.slice4(_blob, 0)));
  }

  /** Get length (using the specified store) */
  function getLength(IStore _store, bytes32 sourceTable) internal view returns (uint32 length) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = _store.getField(_tableId, _keyTuple, 0);
    return (uint32(Bytes.slice4(_blob, 0)));
  }

  /** Set length */
  function setLength(bytes32 sourceTable, uint32 length) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.setField(_tableId, _keyTuple, 0, abi.encodePacked((length)));
  }

  /** Set length (using the specified store) */
  function setLength(IStore _store, bytes32 sourceTable, uint32 length) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.setField(_tableId, _keyTuple, 0, abi.encodePacked((length)));
  }

  /** Get keys */
  function getKeys(bytes32 sourceTable) internal view returns (bytes32[] memory keys) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = StoreSwitch.getField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /** Get keys (using the specified store) */
  function getKeys(IStore _store, bytes32 sourceTable) internal view returns (bytes32[] memory keys) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = _store.getField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /** Set keys */
  function setKeys(bytes32 sourceTable, bytes32[] memory keys) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.setField(_tableId, _keyTuple, 1, EncodeArray.encode((keys)));
  }

  /** Set keys (using the specified store) */
  function setKeys(IStore _store, bytes32 sourceTable, bytes32[] memory keys) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.setField(_tableId, _keyTuple, 1, EncodeArray.encode((keys)));
  }

  /** Get the length of keys */
  function lengthKeys(bytes32 sourceTable) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    uint256 _byteLength = StoreSwitch.getFieldLength(_tableId, _keyTuple, 1, getSchema());
    return _byteLength / 32;
  }

  /** Get the length of keys (using the specified store) */
  function lengthKeys(IStore _store, bytes32 sourceTable) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    uint256 _byteLength = _store.getFieldLength(_tableId, _keyTuple, 1, getSchema());
    return _byteLength / 32;
  }

  /** Get an item of keys (unchecked, returns invalid data if index overflows) */
  function getItemKeys(bytes32 sourceTable, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = StoreSwitch.getFieldSlice(_tableId, _keyTuple, 1, getSchema(), _index * 32, (_index + 1) * 32);
    return (Bytes.slice32(_blob, 0));
  }

  /** Get an item of keys (using the specified store) (unchecked, returns invalid data if index overflows) */
  function getItemKeys(IStore _store, bytes32 sourceTable, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = _store.getFieldSlice(_tableId, _keyTuple, 1, getSchema(), _index * 32, (_index + 1) * 32);
    return (Bytes.slice32(_blob, 0));
  }

  /** Push an element to keys */
  function pushKeys(bytes32 sourceTable, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.pushToField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /** Push an element to keys (using the specified store) */
  function pushKeys(IStore _store, bytes32 sourceTable, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.pushToField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /** Pop an element from keys */
  function popKeys(bytes32 sourceTable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.popFromField(_tableId, _keyTuple, 1, 32);
  }

  /** Pop an element from keys (using the specified store) */
  function popKeys(IStore _store, bytes32 sourceTable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.popFromField(_tableId, _keyTuple, 1, 32);
  }

  /** Update an element of keys at `_index` */
  function updateKeys(bytes32 sourceTable, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.updateInField(_tableId, _keyTuple, 1, _index * 32, abi.encodePacked((_element)));
  }

  /** Update an element of keys (using the specified store) at `_index` */
  function updateKeys(IStore _store, bytes32 sourceTable, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.updateInField(_tableId, _keyTuple, 1, _index * 32, abi.encodePacked((_element)));
  }

  /** Get the full data */
  function get(bytes32 sourceTable) internal view returns (KeysInTableData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = StoreSwitch.getRecord(_tableId, _keyTuple, getSchema());
    return decode(_blob);
  }

  /** Get the full data (using the specified store) */
  function get(IStore _store, bytes32 sourceTable) internal view returns (KeysInTableData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    bytes memory _blob = _store.getRecord(_tableId, _keyTuple, getSchema());
    return decode(_blob);
  }

  /** Set the full data using individual values */
  function set(bytes32 sourceTable, uint32 length, bytes32[] memory keys) internal {
    bytes memory _data = encode(length, keys);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.setRecord(_tableId, _keyTuple, _data);
  }

  /** Set the full data using individual values (using the specified store) */
  function set(IStore _store, bytes32 sourceTable, uint32 length, bytes32[] memory keys) internal {
    bytes memory _data = encode(length, keys);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.setRecord(_tableId, _keyTuple, _data);
  }

  /** Set the full data using the data struct */
  function set(bytes32 sourceTable, KeysInTableData memory _table) internal {
    set(sourceTable, _table.length, _table.keys);
  }

  /** Set the full data using the data struct (using the specified store) */
  function set(IStore _store, bytes32 sourceTable, KeysInTableData memory _table) internal {
    set(_store, sourceTable, _table.length, _table.keys);
  }

  /** Decode the tightly packed blob using this table's schema */
  function decode(bytes memory _blob) internal view returns (KeysInTableData memory _table) {
    // 4 is the total byte length of static data
    PackedCounter _encodedLengths = PackedCounter.wrap(Bytes.slice32(_blob, 4));

    _table.length = (uint32(Bytes.slice4(_blob, 0)));

    // Store trims the blob if dynamic fields are all empty
    if (_blob.length > 4) {
      uint256 _start;
      // skip static data length + dynamic lengths word
      uint256 _end = 36;

      _start = _end;
      _end += _encodedLengths.atIndex(0);
      _table.keys = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_bytes32());
    }
  }

  /** Tightly pack full data using this table's schema */
  function encode(uint32 length, bytes32[] memory keys) internal view returns (bytes memory) {
    uint40[] memory _counters = new uint40[](1);
    _counters[0] = uint40(keys.length * 32);
    PackedCounter _encodedLengths = PackedCounterLib.pack(_counters);

    return abi.encodePacked(length, _encodedLengths.unwrap(), EncodeArray.encode((keys)));
  }

  /** Encode keys as a bytes32 array using this table's schema */
  function encodeKeyTuple(bytes32 sourceTable) internal pure returns (bytes32[] memory _keyTuple) {
    _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));
  }

  /* Delete all data for given keys */
  function deleteRecord(bytes32 sourceTable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /* Delete all data for given keys (using the specified store) */
  function deleteRecord(IStore _store, bytes32 sourceTable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32((sourceTable));

    _store.deleteRecord(_tableId, _keyTuple);
  }
}