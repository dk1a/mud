// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { IStore } from "../IStore.sol";
import { StoreSwitch } from "../StoreSwitch.sol";
import { StoreCore } from "../StoreCore.sol";
import { SchemaType } from "../Types.sol";
import { Bytes } from "../Bytes.sol";
import { Schema, SchemaLib } from "../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../PackedCounter.sol";
import { Mixed, Mixed_ } from "../schemas/Mixed.sol";

// -- User defined tableId --

uint256 constant tableId = uint256(keccak256("mud.store.table.mixed"));

// -- Autogenerated library --
// TODO: autogenerate

library MixedTable {
  /** Get the table's schema */
  function getSchema() internal pure returns (Schema) {
    return Mixed_.getSchema();
  }

  /** Register the table's schema */
  function registerSchema() internal {
    Mixed_.registerSchema(tableId);
  }

  function registerSchema(IStore store) internal {
    Mixed_.registerSchema(tableId, store);
  }

  /** Set the table's data */
  function set(
    bytes32 key,
    uint32 u32,
    uint128 u128,
    uint32[] memory a32,
    string memory s
  ) internal {
    Mixed_.set(tableId, key, u32, u128, a32, s);
  }

  function set(bytes32 key, Mixed memory mixed) internal {
    Mixed_.set(tableId, key, mixed.u32, mixed.u128, mixed.a32, mixed.s);
  }

  function setU32(bytes32 key, uint32 u32) internal {
    Mixed_.setU32(tableId, key, u32);
  }

  function setU128(bytes32 key, uint128 u128) internal {
    Mixed_.setU128(tableId, key, u128);
  }

  function setA32(bytes32 key, uint32[] memory a32) internal {
    Mixed_.setA32(tableId, key, a32);
  }

  function setS(bytes32 key, string memory s) internal {
    Mixed_.setS(tableId, key, s);
  }

  /** Get the table's data */
  function get(bytes32 key) internal view returns (Mixed memory mixed) {
    return Mixed_.get(tableId, key);
  }

  function get(IStore store, bytes32 key) internal view returns (Mixed memory mixed) {
    return Mixed_.get(tableId, store, key);
  }
}
