// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { StoreSwitch } from "../StoreSwitch.sol";
import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../Types.sol";
import { Bytes } from "../Bytes.sol";

// -- User defined schema and id --

bytes32 constant id = keccak256("mud.store.table.system");

struct Schema {
  address addr;
  bytes4 selector;
  uint8 executionMode;
}

// -- Autogenerated schema and library --
// TODO: autogenerate

library SystemTable {
  /** Get the table's schema */
  function getSchema() internal pure returns (SchemaType[] memory schema) {
    schema = new SchemaType[](3);
    schema[0] = SchemaType.Address;
    schema[1] = SchemaType.Bytes4;
    schema[2] = SchemaType.Uint8;
  }

  /** Register the table's schema */
  function registerSchema() internal {
    StoreSwitch.registerSchema(id, getSchema());
  }

  /** Set the table's data */
  function set(
    bytes32 key,
    address addr,
    bytes4 selector,
    uint8 executionMode
  ) internal {
    bytes memory data = bytes.concat(bytes20(addr), bytes4(selector), bytes1(executionMode));
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, data);
  }

  function set(bytes32 key, Schema memory data) internal {
    set(key, data.addr, data.selector, data.executionMode);
  }

  function setAddress(bytes32 key, address addr) internal {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, 0, bytes.concat(bytes20(addr)));
  }

  function setSelector(bytes32 key, bytes4 selector) internal {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, 1, bytes.concat(bytes4(selector)));
  }

  function setExecutionMode(bytes32 key, uint8 executionMode) internal {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, 2, bytes.concat(bytes1(executionMode)));
  }

  /** Get the table's data */
  function get(bytes32 key) internal view returns (Schema memory data) {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    bytes memory blob = StoreSwitch.getData(id, keyTuple, 25);
    return
      Schema({
        addr: Bytes.toAddress(Bytes.slice(blob, 0, 20)),
        selector: Bytes.toBytes4(Bytes.slice(blob, 20, 4)),
        executionMode: Bytes.toUint8(Bytes.slice(blob, 24, 1))
      });
  }
}
