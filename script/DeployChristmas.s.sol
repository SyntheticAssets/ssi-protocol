// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ChristmasAirdrop.sol";
import "../src/Utils.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DeployScript is Script {
    function run() external {
        // 设置接收者和空投金额
        address[] memory recipients = new address[](3);
        recipients[0] = 0x1234567890123456789012345678901234567890;
        recipients[1] = 0x2345678901234567890123456789012345678901;
        recipients[2] = 0x3456789012345678901234567890123456789012;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        bytes32[] memory leaves = new bytes32[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(recipients[i], amounts[i]));
        }
        bytes32 merkleRoot = Utils.getRoot(leaves);

        vm.startBroadcast();
        ChristmasAirdrop airdrop = new ChristmasAirdrop(merkleRoot);
        vm.stopBroadcast();

        console.log("ChristmasAirdrop deployed at:", address(airdrop));
    }
}