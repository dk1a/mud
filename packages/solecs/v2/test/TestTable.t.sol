// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
import { TestTable, id, Schema } from "../tables/TestTable.sol";
import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../SchemaType.sol";
import { StoreView } from "../StoreView.sol";

contract TestTableTest is DSTestPlus, StoreView {
  function testRegisterAndGetSchema() public {
    uint256 gas = gasleft();
    TestTable.registerSchema();
    gas = gas - gasleft();
    console.log("gas used: %s", gas);

    SchemaType[] memory registeredSchema = StoreCore.getSchema(id);
    SchemaType[] memory declaredSchema = TestTable.getSchema();

    assertEq(keccak256(abi.encode(registeredSchema)), keccak256(abi.encode(declaredSchema)));
  }

  function testSetAndGet() public {
    TestTable.registerSchema();
    bytes32 key = keccak256("somekey");

    uint32[] memory numbers = new uint32[](2);
    numbers[0] = 10;
    numbers[1] = 11;

    uint256 gas = gasleft();
    TestTable.set(
      key,
      Schema({
        addr: address(this),
        selector: hex"01020304",
        executionMode: 1,
        sigInt: int128(-123456789),
        args: abi.encode(123, "asdfgh"),
        numbers: numbers,
        aString: "a string",
        aBool: true
      })
    );
    gas = gas - gasleft();
    console.log("gas used (set): %s", gas);

    gas = gasleft();
    Schema memory schema = TestTable.get(key);
    gas = gas - gasleft();
    console.log("gas used (get, warm): %s", gas);

    assertEq(schema.addr, address(this));
    assertEq(schema.selector, hex"01020304");
    assertEq(schema.executionMode, 1);
    assertEq(schema.sigInt, int128(-123456789));
    assertEq(keccak256(schema.args), keccak256(abi.encode(123, "asdfgh")));
    assertEq(schema.numbers.length, numbers.length);
    assertEq(schema.numbers[0], numbers[0]);
    assertEq(schema.numbers[1], numbers[1]);
    assertEq(schema.aString, "a string");
    assertTrue(schema.aBool);
  }
}
