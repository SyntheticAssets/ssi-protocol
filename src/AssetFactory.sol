// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "./Interface.sol";
import "./AssetToken.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "forge-std/console.sol";

contract AssetFactory is Ownable, IAssetFactory {
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet assetIDs;
    mapping(uint => address) public assetTokens;
    address public swap;
    address public vault;
    string public chain;

    event AssetTokenCreated(address assetTokenAddress);
    event SetVault(address vault);
    event SetSwap(address swap);

    constructor(address owner, address swap_, address vault_, string memory chain_) Ownable(owner) {
        require(swap_ != address(0), "swap address is zero");
        require(vault_ != address(0), "vault address is zero");
        swap = swap_;
        vault = vault_;
        chain = chain_;
        emit SetVault(vault);
        emit SetSwap(swap);
    }

    function setSwap(address swap_) external onlyOwner {
        require(swap_ != address(0), "swap address is zero");
        swap = swap_;
        emit SetSwap(swap);
    }

    function setVault(address vault_) external onlyOwner {
        require(vault_ != address(0), "vault address is zero");
        vault = vault_;
        emit SetVault(vault);
    }

    function createAssetToken(Asset memory asset, uint maxFee, address issuer, address rebalancer, address feeManager) external onlyOwner returns (address) {
        require(issuer != address(0) && rebalancer != address(0) && feeManager != address(0), "controllers not set");
        require(!assetIDs.contains(asset.id), "asset exists");
        AssetToken assetToken = new AssetToken({
            id_: asset.id,
            name_: asset.name,
            symbol_: asset.symbol,
            maxFee_: maxFee,
            owner: address(this)
        });
        assetToken.grantRole(assetToken.ISSUER_ROLE(), issuer);
        assetToken.grantRole(assetToken.REBALANCER_ROLE(), rebalancer);
        assetToken.grantRole(assetToken.FEEMANAGER_ROLE(), feeManager);
        assetToken.initTokenset(asset.tokenset);
        assetTokens[asset.id] = address(assetToken);
        assetIDs.add(asset.id);
        emit AssetTokenCreated(address(assetToken));
        return address(assetToken);
    }

    function hasAssetID(uint assetID) external view returns (bool) {
        return assetIDs.contains(assetID);
    }

    function getAssetIDs() external view returns (uint[] memory) {
        return assetIDs.values();
    }
}