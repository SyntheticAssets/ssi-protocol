// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import './Interface.sol';
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Swap is AccessControl, ISwap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set orderHashs;
    mapping(bytes32 => SwapRequest) swapRequests;

    bytes32 public constant TAKER_ROLE = keccak256("TAKER_ROLE");
    bytes32 public constant MAKER_ROLE = keccak256("MAKER_ROLE");

    string[] public takerReceivers;
    string[] public takerSenders;

    event AddSwapRequest(address indexed taker, OrderInfo orderInfo);
    event MakerConfirmSwapRequest(address indexed maker, bytes32 orderHash);
    event ConfirmSwapRequest(address indexed taker, bytes32 orderHash);
    event MakerRejectSwapRequest(address indexed maker, bytes32 orderHash);
    event RollbackSwapRequest(address indexed taker, bytes32 orderHash);
    event SetTakerAddresses(string[] receivers, string[] senders);

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function checkOrderInfo(OrderInfo memory orderInfo) public view returns (uint) {
        if (block.timestamp >= orderInfo.order.deadline) {
            return 1;
        }
        bytes32 orderHash = keccak256(abi.encode(orderInfo.order));
        if (orderHash != orderInfo.orderHash) {
            return 2;
        }
        if (!SignatureChecker.isValidSignatureNow(orderInfo.order.maker, orderHash, orderInfo.orderSign)) {
            return 3;
        }
        if (orderHashs.contains(orderHash)) {
            return 4;
        }
        if (orderInfo.order.inAddressList.length != orderInfo.order.inTokenset.length) {
            return 5;
        }
        if (orderInfo.order.outAddressList.length != orderInfo.order.outTokenset.length) {
            return 6;
        }
        if (!hasRole(MAKER_ROLE, orderInfo.order.maker)) {
            return 7;
        }
        return 0;
    }

    function validateOrderInfo(OrderInfo memory orderInfo) internal view {
        require(orderHashs.contains(orderInfo.orderHash), "order hash not exists");
        require(orderInfo.orderHash == keccak256(abi.encode(orderInfo.order)), "order hash invalid");
    }

    function getOrderHashs() external view returns (bytes32[] memory) {
        return orderHashs.values();
    }

    function getOrderHashLength() external view returns (uint256) {
        return orderHashs.length();
    }

    function getOrderHash(uint256 idx) external view returns (bytes32) {
        require(idx < orderHashs.length(), "out of range");
        return orderHashs.at(idx);
    }

    function addSwapRequest(OrderInfo memory orderInfo) external onlyRole(TAKER_ROLE) {
        uint code = checkOrderInfo(orderInfo);
        require(code == 0, "order not valid");
        swapRequests[orderInfo.orderHash].status = SwapRequestStatus.PENDING;
        swapRequests[orderInfo.orderHash].requester = msg.sender;
        orderHashs.add(orderInfo.orderHash);
        emit AddSwapRequest(msg.sender, orderInfo);
    }

    function getSwapRequest(bytes32 orderHash) external view returns (SwapRequest memory) {
        return swapRequests[orderHash];
    }

    function makerRejectSwapRequest(OrderInfo memory orderInfo) external onlyRole(MAKER_ROLE) {
        validateOrderInfo(orderInfo);
        bytes32 orderHash = orderInfo.orderHash;
        require(orderInfo.order.maker == msg.sender, "not order maker");
        require(swapRequests[orderHash].status == SwapRequestStatus.PENDING, "swap request status is not pending");
        swapRequests[orderHash].status = SwapRequestStatus.REJECTED;
        emit MakerRejectSwapRequest(msg.sender, orderHash);
    }

    function makerConfirmSwapRequest(OrderInfo memory orderInfo, bytes32[] memory outTxHashs) external onlyRole(MAKER_ROLE) {
        validateOrderInfo(orderInfo);
        bytes32 orderHash = orderInfo.orderHash;
        SwapRequest memory swapRequest = swapRequests[orderHash];
        require(orderInfo.order.maker == msg.sender, "not order maker");
        require(swapRequest.status == SwapRequestStatus.PENDING, "status error");
        require(orderInfo.order.outTokenset.length == outTxHashs.length, "wrong outTxHashs length");
        swapRequests[orderHash].outTxHashs = outTxHashs;
        swapRequests[orderHash].status = SwapRequestStatus.MAKER_CONFIRMED;
        emit MakerConfirmSwapRequest(msg.sender, orderHash);
    }

    function rollbackSwapRequest(OrderInfo memory orderInfo) external onlyRole(TAKER_ROLE) {
        validateOrderInfo(orderInfo);
        bytes32 orderHash = orderInfo.orderHash;
        require(swapRequests[orderHash].requester == msg.sender, "not order taker");
        require(swapRequests[orderHash].status == SwapRequestStatus.MAKER_CONFIRMED, "swap request status is not maker_confirmed");
        swapRequests[orderHash].status = SwapRequestStatus.PENDING;
        emit RollbackSwapRequest(msg.sender, orderHash);
    }

    function confirmSwapRequest(OrderInfo memory orderInfo, bytes32[] memory inTxHashs) external onlyRole(TAKER_ROLE) {
        validateOrderInfo(orderInfo);
        bytes32 orderHash = orderInfo.orderHash;
        SwapRequest memory swapRequest = swapRequests[orderHash];
        require(swapRequest.requester == msg.sender, "not order taker");
        require(swapRequest.status == SwapRequestStatus.MAKER_CONFIRMED, "status error");
        require(orderInfo.order.inTokenset.length == inTxHashs.length, "wrong inTxHashs length");
        swapRequests[orderHash].inTxHashs = inTxHashs;
        swapRequests[orderHash].status = SwapRequestStatus.CONFIRMED;
        emit ConfirmSwapRequest(msg.sender, orderHash);
    }

    function setTakerAddresses(string[] memory takerReceivers_, string[] memory takerSenders_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete takerReceivers;
        for (uint i = 0; i < takerReceivers_.length; i++) {
            takerReceivers.push(takerReceivers_[i]);
        }
        delete takerSenders;
        for (uint i = 0; i < takerSenders_.length; i++) {
            takerSenders.push(takerSenders_[i]);
        }
        emit SetTakerAddresses(takerReceivers, takerSenders);
    }

    function getTakerAddresses() external view returns (string[] memory receivers, string[] memory senders) {
        return (takerReceivers, takerSenders);
    }
}
