// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BeeSmartStorage.sol";

contract BeeSmart is AccessControl, BeeSmartStorage {
    bytes32 public constant AdminRole     = keccak256("BeeSmart.Admin");
    bytes32 public constant CommunityRole = keccak256("BeeSmart.Community");

    event OrderMade(bytes32 indexed orderHash, address indexed seller, address indexed buyer, address payToken, uint256 amount);
    event OrderCancelled(bytes32 indexed orderHash, address indexed seller, address indexed buyer);
    event OrderReduced(bytes32 indexed orderHash, address indexed seller, address indexed buyer, uint256 reduceAmount);
    event OrderDisputed(bytes32 indexed orderHash, address indexed firedBy);
    event OrderDisputeRecalled(bytes32 indexed orderHash, address indexed recalledBy);
    event OrderRecalled(bytes32 indexed orderHash, address indexed recalledBy);
    event OrderConfirmed(bytes32 indexed orderHash, uint256 buyerGotAmount, uint256 feeAmount);

    event CommunityWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event CommunityFeeRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event RoleSet(address indexed admin, bytes32 role, address account, bool toGrant);
    event ReputationRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event RebateRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);

    constructor() {
        _grantRole(AdminRole, msg.sender);
    }
    // set community wallet
    function setCommunityWallet(address w) external onlyRole(AdminRole) {
        require(w != address(0), "wallet is null");
        require(w != communityWallet, "same wallet");

        address oldWallet = communityWallet;
        communityWallet = w;
        emit CommunityWalletSet(msg.sender, oldWallet, w);
    }
    // set community fee ratio
    function setCommunityFeeRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r < 1E18, "fee ratio invalid");
        uint256 oldRatio = communityFeeRatio;
        communityFeeRatio = r;
        emit CommunityFeeRatioSet(msg.sender, oldRatio, r);
    }
    // set role
    function setRole(bytes32 role, address account, bool toGrant) external onlyRole(AdminRole) {
        require(role == AdminRole || role == CommunityRole, "unknown role");
        require(account != address(0), "grant to null address");

        if (toGrant) _grantRole(role, account);
        else _revokeRole(role, account);

        emit RoleSet(msg.sender, role, account, toGrant);
    }

    // set reputation ratio
    function setReputationRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r < 1E18, "fee ratio invalid");
        uint256 oldRatio = reputationRatio;
        reputationRatio = r;
        emit CommunityFeeRatioSet(msg.sender, oldRatio, r);
    }
    // set rebate fee ratio
    function setRebateRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r < 1E18, "fee ratio invalid");
        uint256 oldRatio = rebateRatio;
        rebateRatio = r;
        emit RebateRatioSet(msg.sender, oldRatio, r);
    }

    // seller makes a order
    function makeOrder(bytes32 orderHash, address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens[payToken], "token not support");
        require(sellAmount > 0, "pay amount zero");
        require(orders[orderHash].payToken == address(0), "order existed");

        orders[orderHash] = Order(payToken, sellAmount, buyer, msg.sender, OrderStatus.WAITING, uint64(block.timestamp), address(0));

        IERC20(payToken).transferFrom(msg.sender, address(this), sellAmount);

        emit OrderMade(orderHash, msg.sender, buyer, payToken, sellAmount);
    }

    // buyer want to reduce amount of order
    function reduceOrder(bytes32 orderHash, uint256 amount) external {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.WAITING, "order status mismatch");
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.sellAmount >= amount, "amount overflow");

        if (order.sellAmount == amount) {
            order.status = OrderStatus.CANCELLED;
            emit OrderCancelled(orderHash, order.seller, order.buyer);
        } else {
            order.sellAmount -= amount;
            emit OrderReduced(orderHash, order.seller, order.buyer, amount);
        }

        IERC20(order.payToken).transfer(order.seller, amount);
    }

    // seller confirmed and want to finish an order.
    function confirmOrder(bytes32 orderHash) external {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.WAITING, "order status mismatch");
        require(order.seller == msg.sender, "only seller allowed");

        order.status = OrderStatus.CONFIRMED;

        // S1: calculate fees for community & upper parents.
        uint256 communityFee = order.sellAmount * communityFeeRatio / RatioPrecision;
        uint256 buyerGotAmount = order.sellAmount - communityFee;

        uint256[] memory parentIds = relathionship.getParentRelationId(order.buyer);
        if (parentIds.length > 0) {
            uint256 rebateAmount = communityFee * rebateRatio / RatioPrecision;  // 10% for rebates;
            uint256[] memory parentRebates = rebate.calculateRebate(rebateAmount, parentIds);
            for (uint256 i = 0; i < parentIds.length; ++i) {
                if (parentIds[i] == 0) break;
                rebateRewards[parentIds[i]][order.payToken] += parentRebates[i];
            }

            communityFee -= rebateAmount;
        }

        // S2: calculate reputation points for both seller & buyer.
        uint256 points = order.sellAmount * reputationRatio / RatioPrecision;
        reputation.grant(relathionship.getRelationId(order.seller), points);
        reputation.grant(relathionship.getRelationId(order.buyer), points);

        // S3: transfer token to buyer & community
        IERC20(order.payToken).transfer(order.buyer, buyerGotAmount);
        IERC20(order.payToken).transfer(communityWallet, communityFee);

        emit OrderConfirmed(orderHash, buyerGotAmount, order.sellAmount - buyerGotAmount);
    }

    // buyer or seller wants to dispute
    function dispute(bytes32 orderHash) external {
        Order storage order = orders[orderHash];
        require(order.statusTimestamp + statusDurationSec <= block.timestamp, "in waiting time");
        require(order.status == OrderStatus.WAITING, "order status mismatch");
        require(order.buyer == msg.sender || order.seller == msg.sender, "only buyer or seller allowed");

        order.status = OrderStatus.DISPUTING;
        order.statusTimestamp = uint64(block.timestamp);
        order.disputeOriginator = msg.sender;

        emit OrderDisputed(orderHash, msg.sender);
    }

    // buyer or seller or community role can recall a dispution.
    function recallDispute(bytes32 orderHash) external {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");
        require(order.disputeOriginator == msg.sender || hasRole(CommunityRole, msg.sender), "not allowd");

        order.status = OrderStatus.WAITING;
        order.statusTimestamp = uint64(block.timestamp);

        emit OrderDisputeRecalled(orderHash, msg.sender);
    }

    // some disputes happend and community make the recall decision.
    function recallOrder(bytes32 orderHash, address winner) external onlyRole(CommunityRole) {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");

        order.status = OrderStatus.RECALLED;

        // minus the reputation points from order.disputeOriginator
        uint256 points = order.sellAmount * reputationRatio / RatioPrecision;
        if (winner == order.seller) {
            reputation.takeback(relathionship.getRelationId(order.buyer), points);
        } else if (winner == order.buyer) {
            reputation.takeback(relathionship.getRelationId(order.seller), points);
        }

        IERC20(order.payToken).transfer(order.seller, order.sellAmount);

        emit OrderRecalled(orderHash, msg.sender);
    }
}
