// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";

import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../SchemaType.sol";

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
}
