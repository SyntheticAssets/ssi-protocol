// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Swap} from "../src/Swap.sol";
import {AssetFactory} from "../src/AssetFactory.sol";
import {AssetIssuer} from "../src/AssetIssuer.sol";
import {AssetRebalancer} from "../src/AssetRebalancer.sol";
import {AssetFeeManager} from "../src/AssetFeeManager.sol";

contract DeployerScript is Script {
    function setUp() public {}

    function run() public {
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        string memory chain = vm.envString("CHAIN_CODE");
        vm.startBroadcast();
        Swap swap = new Swap(owner, chain);
        AssetFactory factory = new AssetFactory(owner, address(swap), vault, chain);
        AssetIssuer issuer = new AssetIssuer(owner, address(factory));
        AssetRebalancer rebalancer = new AssetRebalancer(owner, address(factory));
        AssetFeeManager fee_manager = new AssetFeeManager(owner, address(factory));
        vm.stopBroadcast();
        console.log(string.concat("swap=", vm.toString(address(swap))));
        console.log(string.concat("factory=", vm.toString(address(factory))));
        console.log(string.concat("issuer=", vm.toString(address(issuer))));
        console.log(string.concat("rebalancer=", vm.toString(address(rebalancer))));
        console.log(string.concat("fee_manager=", vm.toString(address(fee_manager))));
    }
}
