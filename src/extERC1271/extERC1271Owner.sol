// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title extERC1271Ownable
 * @dev Implementation of the ERC1271 standard for signature validation, with extended functionality.
 * This contract allows to validate signatures based on the owner of the extendable contract.
 */
contract extERC1271Ownable {
    // Magic value returned by isValidSignature for valid signatures
    bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    // Magic value returned by isValidSignature for invalid signatures
    bytes4 internal constant ERC1271_MAGIC_VALUE_INVALID = 0xffffffff;

    // Address of the implementation contract
    address public immutable IMPLEMENTATION_ADDR;

    /// @notice Initializes the contract with the implementation address
    /// @param implementation Address of the implementation contract
    constructor(address implementation) {
        IMPLEMENTATION_ADDR = implementation;
    }

    /// @notice Validates a signature against the owner of the implementation contract
    /// @dev Implements ERC-1271 isValidSignature interface
    /// @param dataHash Keccak256 hash of the data signed
    /// @param signature Signature bytes
    /// @return bytes4 Magic value 0x1626ba7e if signature is valid, 0xffffffff otherwise
    function isValidSignature(
        bytes32 dataHash,
        bytes memory signature
    ) public view returns (bytes4) {
        // if isValidSignature fail, the error is catched in returnedError
        (address recoveredAddress, ECDSA.RecoverError returnedError, ) = ECDSA
            .tryRecover(dataHash, signature);

        // if recovering throws an error, return the fail value
        if (returnedError != ECDSA.RecoverError.NoError)
            return ERC1271_MAGIC_VALUE_INVALID;

        // Compare the recovered address to the owner of this contract
        if (recoveredAddress == Ownable(IMPLEMENTATION_ADDR).owner()) {
            return ERC1271_MAGIC_VALUE;
        } else {
            return ERC1271_MAGIC_VALUE_INVALID;
        }
    }
}
