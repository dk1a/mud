// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// WARNING: SchemaType methods use hardcoded enum indexes, review them after any changes to the enum
enum SchemaType {
  UINT8,
  UINT16,
  UINT24,
  UINT32,
  UINT40,
  UINT48,
  UINT56,
  UINT64,
  UINT72,
  UINT80,
  UINT88,
  UINT96,
  UINT104,
  UINT112,
  UINT120,
  UINT128,
  UINT136,
  UINT144,
  UINT152,
  UINT160,
  UINT168,
  UINT176,
  UINT184,
  UINT192,
  UINT200,
  UINT208,
  UINT216,
  UINT224,
  UINT232,
  UINT240,
  UINT248,
  UINT256,
  INT8,
  INT16,
  INT24,
  INT32,
  INT40,
  INT48,
  INT56,
  INT64,
  INT72,
  INT80,
  INT88,
  INT96,
  INT104,
  INT112,
  INT120,
  INT128,
  INT136,
  INT144,
  INT152,
  INT160,
  INT168,
  INT176,
  INT184,
  INT192,
  INT200,
  INT208,
  INT216,
  INT224,
  INT232,
  INT240,
  INT248,
  INT256,
  BYTES1,
  BYTES2,
  BYTES3,
  BYTES4,
  BYTES5,
  BYTES6,
  BYTES7,
  BYTES8,
  BYTES9,
  BYTES10,
  BYTES11,
  BYTES12,
  BYTES13,
  BYTES14,
  BYTES15,
  BYTES16,
  BYTES17,
  BYTES18,
  BYTES19,
  BYTES20,
  BYTES21,
  BYTES22,
  BYTES23,
  BYTES24,
  BYTES25,
  BYTES26,
  BYTES27,
  BYTES28,
  BYTES29,
  BYTES30,
  BYTES31,
  BYTES32,
  BOOL,
  ADDRESS,
  BIT,
  BYTES,
  STRING,
  UINT8_ARRAY,
  UINT16_ARRAY,
  UINT24_ARRAY,
  UINT32_ARRAY,
  UINT40_ARRAY,
  UINT48_ARRAY,
  UINT56_ARRAY,
  UINT64_ARRAY,
  UINT72_ARRAY,
  UINT80_ARRAY,
  UINT88_ARRAY,
  UINT96_ARRAY,
  UINT104_ARRAY,
  UINT112_ARRAY,
  UINT120_ARRAY,
  UINT128_ARRAY,
  UINT136_ARRAY,
  UINT144_ARRAY,
  UINT152_ARRAY,
  UINT160_ARRAY,
  UINT168_ARRAY,
  UINT176_ARRAY,
  UINT184_ARRAY,
  UINT192_ARRAY,
  UINT200_ARRAY,
  UINT208_ARRAY,
  UINT216_ARRAY,
  UINT224_ARRAY,
  UINT232_ARRAY,
  UINT240_ARRAY,
  UINT248_ARRAY,
  UINT256_ARRAY,
  INT8_ARRAY,
  INT16_ARRAY,
  INT24_ARRAY,
  INT32_ARRAY,
  INT40_ARRAY,
  INT48_ARRAY,
  INT56_ARRAY,
  INT64_ARRAY,
  INT72_ARRAY,
  INT80_ARRAY,
  INT88_ARRAY,
  INT96_ARRAY,
  INT104_ARRAY,
  INT112_ARRAY,
  INT120_ARRAY,
  INT128_ARRAY,
  INT136_ARRAY,
  INT144_ARRAY,
  INT152_ARRAY,
  INT160_ARRAY,
  INT168_ARRAY,
  INT176_ARRAY,
  INT184_ARRAY,
  INT192_ARRAY,
  INT200_ARRAY,
  INT208_ARRAY,
  INT216_ARRAY,
  INT224_ARRAY,
  INT232_ARRAY,
  INT240_ARRAY,
  INT248_ARRAY,
  INT256_ARRAY,
  BYTES1_ARRAY,
  BYTES2_ARRAY,
  BYTES3_ARRAY,
  BYTES4_ARRAY,
  BYTES5_ARRAY,
  BYTES6_ARRAY,
  BYTES7_ARRAY,
  BYTES8_ARRAY,
  BYTES9_ARRAY,
  BYTES10_ARRAY,
  BYTES11_ARRAY,
  BYTES12_ARRAY,
  BYTES13_ARRAY,
  BYTES14_ARRAY,
  BYTES15_ARRAY,
  BYTES16_ARRAY,
  BYTES17_ARRAY,
  BYTES18_ARRAY,
  BYTES19_ARRAY,
  BYTES20_ARRAY,
  BYTES21_ARRAY,
  BYTES22_ARRAY,
  BYTES23_ARRAY,
  BYTES24_ARRAY,
  BYTES25_ARRAY,
  BYTES26_ARRAY,
  BYTES27_ARRAY,
  BYTES28_ARRAY,
  BYTES29_ARRAY,
  BYTES30_ARRAY,
  BYTES31_ARRAY,
  BYTES32_ARRAY,
  BOOL_ARRAY,
  ADDRESS_ARRAY,
  BIT_ARRAY,
  BYTES_ARRAY,
  STRING_ARRAY
}

error SchemaType__NotStatic(SchemaType schemaType);
error SchemaType__NotDynamic(SchemaType schemaType);
error SchemaType__NotArray(SchemaType schemaType);

function isDynamic(SchemaType schemaType) pure returns (bool) {
  // 32 * 3 (uint, int, bytes)
  // + 3 (bool, address, bit)
  // - 1 (starts at 0)
  return uint8(schemaType) > 98;
}

function isUnitDynamic(SchemaType schemaType) pure returns (bool) {
  return schemaType == SchemaType.BYTES_ARRAY || schemaType == SchemaType.STRING_ARRAY;
}

function staticLength(SchemaType schemaType) pure returns (uint256) {
  uint256 val = uint8(schemaType);

  if (val < 32) {
    // uint8-256
    return (val + 1) * 8;
  } else if (val < 64) {
    // int8-256, offset by 32
    return (val + 1 - 32) * 8;
  } else if (val < 96) {
    // bytes1-32, offset by 64
    return val + 1 - 64;
  }

  // miscellaneous static-sized types
  if (val == uint8(SchemaType.BOOL)) {
    return 1;
  } else if (val == uint8(SchemaType.ADDRESS)) {
    return 20;
  } else if (val == uint8(SchemaType.BIT)) {
    return 1;
  }

  // dynamic types don't have static length
  revert SchemaType__NotStatic(schemaType);
}

function unitStaticLength(SchemaType schemaType) pure returns (uint256) {
  if (!schemaType.isDynamic()) {
    revert SchemaType__NotDynamic(schemaType);
  } else if (schemaType == SchemaType.BYTES || schemaType == SchemaType.STRING) {
    return 1;
  } else {
    SchemaType innerType = schemaType.arrayInnerType();
    // reverts for BYTES_ARRAY and STRING_ARRAY, since their innerType is dynamic
    return innerType.staticLength();
  }
}

function isLeftAligned(SchemaType schemaType) pure returns (bool) {
  uint256 val = uint8(schemaType);
  // only bytes1-32 start at MSB (address is like uint160, not bytes20)
  return (val >= 64 && val < 96) || schemaType.isDynamic();
}

function isArray(SchemaType schemaType) pure returns (bool) {
  return uint256(schemaType) >= 101;
}

function arrayInnerType(SchemaType schemaType) pure returns (SchemaType) {
  uint256 val = uint8(schemaType);
  if (!schemaType.isArray()) {
    revert SchemaType__NotArray(schemaType);
  }
  return SchemaType(val - 101);
}

using {
  isDynamic,
  isUnitDynamic,
  staticLength,
  unitStaticLength,
  isLeftAligned,
  isArray,
  arrayInnerType
} for SchemaType global;