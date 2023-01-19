// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
import { Slice, toSlice } from "@dk1a/solidity-stringutils/src/Slice.sol";

import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../SchemaType.sol";
import { Pack } from "../Pack.sol";

contract StoreCoreTest is DSTestPlus {
  function testRegisterAndGetSchema() public {
    SchemaType[] memory schema = new SchemaType[](4);
    schema[0] = SchemaType.UINT8;
    schema[1] = SchemaType.UINT16;
    schema[2] = SchemaType.UINT8;
    schema[3] = SchemaType.UINT16;

    bytes32 table = keccak256("some.table");
    uint256 gas = gasleft();
    StoreCore.registerSchema(table, schema);
    gas = gas - gasleft();
    console.log("gas used (register): %s", gas);

    gas = gasleft();
    SchemaType[] memory loadedSchema = StoreCore.getSchema(table);
    gas = gas - gasleft();
    console.log("gas used (get schema, warm): %s", gas);

    assertEq(loadedSchema.length, schema.length);
    assertEq(uint8(schema[0]), uint8(loadedSchema[0]));
    assertEq(uint8(schema[1]), uint8(loadedSchema[1]));
    assertEq(uint8(schema[2]), uint8(loadedSchema[2]));
    assertEq(uint8(schema[3]), uint8(loadedSchema[3]));
  }

  struct Schema_4 {
    uint8 val1;
    uint16 val2;
    uint8 val3;
    uint16 val4;
  }

  function testSetAndGet() public {
    // Register table's schema
    SchemaType[] memory schema = new SchemaType[](4);
    schema[0] = SchemaType.UINT8;
    schema[1] = SchemaType.UINT16;
    schema[2] = SchemaType.UINT8;
    schema[3] = SchemaType.UINT16;
    bytes32 table = keccak256("some.table");
    StoreCore.registerSchema(table, schema);

    uint256 packedSize;
    for (uint256 i; i < schema.length; i++) {
      packedSize += Pack.packedSize(schema[i]);
    }

    // Set data
    bytes memory data = new bytes(packedSize);
    Slice slice = toSlice(data);

    Pack.packStaticValue(slice, SchemaType.UINT8, bytes32(uint256(0x01)));
    slice = slice.getAfter(Pack.packedSize(SchemaType.UINT8));
    Pack.packStaticValue(slice, SchemaType.UINT16, bytes32(uint256(0x0203)));
    slice = slice.getAfter(Pack.packedSize(SchemaType.UINT16));
    Pack.packStaticValue(slice, SchemaType.UINT8, bytes32(uint256(0x04)));
    slice = slice.getAfter(Pack.packedSize(SchemaType.UINT8));
    Pack.packStaticValue(slice, SchemaType.UINT16, bytes32(uint256(0x0506)));
    slice = slice.getAfter(Pack.packedSize(SchemaType.UINT16));

    bytes32[] memory key = new bytes32[](1);
    key[0] = keccak256("some.key");

    // Set data
    uint256 gas = gasleft();
    StoreCore.setData(table, key, data);
    gas = gas - gasleft();
    console.log("gas used (set): %s", gas);

    // Get data
    gas = gasleft();
    bytes memory loadedData = StoreCore.getData(table, key, packedSize);
    gas = gas - gasleft();
    console.log("gas used (get, warm): %s", gas);

    // Split data
    gas = gasleft();
    slice = toSlice(data);
    Schema_4 memory splitData = Schema_4(
      uint8(uint256(Pack.unpackStaticValue(slice.getSubslice(0, 1), SchemaType.UINT8))),
      uint16(uint256(Pack.unpackStaticValue(slice.getSubslice(1, 3), SchemaType.UINT16))),
      uint8(uint256(Pack.unpackStaticValue(slice.getSubslice(3, 4), SchemaType.UINT8))),
      uint16(uint256(Pack.unpackStaticValue(slice.getSubslice(4, 6), SchemaType.UINT16)))
    );

    gas = gas - gasleft();
    console.log("gas used (split): %s", gas);

    assertEq(loadedData.length, data.length);
    assertEq(splitData.val1, 0x01);
    assertEq(splitData.val2, 0x0203);
    assertEq(splitData.val3, 0x04);
    assertEq(splitData.val4, 0x0506);
  }
}
