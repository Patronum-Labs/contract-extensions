// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ExtERC165StorageOwnable
 * @dev Implementation of the ERC165 standard for interface detection, with extended functionality.
 * This contract allows for an address to manage their own interface support independently.
 */
contract extERC165StorageOwnable is Ownable, IERC165 {
    /// @dev Mapping to store interface support
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor(address initialOwner) Ownable(initialOwner) {
        // Empty constructor
    }

    /**
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return bool True if the contract supports `interfaceId`, false otherwise
     * @notice This function checks if the caller supports the given interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Adds support for an interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     */
    function addSupport(bytes4 interfaceId) public onlyOwner {
        _addSupport(interfaceId);
    }

    /**
     * @dev Removes support for an interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     */
    function removeSupport(bytes4 interfaceId) public onlyOwner {
        _supportedInterfaces[interfaceId] = false;
    }

    /**
     * @dev Internal function to add support for an interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     */
    function _addSupport(bytes4 interfaceId) internal {
        _supportedInterfaces[interfaceId] = true;
    }
}
