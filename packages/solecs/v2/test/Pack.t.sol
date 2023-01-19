// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
import { Slice, toSlice } from "@dk1a/solidity-stringutils/src/Slice.sol";

import { SchemaType } from "../SchemaType.sol";
import { Pack } from "../Pack.sol";

contract PackTest is DSTestPlus {
  function testPackGas_4StaticCells() public {
    // Register table's schema
    SchemaType[] memory schema = new SchemaType[](4);
    schema[0] = SchemaType.UINT8;
    schema[1] = SchemaType.UINT16;
    schema[2] = SchemaType.UINT8;
    schema[3] = SchemaType.UINT16;

    uint256 gas = gasleft();
    // Get size
    uint256 packedSize;
    for (uint256 i; i < schema.length; i++) {
      packedSize += Pack.packedSize(schema[i]);
    }
    gas = gas - gasleft();
    console.log("gas used (packedSize): %s", gas);

    gas = gasleft();
    // Pack bytes via Pack methods
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

    gas = gas - gasleft();
    console.log("gas used (packing): %s", gas);

    gas = gasleft();
    // Pack bytes via concat
    bytes memory dataExpected = bytes.concat(hex"01", hex"0203", hex"04", hex"0506");

    gas = gas - gasleft();
    console.log("gas used (concat): %s", gas);

    assertEq(bytes32(data), bytes32(dataExpected));
  }
}
