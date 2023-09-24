// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BeeSmart is AccessControl {
    bytes32 public constant AdminRole     = keccak256("BeeSmart.Admin");
    bytes32 public constant CommunityRole = keccak256("BeeSmart.Community");

    enum OrderStatus { WAITING, CONFIRMED, TIMEOUT, RECALLED }
    struct Order {
        address payToken;
        uint256 sellAmount;
        address buyer;
        address seller;
        OrderStatus status;
    }

    mapping(address => bool) public supportedTokens; // supported ERC20.
    mapping(bytes32 => bool) public ongoingOrders;   // hash of orders which is ongoing.
    mapping(bytes32 => bool) public confirmedOrders; // hash of orders which confirmed, both succed or failed.

    mapping(bytes32 => Order) public orders;

    event OrderMade(address indexed seller, address indexed buyer, address payToken, uint256 amount);

    constructor() {
        _grantRole(AdminRole, msg.sender);
    }

    // seller makes a order
    function makeOrder(bytes32 orderHash, address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens[payToken], "token not support");
        require(sellAmount > 0, "pay amount zero");
        require(orders[orderHash].payToken == address(0), "order existed");

        orders[orderHash] = Order(payToken, sellAmount, buyer, msg.sender, OrderStatus.WAITING);

        IERC20(payToken).transferFrom(msg.sender, address(this), sellAmount);

        emit OrderMade(msg.sender, buyer, payToken, sellAmount);
    }

    // buyer want to reduce amount of order
    function reduceOrder(bytes32 orderHash, uint256 amount) external {

    }

    // seller confirmed and want to finish an order.
    function finishOrder(bytes32 orderHash) external {

    }

    // buyer or seller wants to dispute
    function dispute(bytes32 orderHash) external {

    }

    // some disputes happend and community make the recall decision.
    function recallOrder(bytes32 orderHash) external onlyRole(CommunityRole) {

    }

}
