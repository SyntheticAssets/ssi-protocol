// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/ChristmasAirdrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "forge-std/console.sol";

contract ChristmasAirdropTest is Test {
    ChristmasAirdrop public christmasAirdrop;
    address public owner;

    bytes32 public merkleRoot;
    bytes32[] public proof1;
    bytes32[] public proof2;
    bytes32[] public proof3;

    address[] public recipients;
    uint256[] public amounts;

    bytes32[] public leaves;

    function setUp() public {
        owner = address(this);

        // 设置测试账户
        recipients = new address[](3);
        recipients[0] = address(0x1);
        recipients[1] = address(0x2);
        recipients[2] = address(0x3);

        amounts = new uint256[](3);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        leaves = new bytes32[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(recipients[i], amounts[i]));
        }

        merkleRoot = getRoot(leaves);
        christmasAirdrop = new ChristmasAirdrop(merkleRoot);

        proof1 = getProof(leaves, 0);
        proof2 = getProof(leaves, 1);
        proof3 = getProof(leaves, 2);
    }

    function testTotalSupply() public {
        assertEq(
            christmasAirdrop.totalSupply(),
            1_000_000 * 10**18
        );
    }

    function testClaimAirdrop() public {
        vm.startPrank(recipients[0]);
        christmasAirdrop.claimAirdrop(amounts[0], proof1);
        assertEq(
            christmasAirdrop.balanceOf(recipients[0]),
            amounts[0]);
        vm.stopPrank();

        vm.startPrank(recipients[0]);
        vm.expectRevert("Airdrop already claimed");
        christmasAirdrop.claimAirdrop(amounts[0], proof1);
        vm.stopPrank();
    }

    function testInvalidProof() public {
        vm.startPrank(recipients[0]);
        vm.expectRevert("Invalid Merkle Proof");
        christmasAirdrop.claimAirdrop(amounts[0], proof2);
        vm.stopPrank();
    }

    function testSetMerkleRoot() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new merkle root"));
        christmasAirdrop.setMerkleRoot(newRoot);
        assertEq(
            christmasAirdrop.merkleRoot(),
            newRoot
        );
    }

    function getRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint256 n = leaves.length;
        while (n > 1) {
            for (uint256 i = 0; i < n / 2; i++) {
                leaves[i] = parentHash(leaves[2 * i], leaves[2 * i + 1]);
            }
            if (n % 2 == 1) {
                leaves[n / 2] = leaves[n - 1];
                n = n / 2 + 1;
            } else {
                n = n / 2;
            }
        }
        return leaves[0];
    }

    function getProof(bytes32[] memory leaves, uint256 index) internal pure returns (bytes32[] memory) {
        uint256 n = leaves.length;
        bytes32[] memory proof = new bytes32[](0);
        while (n > 1) {
            if (index % 2 == 0 && index + 1 < n) {
                proof = append(proof, leaves[index + 1]);
            } else if (index % 2 == 1) {
                proof = append(proof, leaves[index - 1]);
            }
            index = index / 2;
            for (uint256 i = 0; i < n / 2; i++) {
                leaves[i] = parentHash(leaves[2 * i], leaves[2 * i + 1]);
            }
            if (n % 2 == 1) {
                leaves[n / 2] = leaves[n - 1];
                n = n / 2 + 1;
            } else {
                n = n / 2;
            }
        }
        return proof;
    }

    function parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encodePacked(a, b));
        } else {
            return keccak256(abi.encodePacked(b, a));
        }
    }

    function append(bytes32[] memory array, bytes32 value) internal pure returns (bytes32[] memory) {
        bytes32[] memory newArray = new bytes32[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
        return newArray;
    }
}