// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { Slice, toSlice } from "@dk1a/solidity-stringutils/src/Slice.sol";

import { StoreSwitch } from "../StoreSwitch.sol";
import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../SchemaType.sol";
import { Pack } from "../Pack.sol";

// -- User defined schema and id --

bytes32 constant id = keccak256("mud.store.table.vec2");

struct Schema {
  uint32 x;
  uint32 y;
}

// -- Autogenerated schema and library --
// TODO: autogenerate

library Vec2Table {
  /** Get the table's schema */
  function getSchema() internal pure returns (SchemaType[] memory schema) {
    schema = new SchemaType[](2);
    schema[0] = SchemaType.UINT32;
    schema[1] = SchemaType.UINT32;
  }

  /** Register the table's schema */
  function registerSchema() internal {
    StoreSwitch.registerSchema(id, getSchema());
  }

  /** Set the table's data */
  function set(
    bytes32 key,
    uint32 x,
    uint32 y
  ) internal {
    // TODO static sizes can also be autogenerated
    uint256 packedSize = Pack.packedSize(SchemaType.UINT32) + Pack.packedSize(SchemaType.UINT32);

    bytes memory data = new bytes(packedSize);
    Slice slice = toSlice(data);
    slice = Pack.packStaticValue(slice, SchemaType.UINT32, bytes32(uint256(x)));
    slice = Pack.packStaticValue(slice, SchemaType.UINT32, bytes32(uint256(y)));

    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;

    StoreSwitch.setData(id, keyTuple, data);
  }

  function set(bytes32 key, Schema memory vec2) internal {
    set(key, vec2.x, vec2.y);
  }

  function setX(bytes32 key, uint32 x) internal {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, 0, abi.encodePacked(x));
  }

  function setY(bytes32 key, uint32 y) internal {
    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    StoreSwitch.setData(id, keyTuple, 1, abi.encodePacked(y));
  }

  /** Get the table's data */
  function get(bytes32 key) internal view returns (Schema memory result) {
    bytes32 __genericValue;

    bytes32[] memory keyTuple = new bytes32[](1);
    keyTuple[0] = key;
    bytes memory data = StoreSwitch.getData(id, keyTuple);
    Slice slice = toSlice(data);

    (__genericValue, slice) = Pack.unpackStaticValue(slice, SchemaType.UINT32);
    result.x = uint32(uint256(__genericValue));

    (__genericValue, slice) = Pack.unpackStaticValue(slice, SchemaType.UINT32);
    result.y = uint32(uint256(__genericValue));

    return result;
  }
}
