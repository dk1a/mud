// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { SchemaType } from "./SchemaType.sol";

interface IMudStore {
  event StoreUpdate(bytes32 table, bytes32[] index, uint8 schemaIndex, bytes data);

  function registerSchema(bytes32 table, SchemaType[] calldata schema) external;

  function setData(
    bytes32 table,
    bytes32[] calldata index,
    bytes[] calldata data
  ) external;

  function setData(
    bytes32 table,
    bytes32[] calldata index,
    uint8 schemaIndex,
    bytes memory data
  ) external;

  function getData(bytes32 table, bytes32[] calldata index) external view returns (bytes[] memory data);

  function getDataAtIndex(
    bytes32 table,
    bytes32[] calldata index,
    bytes32 schemaIndex
  ) external view returns (bytes memory data);
}
