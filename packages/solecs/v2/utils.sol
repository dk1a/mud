// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

function divCeil(uint256 a, uint256 b) pure returns (uint256) {
  return a / b + (a % b == 0 ? 0 : 1);
}
