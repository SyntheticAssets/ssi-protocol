// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/ChristmasAirdrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/Utils.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract ChristmasAirdropTest is Test {
    ChristmasAirdrop public airdrop;
    MockERC20 public token1;
    MockERC20 public token2;

    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);

    bytes32 public merkleRoot;
    bytes32[] public proof1;
    bytes32[] public proof2;

    bytes32[] public leaves;
    uint256 public expirationTime;

    function setUp() public {
        vm.startPrank(owner);

        token1 = new MockERC20("Token1", "TK1", 1000 ether);
        token2 = new MockERC20("Token2", "TK2", 1000 ether);

        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        leaves = new bytes32[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            leaves[i] = keccak256(
                abi.encodePacked(recipients[i], tokens[i], amounts[i])
            );
        }
        merkleRoot = Utils.getMerkleRoot(leaves);

        expirationTime = block.timestamp + 1 days;
        airdrop = new ChristmasAirdrop(merkleRoot, expirationTime);

        token1.transfer(address(airdrop), 100 ether);
        token2.transfer(address(airdrop), 200 ether);

        proof1 = getProof(leaves, 0);
        proof2 = getProof(leaves, 1);

        console.log(recipients[0]);
        for (uint256 i = 0; i < proof1.length; i++) {
            console.logBytes32(proof1[i]);
        }

        vm.stopPrank();
    }

    function testDeployment() public {
        assertEq(airdrop.merkleRoot(), merkleRoot);
        assertEq(airdrop.expirationTime(), expirationTime);
    }

    function testSetExpirationTime() public {
        uint256 newExpirationTime = block.timestamp + 2 days;
        vm.startPrank(owner);
        airdrop.setExpirationTime(newExpirationTime);
        assertEq(airdrop.expirationTime(), newExpirationTime);
        vm.stopPrank();
    }

    function testSetMerkleRoot() public {
        bytes32 newMerkleRoot = keccak256(abi.encodePacked("new root"));

        vm.startPrank(owner);
        airdrop.setMerkleRoot(newMerkleRoot);
        assertEq(airdrop.merkleRoot(), newMerkleRoot);
        vm.stopPrank();
    }

    function testClaimAirdropAfterExpiration() public {
        vm.warp(expirationTime + 1);

        vm.prank(user1);
        vm.expectRevert("Airdrop has expired");
        airdrop.claimAirdrop(address(token1), 100 ether, proof1);
    }

    function testClaimAirdrop() public {
        vm.prank(user1);
        airdrop.claimAirdrop(address(token1), 100 ether, proof1);
        assertEq(token1.balanceOf(user1), 100 ether);

        vm.startPrank(user1);
        vm.expectRevert("Airdrop already claimed for this token");
        airdrop.claimAirdrop(address(token1), 100 ether, proof1);
        vm.stopPrank();
    }

    function testClaimAirdropInvalidProof() public {
        vm.prank(user1);
        vm.expectRevert("Invalid Merkle Proof");
        airdrop.claimAirdrop(address(token1), 100 ether, proof2);
    }

    function testBatchAirdrop() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;

        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = proof1;
        proofs[1] = proof2;

        vm.prank(owner);
        airdrop.batchAirdrop(recipients, tokens, amounts, proofs);

        assertEq(token1.balanceOf(user1), 100 ether);
        assertEq(token2.balanceOf(user2), 200 ether);

        vm.prank(owner);
        airdrop.batchAirdrop(recipients, tokens, amounts, proofs);

        assertEq(token1.balanceOf(user1), 100 ether);
        assertEq(token2.balanceOf(user2), 200 ether);
    }

    function testWithdrawTokens() public {
        uint256 remaining = token1.balanceOf(address(airdrop));
        vm.prank(owner);
        airdrop.withdrawTokens(owner, address(token1), remaining);
        assertEq(token1.balanceOf(owner), remaining + (1000 ether - 100 ether));
    }

    function getProof(
        bytes32[] memory leaves,
        uint256 index
    ) internal pure returns (bytes32[] memory proof) {
        uint256 n = leaves.length;
        proof = new bytes32[](0);
        while (n > 1) {
            if (index % 2 == 0 && index + 1 < n) {
                proof = append(proof, leaves[index + 1]);
            } else if (index % 2 == 1) {
                proof = append(proof, leaves[index - 1]);
            }
            index = index / 2;
            for (uint256 i = 0; i < n / 2; i++) {
                leaves[i] = _hashPair(leaves[2 * i], leaves[2 * i + 1]);
            }
            if (n % 2 == 1) {
                leaves[n / 2] = leaves[n - 1];
                n = n / 2 + 1;
            } else {
                n = n / 2;
            }
        }
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return
            a < b
                ? keccak256(abi.encodePacked(a, b))
                : keccak256(abi.encodePacked(b, a));
    }

    function append(
        bytes32[] memory array,
        bytes32 value
    ) internal pure returns (bytes32[] memory newArray) {
        newArray = new bytes32[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
    }
}
