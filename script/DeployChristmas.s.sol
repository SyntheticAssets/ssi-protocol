// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ChristmasAirdrop.sol";
import "../src/Utils.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DeployScript is Script {
    ChristmasAirdrop public airdrop;

    function run() external {
        // setting
        string memory merkleRootHex = vm.readFile(
            "./test/data/merkle_root.txt"
        );
        bytes32 merkleRoot = vm.parseBytes32(merkleRootHex);

        // deploy ChristmasAirdrop contract
        uint256 expirationTime = block.timestamp + 7 days;
        vm.startBroadcast();
        airdrop = new ChristmasAirdrop(merkleRoot, expirationTime);
        vm.stopBroadcast();

        console.log("ChristmasAirdrop deployed at:", address(airdrop));
    }

    function readAddressArray(
        string memory filePath
    ) internal view returns (address[] memory) {
        string memory jsonData = vm.readFile(filePath);
        bytes memory parsed = vm.parseJson(
            jsonData,
            string.concat(".", "tokens")
        );
        address[] memory addrArray = abi.decode(parsed, (address[]));
        return addrArray;
    }

    function readUint256Array(
        string memory filePath
    ) internal view returns (uint256[] memory) {
        string memory jsonData = vm.readFile(filePath);
        bytes memory parsed = vm.parseJson(jsonData, ".amounts");
        string[] memory strArray = abi.decode(parsed, (string[]));
        uint256[] memory uintArray = new uint256[](strArray.length);
        for (uint i = 0; i < strArray.length; i++) {
            uintArray[i] = vm.parseUint(strArray[i]);
        }
        return uintArray;
    }
}
