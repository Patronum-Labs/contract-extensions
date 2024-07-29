// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ExtERC165StorageSingleton
 * @dev Implementation of the ERC165 standard for interface detection, with extended functionality.
 * This contract allows each address to manage their own interface support independently.
 */
contract ExtERC165StorageSingleton is IERC165 {
    /// @dev Mapping to store interface support for each address
    mapping(address => mapping(bytes4 => bool)) private _supportedInterfaces;

    /**
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return bool True if the contract supports `interfaceId`, false otherwise
     * @notice This function checks if the caller supports the given interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return _supportedInterfaces[msg.sender][interfaceId];
    }

    /**
     * @dev Adds support for an interface for the calling address.
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function addSupport(bytes4 interfaceId) public {
        _addSupport(msg.sender, interfaceId);
    }

    /**
     * @dev Removes support for an interface for the calling address.
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function removeSupport(bytes4 interfaceId) public {
        _supportedInterfaces[msg.sender][interfaceId] = false;
    }

    /**
     * @dev Internal function to add support for an interface.
     * @param account The address for which to add support
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @notice This function is used internally to add interface support for a specific address
     */
    function _addSupport(address account, bytes4 interfaceId) internal {
        _supportedInterfaces[account][interfaceId] = true;
    }
}
