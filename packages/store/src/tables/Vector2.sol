// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* Autogenerated file. Do not edit manually. */

import { IStore } from "../IStore.sol";
import { StoreSwitch } from "../StoreSwitch.sol";
import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../Types.sol";
import { Bytes } from "../Bytes.sol";
import { SliceLib } from "../Slice.sol";
import { EncodeArray } from "../tightcoder/EncodeArray.sol";
import { Schema, SchemaLib } from "../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../PackedCounter.sol";

uint256 constant _tableId = uint256(keccak256("/tables/Vector2"));
uint256 constant Vector2TableId = _tableId;

struct Vector2Data {
  uint32 x;
  uint32 y;
}

library Vector2 {
  /** Get the table's schema */
  function getSchema() internal pure returns (Schema) {
    SchemaType[] memory _schema = new SchemaType[](2);
    _schema[0] = SchemaType.UINT32;
    _schema[1] = SchemaType.UINT32;

    return SchemaLib.encode(_schema);
  }

  /** Register the table's schema */
  function registerSchema() internal {
    StoreSwitch.registerSchema(_tableId, getSchema());
  }

  function registerSchema(IStore _store) internal {
    _store.registerSchema(_tableId, getSchema());
  }

  function setX(bytes32 key, uint32 x) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    StoreSwitch.setField(_tableId, _keyTuple, 0, abi.encodePacked(x));
  }

  function setY(bytes32 key, uint32 y) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    StoreSwitch.setField(_tableId, _keyTuple, 1, abi.encodePacked(y));
  }

  function getX(bytes32 key) internal view returns (uint32 x) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    bytes memory _blob = StoreSwitch.getField(_tableId, _keyTuple, 0);
    return uint32(Bytes.slice4(_blob, 0));
  }

  function getY(bytes32 key) internal view returns (uint32 y) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    bytes memory _blob = StoreSwitch.getField(_tableId, _keyTuple, 1);
    return uint32(Bytes.slice4(_blob, 0));
  }

  /** Set the table's data */
  function set(
    bytes32 key,
    uint32 x,
    uint32 y
  ) internal {
    bytes memory _data = abi.encodePacked(x, y);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setRecord(_tableId, _keyTuple, _data);
  }

  function set(bytes32 key, Vector2Data memory _table) internal {
    set(key, _table.x, _table.y);
  }

  /** Get the table's data */
  function get(bytes32 key) internal view returns (Vector2Data memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    bytes memory _blob = StoreSwitch.getRecord(_tableId, _keyTuple, getSchema());
    return decode(_blob);
  }

  function get(IStore _store, bytes32 key) internal view returns (Vector2Data memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;
    bytes memory _blob = _store.getRecord(_tableId, _keyTuple);
    return decode(_blob);
  }

  function decode(bytes memory _blob) internal pure returns (Vector2Data memory _table) {
    _table.x = uint32(Bytes.slice4(_blob, 0));

    _table.y = uint32(Bytes.slice4(_blob, 4));
  }
}
