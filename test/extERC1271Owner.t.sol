// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Extendable.sol";
import "../src/extERC1271/extERC1271Owner.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IERC1271 {
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue);
}

contract extERC1271OwnableTest is Test {
    Extendable public extendable;
    extERC1271Ownable public erc1271Extension;
    address public owner;
    address public user;
    uint256 public ownerPrivateKey;

    bytes4 constant IS_VALID_SIGNATURE_SELECTOR =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    // Magic value returned by isValidSignature for valid signatures
    bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    // Magic value returned by isValidSignature for invalid signatures
    bytes4 internal constant ERC1271_MAGIC_VALUE_INVALID = 0xffffffff;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        user = address(0x123);

        vm.prank(owner);
        extendable = new Extendable(owner);

        erc1271Extension = new extERC1271Ownable(address(extendable));

        vm.prank(owner);
        extendable.addExtension(
            IS_VALID_SIGNATURE_SELECTOR,
            address(erc1271Extension)
        );
    }

    function testValidSignature() public {
        bytes32 messageHash = keccak256("Hello, World!");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bytes4 result = IERC1271(address(extendable)).isValidSignature(
            messageHash,
            signature
        );
        assertEq(result, ERC1271_MAGIC_VALUE);
    }

    function testInvalidSignature() public {
        bytes32 messageHash = keccak256("Hello, World!");
        uint256 randomPrivateKey = 0xB0B;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            randomPrivateKey,
            messageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        bytes4 result = IERC1271(address(extendable)).isValidSignature(
            messageHash,
            signature
        );
        assertEq(result, ERC1271_MAGIC_VALUE_INVALID);
    }

    function testInvalidSignatureLength() public {
        bytes32 messageHash = keccak256("Hello, World!");
        bytes memory invalidSignature = abi.encodePacked(
            bytes32(0),
            bytes32(0),
            uint8(0)
        );

        bytes4 result = IERC1271(address(extendable)).isValidSignature(
            messageHash,
            invalidSignature
        );
        assertEq(result, ERC1271_MAGIC_VALUE_INVALID);
    }

    function testChangeOwner() public {
        address newOwner = address(0x456);

        vm.prank(owner);
        Ownable(address(extendable)).transferOwnership(newOwner);

        bytes32 messageHash = keccak256("Hello, World!");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bytes4 result = IERC1271(address(extendable)).isValidSignature(
            messageHash,
            signature
        );
        assertEq(result, ERC1271_MAGIC_VALUE_INVALID);
    }

    function testRemoveExtension() public {
        vm.prank(owner);
        extendable.removeExtension(IS_VALID_SIGNATURE_SELECTOR);

        bytes32 messageHash = keccak256("Hello, World!");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("No extension found");
        IERC1271(address(extendable)).isValidSignature(messageHash, signature);
    }
}
