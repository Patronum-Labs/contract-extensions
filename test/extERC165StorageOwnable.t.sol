// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Extendable} from "../src/Extendable.sol";
import {ExtERC165StorageOwnable} from "../src/ExtERC165/ExtERC165StorageOwnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ExtERC165StorageOwnableTest is Test {
    Extendable public extendable;
    ExtERC165StorageOwnable public erc165Extension;
    address public owner;
    address public user;

    bytes4 public constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 public constant SUPPORTS_INTERFACE_SELECTOR =
        bytes4(keccak256("supportsInterface(bytes4)"));

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        extendable = new Extendable(owner);
        erc165Extension = new ExtERC165StorageOwnable(owner);
    }

    function testInitialState() public view {
        assertEq(extendable.owner(), owner);
        assertEq(erc165Extension.owner(), owner);
    }

    function testBeforeAddingExtension() public {
        vm.expectRevert("No extension found");
        (bool success, bytes memory data) = address(extendable).call(
            abi.encodeWithSelector(
                SUPPORTS_INTERFACE_SELECTOR,
                ERC165_INTERFACE_ID
            )
        );
        success;
        data;
    }

    function testAddingExtensionWithoutSupporting() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        (bool success, bytes memory result) = address(extendable).call(
            abi.encodeWithSelector(
                SUPPORTS_INTERFACE_SELECTOR,
                ERC165_INTERFACE_ID
            )
        );
        assertTrue(success);
        assertFalse(abi.decode(result, (bool)));
    }

    function testAddingSupportForERC165() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        erc165Extension.addSupport(ERC165_INTERFACE_ID);

        (bool success, bytes memory result) = address(extendable).call(
            abi.encodeWithSelector(
                SUPPORTS_INTERFACE_SELECTOR,
                ERC165_INTERFACE_ID
            )
        );
        assertTrue(success);
        assertTrue(abi.decode(result, (bool)));
    }

    function testRemovingSupportForERC165() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        erc165Extension.addSupport(ERC165_INTERFACE_ID);

        erc165Extension.removeSupport(ERC165_INTERFACE_ID);

        (bool success, bytes memory result) = address(extendable).call(
            abi.encodeWithSelector(
                SUPPORTS_INTERFACE_SELECTOR,
                ERC165_INTERFACE_ID
            )
        );
        assertTrue(success);
        assertFalse(abi.decode(result, (bool)));
    }

    function testAddingSupportNonOwner() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        erc165Extension.addSupport(ERC165_INTERFACE_ID);
    }

    function testRemovingSupportNonOwner() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        erc165Extension.addSupport(ERC165_INTERFACE_ID);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        erc165Extension.removeSupport(ERC165_INTERFACE_ID);
    }

    function testMultipleInterfaces() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4 customInterface1 = bytes4(keccak256("customInterface1()"));
        bytes4 customInterface2 = bytes4(keccak256("customInterface2()"));

        erc165Extension.addSupport(customInterface1);
        erc165Extension.addSupport(customInterface2);

        assertTrue(_checkInterfaceSupport(customInterface1));
        assertTrue(_checkInterfaceSupport(customInterface2));

        erc165Extension.removeSupport(customInterface1);

        assertFalse(_checkInterfaceSupport(customInterface1));
        assertTrue(_checkInterfaceSupport(customInterface2));
    }

    function testRemovingExtension() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        erc165Extension.addSupport(ERC165_INTERFACE_ID);

        extendable.removeExtension(SUPPORTS_INTERFACE_SELECTOR);

        vm.expectRevert("No extension found");
        (bool success, bytes memory data) = address(extendable).call(
            abi.encodeWithSelector(
                SUPPORTS_INTERFACE_SELECTOR,
                ERC165_INTERFACE_ID
            )
        );
        success;
        data;
    }

    function testAddingInvalidExtension() public {
        vm.expectRevert("Invalid extension address");
        extendable.addExtension(SUPPORTS_INTERFACE_SELECTOR, address(0));
    }

    function testRemovingNonExistentExtension() public {
        vm.expectRevert("Extension does not exist");
        extendable.removeExtension(SUPPORTS_INTERFACE_SELECTOR);
    }

    function testAddingExtensionAsNonOwner() public {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
    }

    function testRemovingExtensionAsNonOwner() public {
        extendable.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        extendable.removeExtension(SUPPORTS_INTERFACE_SELECTOR);
    }

    function _checkInterfaceSupport(
        bytes4 interfaceId
    ) internal returns (bool) {
        (bool success, bytes memory result) = address(extendable).call(
            abi.encodeWithSelector(SUPPORTS_INTERFACE_SELECTOR, interfaceId)
        );
        return success && abi.decode(result, (bool));
    }
}
