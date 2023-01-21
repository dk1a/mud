// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { leftMask } from "@dk1a/solidity-stringutils/src/utils/mem.sol";

function memToStorage(
  uint256 slotDest,
  uint256 slotByteOffset,
  bytes memory data,
  bool safeTail
) {
  // slots are measured in words, so a byte offset is needed for data within the word
  if (slotByteOffset > 0) {
    unchecked {
      slotDest += slotByteOffset / 32;
      slotByteOffset %= 32;
    }
  }

  uint256 length = data.length;
  uint256 ptrSrc;
  assembly {
    // skip length
    ptrSrc := add(data, 0x20)
  }

  // copy unaligned prefix if necessary
  if (slotByteOffset > 0) {
    uint256 mask = leftMask(length);
    // this makes a middle mask that will have 0s on the left and *might* have 0s on the right
    mask >>= slotByteOffset * 8;

    /// @solidity memory-safe-assembly
    assembly {
      sstore(
        slotDest,
        or(
          // store the middle part
          and(mload(ptrSrc), mask),
          // preserve the surrounding parts
          and(sload(slotDest), not(mask))
        )
      )
    }

    uint256 prefixLength;
    // safe because of `slotByteOffset %= 32` at the start
    unchecked {
      prefixLength = 32 - slotByteOffset;
    }
    // return if done
    if (length <= prefixLength) return;

    slotDest += 1;
    // safe because of `length <= prefixLength` earlier
    unchecked {
      ptrSrc += prefixLength;
      length -= prefixLength;
    }
  }

  // copy 32-byte chunks
  while (length >= 32) {
    /// @solidity memory-safe-assembly
    assembly {
      sstore(slotDest, mload(ptrSrc))
    }
    slotDest += 1;
    // safe because total addition will be <= length (ptr+len is implicitly safe)
    unchecked {
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

function storageToMem(
  uint256 slotSrc,
  uint256 slotByteOffset,
  uint256 length
) view returns (bytes memory data) {
  // slots are measured in words, so a byte offset is needed for data within the word
  if (slotByteOffset > 0) {
    unchecked {
      slotSrc += slotByteOffset / 32;
      slotByteOffset %= 32;
    }
  }

  data = new bytes(length);

  uint256 ptrDest;
  assembly {
    // skip length
    ptrDest := add(data, 0x20)
  }

  uint256 mask;
  // copy unaligned prefix if necessary
  if (slotByteOffset > 0) {
    mask = leftMask(length);
    // this makes a middle mask that will have 0s on the left and *might* have 0s on the right
    mask >>= slotByteOffset * 8;

    /// @solidity memory-safe-assembly
    assembly {
      mstore(
        ptrDest,
        or(
          // store the middle part
          and(sload(slotSrc), mask),
          // preserve the surrounding parts
          and(mload(ptrDest), not(mask))
        )
      )
    }

    uint256 prefixLength;
    // safe because of `slotByteOffset %= 32` revert at the start
    unchecked {
      prefixLength = 32 - slotByteOffset;
    }
    // return if done
    if (length <= prefixLength) return data;

    slotSrc += 1;
    // safe because of `length <= prefixLength` earlier
    unchecked {
      ptrDest += prefixLength;
      length -= prefixLength;
    }
  }

  // copy 32-byte chunks
  while (length >= 32) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(ptrDest, sload(slotSrc))
    }
    slotSrc += 1;
    // safe because total addition will be <= length (ptr+len is implicitly safe)
    unchecked {
      ptrDest += 32;
      length -= 32;
    }
  }

  // return if nothing is left
  if (length == 0) return data;

  // copy the 0-31 length tail
  // (always preserve the trailing bytes after the tail, an extra mload is cheap)
  mask = leftMask(length);
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
