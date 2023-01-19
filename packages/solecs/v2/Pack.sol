// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Slice__, Slice, toSlice } from "@dk1a/solidity-stringutils/src/Slice.sol";

import { SchemaType } from "./SchemaType.sol";

/**
 * Treat an array as a slice of raw bytes.
 * (be careful with unused bytes of padded arrays)
 */
function toSlice(bytes32[] memory value) pure returns (Slice) {
  uint256 _ptr;
  assembly {
    _ptr := add(value, 0x20)
  }
  return Slice__.fromRawParts(_ptr, value.length * 32);
}

library Pack {
  error Pack__DynamicLengthOverflow();
  error Pack__StaticLengthMismatch();

  error Pack__SchemaTypeNotStatic();
  error Pack__SchemaTypeNotBytes();
  error Pack__SchemaTypeNotArray();
  error Pack__SchemaTypeNotBytesArray();

  uint256 constant DYNAMIC_LENGTH_BYTES = 2;
  uint256 constant DYNAMIC_LENGTH_BITSHIFT = (32 - DYNAMIC_LENGTH_BYTES) * 8;

  // A dynamic value should fit into 2 bytes for efficient packing
  // (a single schema row shouldn't have very long arrays anyways)
  uint256 constant MAX_DYNAMIC_LENGTH = type(uint16).max;

  function packLength(uint256 length) internal pure returns (bytes32) {
    return bytes32(length << DYNAMIC_LENGTH_BITSHIFT);
  }

  function unpackLength(bytes32 length) internal pure returns (uint256) {
    return uint256(length) >> DYNAMIC_LENGTH_BITSHIFT;
  }

  function verifyValue(SchemaType schemaType, Slice slice) internal pure {
    if (schemaType.isDynamic()) {
      // dynamic values decide their own length, however it's capped by `MAX_DYNAMIC_LENGTH`
      // (this length is always in bytes regardless of SchemaType)
      if (slice.len() > MAX_DYNAMIC_LENGTH) {
        revert Pack__DynamicLengthOverflow();
      }
    } else {
      // static value must always be of schema-determined length
      if (schemaType.staticLength() != slice.len()) {
        revert Pack__StaticLengthMismatch();
      }
    }
  }

  function packedSize(SchemaType schemaType) internal pure returns (uint256) {
    return schemaType.staticLength();
  }

  function packedArraySize(SchemaType schemaType, uint256 arrayLength) internal pure returns (uint256) {
    uint256 unitLength = schemaType.unitStaticLength();
    return DYNAMIC_LENGTH_BYTES + arrayLength * unitLength;
  }

  function packedBytesSize(SchemaType, uint256 bytesLength) internal pure returns (uint256) {
    return DYNAMIC_LENGTH_BYTES + bytesLength;
  }

  /* TODO this
  function packedBytesArraySize(SchemaType, bytes[] memory value) internal pure returns (uint256) {
    
  }*/

  /**
   * Packed `value` based on `schemaType` and mstore it to `dataPtr`.
   * (encodes like `encodePacked` for typed values).
   * @param value a generic value, just cast any other type to bytes32.
   */
  function packStaticValue(
    Slice slice,
    SchemaType schemaType,
    bytes32 value
  ) internal pure {
    if (schemaType.isDynamic()) {
      revert Pack__SchemaTypeNotStatic();
    }
    uint256 length = schemaType.staticLength();

    if (schemaType.isLeftAligned()) {
      slice.copyFromValue(value, length);
    } else {
      slice.copyFromValueRightAligned(value, length);
    }
  }

  /**
   * Decode the packed encoding of a single static value.
   * @return value a generic value, just cast it to SchemaType's corresponding type.
   */
  function unpackStaticValue(Slice slice, SchemaType schemaType) internal pure returns (bytes32 value) {
    if (schemaType.isDynamic()) {
      revert Pack__SchemaTypeNotStatic();
    }
    uint256 length = schemaType.staticLength();
    if (length != slice.len()) {
      revert Pack__StaticLengthMismatch();
    }

    value = slice.toBytes32();

    if (length != 32 && !schemaType.isLeftAligned()) {
      // right-align a non-word-length value
      value = bytes32(uint256(value) >> ((32 - length) * 8));
    }

    return value;
  }

  function packBytes(
    Slice slice,
    SchemaType schemaType,
    bytes memory value
  ) private view {
    if (schemaType != SchemaType.BYTES && schemaType != SchemaType.STRING) {
      revert Pack__SchemaTypeNotBytes();
    }
    uint256 length = value.length;
    if (length > MAX_DYNAMIC_LENGTH) {
      revert Pack__DynamicLengthOverflow();
    }

    // copy packed length
    slice.getBefore(DYNAMIC_LENGTH_BYTES).copyFromValueRightAligned(bytes32(length), DYNAMIC_LENGTH_BYTES);
    // copy bytes
    slice.getAfter(DYNAMIC_LENGTH_BYTES).copyFromSlice(toSlice(value));
  }

  function packArray(
    Slice slice,
    SchemaType schemaType,
    bytes32[] memory value
  ) internal view {
    if (!schemaType.isDynamic() || schemaType.isUnitDynamic()) {
      revert Pack__SchemaTypeNotArray();
    }
    SchemaType innerType = schemaType.arrayInnerType();
    uint256 unitLength = innerType.staticLength();
    uint256 length = value.length * unitLength;
    if (length > MAX_DYNAMIC_LENGTH) {
      revert Pack__DynamicLengthOverflow();
    }

    // copy packed length
    slice.getBefore(DYNAMIC_LENGTH_BYTES).copyFromValueRightAligned(bytes32(length), DYNAMIC_LENGTH_BYTES);
    slice = slice.getAfter(DYNAMIC_LENGTH_BYTES);

    // if tightly packed already, then encode as-is
    if (unitLength == 32) {
      // copy bytes
      slice.copyFromSlice(toSlice(value));
      return;
    }

    // tightly pack array items
    for (uint256 i; i < value.length; i++) {
      packStaticValue(slice, innerType, value[i]);
      slice = slice.getAfter(unitLength);
    }
  }

  function packNestedDynamicValue(SchemaType schemaType, bytes32[] memory value) private pure returns (bytes memory) {
    if (!schemaType.isUnitDynamic()) {
      revert Pack__SchemaTypeNotBytesArray();
    }
    // TODO this (bytes_array, string_array)
  }
}
