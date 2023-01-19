// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { leftMask } from "@dk1a/solidity-stringutils/src/utils/mem.sol";

function memToStorage(
  uint256 slotDest,
  bytes memory data,
  bool safeTail
) {
  uint256 length = data.length;
  uint256 ptrSrc;
  assembly {
    // skip length
    ptrSrc := add(data, 0x20)
  }

  // copy 32-byte chunks
  while (length >= 32) {
    /// @solidity memory-safe-assembly
    assembly {
      sstore(slotDest, mload(ptrSrc))
    }
    // safe because total addition will be <= length (ptr+len is implicitly safe)
    unchecked {
      slotDest += 32;
      ptrSrc += 32;
      length -= 32;
    }
  }

  // return if nothing is left
  if (length == 0) return;

  // copy the 0-31 length tail
  if (safeTail) {
    // preserve the trailing bytes after the tail

    uint256 mask = leftMask(length);
    /// @solidity memory-safe-assembly
    assembly {
      sstore(
        slotDest,
        or(
          // store the left part
          and(mload(ptrSrc), mask),
          // preserve the right part
          and(sload(slotDest), not(mask))
        )
      )
    }
  } else {
    // overwrite the trailing bytes after the tail with garbage from memory
    // (this is fine only at the end of a sparse storage slot)

    /// @solidity memory-safe-assembly
    assembly {
      sstore(slotDest, mload(ptrSrc))
    }
  }
}

function storageToMem(uint256 slotSrc, uint256 length) view returns (bytes memory data) {
  data = new bytes(length);

  uint256 ptrDest;
  assembly {
    // skip length
    ptrDest := add(data, 0x20)
  }

  // copy 32-byte chunks
  while (length >= 32) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(ptrDest, sload(slotSrc))
    }
    // safe because total addition will be <= length (ptr+len is implicitly safe)
    unchecked {
      ptrDest += 32;
      slotSrc += 32;
      length -= 32;
    }
  }

  // return if nothing is left
  if (length == 0) return data;

  // copy the 0-31 length tail
  // (always preserve the trailing bytes after the tail, an extra mload is cheap)
  uint256 mask = leftMask(length);
  /// @solidity memory-safe-assembly
  assembly {
    mstore(
      ptrDest,
      or(
        // store the left part
        and(sload(slotSrc), mask),
        // preserve the right part
        and(mload(ptrDest), not(mask))
      )
    )
  }
}
