// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Swap} from "../src/Swap.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetFactory} from "../src/AssetFactory.sol";
import {AssetIssuer} from "../src/AssetIssuer.sol";
import {AssetRebalancer} from "../src/AssetRebalancer.sol";
import {AssetFeeManager} from "../src/AssetFeeManager.sol";
import {StakeFactory} from "../src/StakeFactory.sol";
import {StakeToken} from "../src/StakeToken.sol";
import {AssetLocking} from "../src/AssetLocking.sol";
import {USSI} from "../src/USSI.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployerScript is Script {
    function setUp() public {}

    function run() public {
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        address orderSigner = vm.envAddress("ORDER_SIGNER");
        address redeemToken = vm.envAddress("REDEEM_TOKEN");
        string memory chain = vm.envString("CHAIN_CODE");
        vm.startBroadcast();
        Swap swap = new Swap(owner, chain);
        AssetToken tokenImpl = new AssetToken();
        AssetFactory factoryImpl = new AssetFactory();
        address factoryAddress = address(new TransparentUpgradeableProxy(
            address(factoryImpl),
            owner,
            abi.encodeCall(AssetFactory.initialize, (owner, address(swap), vault, chain, address(tokenImpl)))
        ));
        AssetFactory factory = AssetFactory(factoryAddress);
        AssetIssuer issuer = new AssetIssuer(owner, address(factory));
        AssetRebalancer rebalancer = new AssetRebalancer(owner, address(factory));
        AssetFeeManager feeManager = new AssetFeeManager(owner, address(factory));
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
