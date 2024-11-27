// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;
import './Interface.sol';
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

contract StakeToken is ERC20 {
    using SafeERC20 for IERC20;

    address public token;
    uint48 public cooldown;
    uint48 public constant MAX_COOLDOWN = 30 days;

    struct CooldownInfo {
        uint256 cooldownAmount;
        uint256 cooldownEndTimestamp;
    }

    mapping(address => CooldownInfo) public cooldownInfos;

    event Stake(address staker, uint256 amount);
    event UnStake(address unstaker, uint256 amount);
    event Withdraw(address withdrawer, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        address token_,
        uint48 cooldown_
    ) ERC20(name_, symbol_) {
        require(token_ != address(0), "token address is zero");
        require(cooldown_ < MAX_COOLDOWN, "cooldown exceeds MAX_COOLDOWN");
        token = token_;
        cooldown = cooldown_;
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return ERC20(token).decimals();
    }

    function stake(uint256 amount) external {
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "not enough allowance");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        CooldownInfo storage cooldownInfo = cooldownInfos[msg.sender];
        require(amount <= balanceOf(msg.sender), "not enough to unstake");
        cooldownInfo.cooldownAmount += amount;
        cooldownInfo.cooldownEndTimestamp = block.timestamp + cooldown;
        _burn(msg.sender, amount);
        emit UnStake(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        CooldownInfo storage cooldownInfo = cooldownInfos[msg.sender];
        require(cooldownInfo.cooldownAmount >= amount, "not enough cooldown amount");
        require(cooldownInfo.cooldownEndTimestamp <= block.timestamp, "cooldowning");
        IERC20(token).safeTransfer(msg.sender, amount);
        cooldownInfo.cooldownAmount -= amount;
        emit Withdraw(msg.sender, amount);
    }
}