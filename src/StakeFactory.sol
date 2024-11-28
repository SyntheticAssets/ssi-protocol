// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;
import './Interface.sol';
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import './StakeToken.sol';
import "forge-std/console.sol";

contract StakeFactory is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    address public factoryAddress;
    mapping(uint256 => address) public stakeTokens;
    EnumerableSet.UintSet private assetIDs;

    event CreateStakeToken(address stakeToken, uint256 assetID, uint48 cooldown);

    constructor(address owner, address factoryAddress_) Ownable(owner) {
        factoryAddress = factoryAddress_;
    }

    function createStakeToken(uint256 assetID, uint48 cooldown) external onlyOwner returns (address stakeToken)  {
        require(!assetIDs.contains(assetID), "stake token already exists");
        IAssetFactory factory = IAssetFactory(factoryAddress);
        address assetToken = factory.assetTokens(assetID);
        require(assetToken != address(0), "asset token not exists");
        string memory tokenName = IERC20Metadata(assetToken).name();
        string memory tokenSymbol = IERC20Metadata(assetToken).symbol();
        stakeToken = address(new StakeToken(
            string.concat("Staked ", tokenName),
            string.concat("s", tokenSymbol),
            address(assetToken),
            cooldown
        ));
        stakeTokens[assetID] = stakeToken;
        assetIDs.add(assetID);
        emit CreateStakeToken(stakeToken, assetID, cooldown);
    }

    function getStakeTokens() external view returns (uint256[] memory ids, address[] memory tokens) {
        ids = assetIDs.values();
        tokens = new address[](ids.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = stakeTokens[assetIDs.at(i)];
        }
    }
}