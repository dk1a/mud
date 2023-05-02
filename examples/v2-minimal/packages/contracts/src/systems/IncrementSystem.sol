// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { CounterTable } from "../codegen/Tables.sol";
import { IWorld } from "../codegen/world/IWorld.sol";

bytes32 constant SingletonKey = bytes32(uint256(0x060D));

struct Asd {
  uint256 asd;
}

contract IncrementSystem is System {
  function increment(Asd memory asd) public returns (uint32) {
    bytes32 key = SingletonKey;
    uint32 counter = CounterTable.get(key);
    uint32 newValue = counter + 1;
    CounterTable.set(key, newValue);
    if (newValue < 10) {
      Asd memory asd;
      IWorld(_world()).increment(asd);
    }
    return newValue;
  }
}
