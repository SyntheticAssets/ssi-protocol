// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

contract ChristmasAirdrop is ERC20, Ownable, ReentrancyGuard {

    uint256 private constant TOTAL_SUPPLY = 1_000_000;

    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    event AirdropClaimed(address indexed claimant, uint256 amount);
    event MerkleRootUpdated(bytes32 indexed newMerkleRoot);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    constructor(bytes32 _merkleRoot) ERC20("IMAGINE Token", "IMAGINE") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY * 10**decimals());
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external nonReentrant {
        require(!hasClaimed[msg.sender], "Airdrop already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        // 验证 Merkle 证明
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Proof");
        hasClaimed[msg.sender] = true;
        _transfer(address(this), msg.sender, amount);
        emit AirdropClaimed(msg.sender, amount);
    }

    function batchAirdrop(address[] calldata recipients, uint256[] calldata amounts, bytes32[][] calldata proofs) external onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        require(recipients.length == proofs.length, "Recipients and proofs length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            if (!hasClaimed[recipients[i]]) {
                bytes32 leaf = keccak256(abi.encodePacked(recipients[i], amounts[i]));
                if (MerkleProof.verify(proofs[i], merkleRoot, leaf)) {
                    hasClaimed[recipients[i]] = true;
                    _transfer(address(this), recipients[i], amounts[i]);
                    emit AirdropClaimed(recipients[i], amounts[i]);
                }
            }
        }
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)), "Insufficient balance");
        _transfer(address(this), msg.sender, amount);
        emit TokensWithdrawn(msg.sender, amount);
    }
    
}