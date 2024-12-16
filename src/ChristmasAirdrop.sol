// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "forge-std/console.sol";

contract ChristmasAirdrop is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 public merkleRoot;
    mapping(address => mapping(address => uint256)) public hasClaimed;
    uint256 public expirationTime;

    event AirdropClaimed(
        address indexed claimant,
        address indexed token,
        uint256 amount
    );
    event MerkleRootUpdated(bytes32 indexed newMerkleRoot);
    event TokensWithdrawn(address to, address indexed token, uint256 amount);
    event ExpirationTimeUpdated(uint256 newExpirationTime);

    constructor(
        bytes32 _merkleRoot,
        uint256 _expirationTime
    ) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        expirationTime = _expirationTime;
    }

    function setExpirationTime(uint256 _newExpirationTime) external onlyOwner {
        expirationTime = _newExpirationTime;
        emit ExpirationTimeUpdated(_newExpirationTime);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    function _claim(
        address recipient,
        address token,
        uint256 amount,
        bytes32[] calldata proof
    ) internal {
        require(block.timestamp <= expirationTime, "Airdrop has expired");
        uint256 claimed = hasClaimed[recipient][token];
        uint256 claimableAmount = amount - claimed;
        require(claimableAmount > 0, "No remaining tokens to claim");
        bytes32 leaf = keccak256(abi.encodePacked(recipient, token, amount));
        // Verify Merkle Proof
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );
        hasClaimed[recipient][token] = amount;
        require(
            IERC20(token).transfer(recipient, amount),
            "Token transfer failed"
        );
        emit AirdropClaimed(recipient, token, amount);
    }

    function claim(
        address token,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        _claim(msg.sender, token, amount, proof);
    }

    function batchClaim(
        address[] calldata recipients,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external onlyOwner nonReentrant {
        require(
            recipients.length == tokens.length &&
                recipients.length == amounts.length &&
                recipients.length == proofs.length,
            "Input arrays length mismatch"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            address token = tokens[i];
            uint256 amount = amounts[i];
            bytes32[] calldata proof = proofs[i];
            if (block.timestamp > expirationTime) {
                break;
            }
            uint256 claimed = hasClaimed[recipient][token];
            uint256 claimableAmount = amount - claimed;
            if (claimableAmount > 0) {
                _claim(recipient, token, amount, proof);
            }
        }
    }

    function withdrawTokens(
        address to,
        address token,
        uint256 amount
    ) external onlyOwner nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "Insufficient token balance");
        IERC20(token).safeTransfer(to, amount);
        emit TokensWithdrawn(to, token, amount);
    }
}
