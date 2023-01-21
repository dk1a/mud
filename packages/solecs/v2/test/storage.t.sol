// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";

import { memToStorage, storageToMem } from "../storage.sol";
import { divCeil } from "../utils.sol";

contract storageTest is DSTestPlus {
  function _meteredSetAndGet(bytes memory data, bool safeTail) internal {
    uint256 slot = uint256(keccak256("some location"));

    uint256 gas = gasleft();
    memToStorage(slot, 0, data, safeTail);
    gas = gas - gasleft();
    console.log("gas used (set, %s slots): %s", divCeil(data.length, 32), gas);

    gas = gasleft();
    bytes memory loadedData = storageToMem(slot, 0, data.length);
    gas = gas - gasleft();
    console.log("gas used (get, warm, %s slots): %s", divCeil(data.length, 32), gas);

    assertEq(keccak256(loadedData), keccak256(data));
  }

  function testSetAndGet_OneSlot() public {
    bytes memory data = new bytes(32);

    data[0] = 0x01;
    data[31] = 0x02;

    _meteredSetAndGet(data, false);
  }

  function testSetAndGet_OneSlot_SafeTail() public {
    bytes memory data = new bytes(32);

    data[0] = 0x01;
    data[31] = 0x02;

    _meteredSetAndGet(data, true);
  }

  function testSetAndGet_4AlignedSlots() public {
    bytes memory data = abi.encode("this is some data spanning multiple words");

    _meteredSetAndGet(data, false);
  }

  function testSetAndGet_4AlignedSlots_SafeTail() public {
    bytes memory data = abi.encode("this is some data spanning multiple words");

    _meteredSetAndGet(data, true);
  }

  function testSetAndGet_2UnalignedSlots() public {
    bytes memory data = "this is some data spanning multiple words";

    _meteredSetAndGet(data, false);
  }

  function testSetAndGet_2UnalignedSlots_SafeTail() public {
    bytes memory data = "this is some data spanning multiple words";

    _meteredSetAndGet(data, true);
  }
}
