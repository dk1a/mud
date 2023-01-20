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

  function packedBytesSize(SchemaType, uint256 bytesLength) internal pure returns (uint256) {
    return DYNAMIC_LENGTH_BYTES + bytesLength;
  }

  function packedArraySize(SchemaType schemaType, uint256 arrayLength) internal pure returns (uint256) {
    uint256 unitLength = schemaType.unitStaticLength();
    return DYNAMIC_LENGTH_BYTES + arrayLength * unitLength;
  }

  /* TODO this
  function packedBytesArraySize(SchemaType, bytes[] memory value) internal pure returns (uint256) {
    
  }*/

  /**
   * Packed `value` based on `schemaType` and mstore it to `dataPtr`.
   * (encodes like `encodePacked` for typed values).
   * @param value a generic value, just cast any other type to bytes32.
   * @return nextSubslice subslice after the packed value.
   */
  function packStaticValue(
    Slice slice,
    SchemaType schemaType,
    bytes32 value
  ) internal pure returns (Slice nextSubslice) {
    if (schemaType.isDynamic()) {
      revert Pack__SchemaTypeNotStatic();
    }
    uint256 length = schemaType.staticLength();

    if (schemaType.isLeftAligned()) {
      slice.copyFromValue(value, length);
    } else {
      slice.copyFromValueRightAligned(value, length);
    }

    return slice.getAfter(length);
  }

  /**
   * Decode the packed encoding of a single static value.
   * @return value a generic value, just cast it to SchemaType's corresponding type.
   */
  function unpackStaticValue(Slice slice, SchemaType schemaType)
    internal
    pure
    returns (bytes32 value, Slice nextSubslice)
  {
    if (schemaType.isDynamic()) {
      revert Pack__SchemaTypeNotStatic();
    }
    uint256 length = schemaType.staticLength();
    (slice, nextSubslice) = slice.splitAt(length);
    value = slice.toBytes32();

    if (length != 32 && !schemaType.isLeftAligned()) {
      // right-align a non-word-length value
      value = bytes32(uint256(value) >> ((32 - length) * 8));
    }

    return (value, nextSubslice);
  }

  function packBytes(
    Slice slice,
    SchemaType schemaType,
    bytes memory value
  ) internal view returns (Slice nextSubslice) {
    if (schemaType != SchemaType.BYTES && schemaType != SchemaType.STRING) {
      revert Pack__SchemaTypeNotBytes();
    }
    uint256 length = value.length;
    if (length > MAX_DYNAMIC_LENGTH) {
      revert Pack__DynamicLengthOverflow();
    }

    // copy packed length
    Slice sliceForLength;
    (sliceForLength, slice) = slice.splitAt(DYNAMIC_LENGTH_BYTES);
    sliceForLength.copyFromValueRightAligned(bytes32(length), DYNAMIC_LENGTH_BYTES);
    // copy bytes
    (slice, nextSubslice) = slice.splitAt(length);
    slice.copyFromSlice(toSlice(value));

    return nextSubslice;
  }

  function packBytesSingle(SchemaType schemaType, bytes memory value) internal view returns (bytes memory data) {
    data = new bytes(packedBytesSize(schemaType, value.length));
    packBytes(toSlice(data), schemaType, value);
    return data;
  }

  function unpackBytes(Slice slice, SchemaType schemaType)
    internal
    view
    returns (bytes memory value, Slice nextSubslice)
  {
    if (schemaType != SchemaType.BYTES && schemaType != SchemaType.STRING) {
      revert Pack__SchemaTypeNotBytes();
    }

    // copy packed length
    Slice sliceForLength;
    (sliceForLength, slice) = slice.splitAt(DYNAMIC_LENGTH_BYTES);
    uint256 length = unpackLength(sliceForLength.toBytes32());

    (slice, nextSubslice) = slice.splitAt(length);
    value = slice.toBytes();
    return (value, nextSubslice);
  }

  function packArray(
    Slice slice,
    SchemaType schemaType,
    bytes32[] memory value
  ) internal view returns (Slice nextSubslice) {
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

    if (unitLength == 32) {
      // if tightly packed already, then encode as-is
      slice.copyFromSlice(toSlice(value));
      return slice.getAfter(value.length);
    } else {
      // tightly pack array items
      for (uint256 i; i < value.length; i++) {
        packStaticValue(slice, innerType, value[i]);
        slice = slice.getAfter(unitLength);
      }
      return slice;
    }
  }

  function packArraySingle(SchemaType schemaType, bytes32[] memory value) internal view returns (bytes memory data) {
    data = new bytes(packedArraySize(schemaType, value.length));
    packArray(toSlice(data), schemaType, value);
    return data;
  }

  function unpackArray(Slice slice, SchemaType schemaType)
    internal
    view
    returns (bytes32[] memory value, Slice nextSubslice)
  {
    if (!schemaType.isDynamic() || schemaType.isUnitDynamic()) {
      revert Pack__SchemaTypeNotArray();
    }

    SchemaType innerType = schemaType.arrayInnerType();
    uint256 unitLength = innerType.staticLength();
    bytes32 packedLength = slice.getBefore(DYNAMIC_LENGTH_BYTES).toBytes32();
    uint256 byteLength = unpackLength(packedLength);
    uint256 length = byteLength / unitLength;

    slice = slice.getAfter(DYNAMIC_LENGTH_BYTES);

    value = new bytes32[](length);
    if (unitLength == 32) {
      // if the decoded value is also tightly packed, then return as-is
      toSlice(value).copyFromSlice(slice);
      slice = slice.getAfter(byteLength);
    } else {
      // pad tightly packed items
      for (uint256 i; i < value.length; i++) {
        (value[i], slice) = unpackStaticValue(slice, innerType);
      }
    }
    return (value, slice);
  }

  function packNestedDynamicValue(SchemaType schemaType, bytes32[] memory value) private pure returns (bytes memory) {
    if (!schemaType.isUnitDynamic()) {
      revert Pack__SchemaTypeNotBytesArray();
    }
    // TODO this (bytes_array, string_array)
  }
}
