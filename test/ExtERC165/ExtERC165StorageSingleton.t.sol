// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Extendable} from "../../src/Extendable.sol";
import {ExtERC165StorageSingleton} from "../../src/ExtERC165/ExtERC165StorageSingleton.sol";

contract ExtERC165StorageSingletonTest is Test {
    ExtERC165StorageSingleton public erc165Extension;
    Extendable public extendable1;
    Extendable public extendable2;
    Extendable public extendable3;
    address public owner;

    bytes4 public constant ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    bytes4 public constant SUPPORTS_INTERFACE_SELECTOR =
        IERC165.supportsInterface.selector;
    bytes4 public constant ADD_SUPPORT_SELECTOR =
        bytes4(keccak256("addSupport(bytes4)"));
    bytes4 public constant REMOVE_SUPPORT_SELECTOR =
        bytes4(keccak256("removeSupport(bytes4)"));

    function setUp() public {
        owner = address(this);
        erc165Extension = new ExtERC165StorageSingleton();
        extendable1 = new Extendable(owner);
        extendable2 = new Extendable(owner);
        extendable3 = new Extendable(owner);
    }

    function testAddingExtension() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        assertFalse(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
    }

    function testAddSupport() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
        vm.expectRevert("No extension found");
        IERC165(address(extendable2)).supportsInterface(ERC165_INTERFACE_ID);
    }

    function testRemoveSupport() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        assertTrue(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(REMOVE_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        assertFalse(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
    }

    function testMultipleExtendableSupport() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        extendable2.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4 customInterfaceId = bytes4(keccak256("customInterface()"));

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        extendable2.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, customInterfaceId)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
        assertFalse(
            IERC165(address(extendable1)).supportsInterface(customInterfaceId)
        );

        assertFalse(
            IERC165(address(extendable2)).supportsInterface(ERC165_INTERFACE_ID)
        );
        assertTrue(
            IERC165(address(extendable2)).supportsInterface(customInterfaceId)
        );
    }

    function testRemovingExtension() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );

        extendable1.removeExtension(SUPPORTS_INTERFACE_SELECTOR);

        vm.expectRevert("No extension found");
        IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID);
    }

    function testBeforeAddingExtension() public {
        vm.expectRevert("No extension found");
        IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID);
    }

    function testAddSupportForMultipleInterfaces() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4 customInterface1 = bytes4(keccak256("customInterface1()"));
        bytes4 customInterface2 = bytes4(keccak256("customInterface2()"));

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, customInterface1)
        );
        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, customInterface2)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(customInterface1)
        );
        assertTrue(
            IERC165(address(extendable1)).supportsInterface(customInterface2)
        );
    }

    function testRemoveSupportForNonExistentInterface() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4 nonExistentInterface = bytes4(
            keccak256("nonExistentInterface()")
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(
                REMOVE_SUPPORT_SELECTOR,
                nonExistentInterface
            )
        );

        assertFalse(
            IERC165(address(extendable1)).supportsInterface(
                nonExistentInterface
            )
        );
    }

    function testAddSupportTwice() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
    }

    function testRemoveSupportTwice() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(REMOVE_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );
        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(REMOVE_SUPPORT_SELECTOR, ERC165_INTERFACE_ID)
        );

        assertFalse(
            IERC165(address(extendable1)).supportsInterface(ERC165_INTERFACE_ID)
        );
    }

    function testAddAndRemoveMultipleInterfaces() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4[] memory interfaces = new bytes4[](3);
        interfaces[0] = bytes4(keccak256("interface1()"));
        interfaces[1] = bytes4(keccak256("interface2()"));
        interfaces[2] = bytes4(keccak256("interface3()"));

        for (uint256 i = 0; i < interfaces.length; i++) {
            extendable1.execute(
                address(erc165Extension),
                abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, interfaces[i])
            );
            assertTrue(
                IERC165(address(extendable1)).supportsInterface(interfaces[i])
            );
        }

        for (uint256 i = 0; i < interfaces.length; i++) {
            extendable1.execute(
                address(erc165Extension),
                abi.encodeWithSelector(REMOVE_SUPPORT_SELECTOR, interfaces[i])
            );
            assertFalse(
                IERC165(address(extendable1)).supportsInterface(interfaces[i])
            );
        }
    }

    function testCrossExtendableInterference() public {
        extendable1.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );
        extendable2.addExtension(
            SUPPORTS_INTERFACE_SELECTOR,
            address(erc165Extension)
        );

        bytes4 customInterface = bytes4(keccak256("customInterface()"));

        extendable1.execute(
            address(erc165Extension),
            abi.encodeWithSelector(ADD_SUPPORT_SELECTOR, customInterface)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(customInterface)
        );
        assertFalse(
            IERC165(address(extendable2)).supportsInterface(customInterface)
        );

        extendable2.execute(
            address(erc165Extension),
            abi.encodeWithSelector(REMOVE_SUPPORT_SELECTOR, customInterface)
        );

        assertTrue(
            IERC165(address(extendable1)).supportsInterface(customInterface)
        );
        assertFalse(
            IERC165(address(extendable2)).supportsInterface(customInterface)
        );
    }
}
