// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

using WorldResourceIdInstance for ResourceId;

// name is "CallWithSignatureAlt"
// version is "1"
// chainId must match block.chainid
// verifyingContract is the world address
bytes32 constant DOMAIN_TYPEHASH = keccak256(
  "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);
bytes32 constant CALL_TYPEHASH = keccak256(
  "Call(address signer,string systemNamespace,string systemName,bytes callData,uint256 nonce)"
);

/**
 * @notice Generate the message hash for a given delegation signature.
 * For EIP712 signatures https://eips.ethereum.org/EIPS/eip-712
 * @dev We include the signer address to prevent generating a signature that recovers to a random address that didn't sign the message.
 * @param signer The address on whose behalf the system is called.
 * @param systemId The ID of the system to be called.
 * @param callData The ABI data for the system call.
 * @param nonce The nonce of the signer
 * @param worldAddress The world address
 * @return Return the message hash.
 */
function getSignedMessageHash(
  address signer,
  ResourceId systemId,
  bytes memory callData,
  uint256 nonce,
  address worldAddress
) view returns (bytes32) {
  bytes32 domainSeperator = keccak256(
    abi.encode(
      DOMAIN_TYPEHASH,
      keccak256(bytes("CallWithSignatureAlt")),
      keccak256(bytes("1")),
      uint256(block.chainid),
      worldAddress
    )
  );

  return
    keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeperator,
        keccak256(
          abi.encode(
            CALL_TYPEHASH,
            signer,
            keccak256(abi.encodePacked(WorldResourceIdLib.toTrimmedString(systemId.getNamespace()))),
            keccak256(abi.encodePacked(WorldResourceIdLib.toTrimmedString(systemId.getName()))),
            keccak256(callData),
            nonce
          )
        )
      )
    );
}
