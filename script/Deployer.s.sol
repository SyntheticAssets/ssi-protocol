// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;
import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {Swap} from "../src/Swap.sol";
import {AssetFactory} from "../src/AssetFactory.sol";
import {AssetIssuer} from "../src/AssetIssuer.sol";
import {AssetRebalancer} from "../src/AssetRebalancer.sol";
import {AssetFeeManager} from "../src/AssetFeeManager.sol";
import {StakeFactory} from "../src/StakeFactory.sol";
import {StakeToken} from "../src/StakeToken.sol";
import {AssetLocking} from "../src/AssetLocking.sol";
import {USSI} from "../src/USSI.sol";

contract DeployAssetController is Script {
    function setUp() public {}

    function run() public {
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        address orderSigner = vm.envAddress("ORDER_SIGNER");
        address redeemToken = vm.envAddress("REDEEM_TOKEN");
        string memory chain = vm.envString("CHAIN_CODE");
        vm.startBroadcast();
        address swap = Upgrades.deployTransparentProxy("Swap.sol", owner, abi.encodeCall(Swap.initialize, (owner, chain)));
        address factory = Upgrades.deployTransparentProxy("AssetFactory.sol", owner, abi.encodeCall(AssetFactory.initialize, (owner, swap, vault, chain)));
        address issuer = Upgrades.deployTransparentProxy("AssetIssuer.sol", owner, abi.encodeCall(AssetIssuer.initialize, (owner, factory)));
        address rebalancer = Upgrades.deployTransparentProxy("AssetRebalancer.sol", owner, abi.encodeCall(AssetRebalancer.initialize, (owner, factory)));
        address feeManager = Upgrades.deployTransparentProxy("AssetFeeManager.sol", owner, abi.encodeCall(AssetFeeManager.initialize, (owner, factory)));
        vm.stopBroadcast();
        StakeFactory stakeFactory = new StakeFactory(owner, address(factory));
        AssetLocking assetLocking = new AssetLocking(owner);
        USSI uSSI = new USSI(owner, orderSigner, address(factory), redeemToken);
        StakeToken sUSSI = new StakeToken("Staked USSI", "sUSSI", address(uSSI), 7 days);
        vm.stopBroadcast();
        console.log(string.concat("swap=", vm.toString(address(swap))));
        console.log(string.concat("factory=", vm.toString(address(factory))));
        console.log(string.concat("issuer=", vm.toString(address(issuer))));
        console.log(string.concat("rebalancer=", vm.toString(address(rebalancer))));
        console.log(string.concat("feeManager=", vm.toString(address(feeManager))));
        console.log(string.concat("stakeFactory=", vm.toString(address(stakeFactory))));
        console.log(string.concat("assetLocking=", vm.toString(address(assetLocking))));
        console.log(string.concat("USSI=", vm.toString(address(uSSI))));
        console.log(string.concat("sUSSI=", vm.toString(address(sUSSI))));
    }
}
