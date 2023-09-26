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

    constructor() {
        _grantRole(AdminRole, msg.sender);
    }

    // seller makes a order
    function makeOrder(bytes32 orderHash, address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens[payToken], "token not support");
        require(sellAmount > 0, "pay amount zero");
        require(orders[orderHash].payToken == address(0), "order existed");

        orders[orderHash] = Order(payToken, sellAmount, buyer, msg.sender, OrderStatus.WAITING, address(0));

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

        uint256 buyerGotAmount = order.sellAmount;
        // TODO nexts
        // S1: calculate fees for community.

        // S2: calculate reputation points for both seller & buyer.

        IERC20(order.payToken).transfer(order.buyer, buyerGotAmount);

        emit OrderConfirmed(orderHash, buyerGotAmount, order.sellAmount - buyerGotAmount);
    }

    // buyer or seller wants to dispute
    function dispute(bytes32 orderHash) external {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.WAITING, "order status mismatch");
        require(order.buyer == msg.sender || order.seller == msg.sender, "only buyer or seller allowed");

        order.status = OrderStatus.DISPUTING;
        order.disputeOriginator = msg.sender;

        emit OrderDisputed(orderHash, msg.sender);
    }

    // buyer or seller or community role can recall a dispution.
    function recallDispute(bytes32 orderHash) external {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");
        require(order.disputeOriginator == msg.sender || hasRole(CommunityRole, msg.sender), "not allowd");

        order.status = OrderStatus.WAITING;

        emit OrderDisputeRecalled(orderHash, msg.sender);
    }

    // some disputes happend and community make the recall decision.
    function recallOrder(bytes32 orderHash) external onlyRole(CommunityRole) {
        Order storage order = orders[orderHash];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");

        order.status = OrderStatus.RECALLED;

        // TODO: minus the reputation points from order.disputeOriginator

        IERC20(order.payToken).transfer(order.seller, order.sellAmount);

        emit OrderRecalled(orderHash, msg.sender);
    }
}
