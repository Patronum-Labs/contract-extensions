// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Extendable
 * @dev This contract represent the simplest version of an extendable contract where functionality
 * can be added or removed dynamically through extensions.
 */
contract Extendable is Ownable {
    /**
     * @dev Mapping of function selectors to extension addresses.
     */
    mapping(bytes4 => address) public extensions;

    /**
     * @dev Sets the initial owner of the contract.
     * @param initialOwner The address to be set as the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // Empty constructor
    }

    /**
     * @dev Executes a function call on the target contract.
     * @param target The address of the target contract.
     * @param data The calldata to be sent to the target contract.
     */
    function execute(
        address target,
        bytes calldata data
    ) external returns (bytes memory) {
        (bool success, bytes memory result) = target.call(data);
        require(success, "Execution failed");
        return result;
    }

    /**
     * @dev Adds an extension for a specific function selector.
     * @param selector The 4-byte function selector.
     * @param extension The address of the extension contract.
     * @notice Only the contract owner can call this function.
     */
    function addExtension(bytes4 selector, address extension) public onlyOwner {
        require(extension != address(0), "Invalid extension address");
        extensions[selector] = extension;
    }

    /**
     * @dev Removes an extension for a specific function selector.
     * @param selector The 4-byte function selector of the extension to be removed.
     * @notice Only the contract owner can call this function.
     */
    function removeExtension(bytes4 selector) public onlyOwner {
        require(extensions[selector] != address(0), "Extension does not exist");
        delete extensions[selector];
    }

    /**
     * @dev Fallback function to delegate calls to extensions.
     * This function is called for all messages sent to this contract (except for add and remove extensions).
     * It delegates the call to the appropriate extension based on the function selector.
     */
    fallback() external {
        // if msg.data.length is less than 4 bytes return
        if (msg.data.length < 4) {
            return;
        }

        // read the address of the ext based on msg.sig
        bytes4 selector = msg.sig;
        address extension = extensions[selector];

        // if no extension was found, revert
        if (extension == address(0)) {
            revert("No extension found");
        }

        // Call the extension with the original call data associated with the sender
        (bool success, bytes memory result) = extension.call(
            abi.encodePacked(msg.data, msg.sender)
        );

        // Handle the result of the extension call
        if (success) {
            // If successful, return the result
            assembly {
                return(add(result, 32), mload(result))
            }
        } else {
            // `mload(result)` -> offset in memory where `result.length` is located
            // `add(result, 32)` -> offset in memory where `result` data starts
            // solhint-disable no-inline-assembly
            /// @solidity memory-safe-assembly
            assembly {
                let resultdata_size := mload(result)
                revert(add(result, 32), resultdata_size)
            }
        }
    }
}
