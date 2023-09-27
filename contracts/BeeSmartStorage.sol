// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./components/IRelationship.sol";
import "./components/IReputation.sol";
import "./components/IRebate.sol";

contract BeeSmartStorage {

    enum OrderStatus { UNKNOWN, WAITING, CONFIRMED, CANCELLED, TIMEOUT, DISPUTING, RECALLED }
    struct Order {
        address payToken;
        uint256 sellAmount;
        address buyer;
        address seller;
        OrderStatus status;
        address disputeOriginator;
    }

    mapping(address => bool) public supportedTokens; // supported ERC20.

    mapping(bytes32 => Order) public orders; // total orders, includes pendings and finished orders.

    // relationId => erc20 => rebate
    mapping(uint256 => mapping (address => uint256)) public rebates;

    IRelationship public relathionship;
    IReputation   public reputation;
    IRebate       public rebate;

    address       public communityWallet;
    uint256       public communityFeeRatio = 0.003E18;  // fee ratio: 0.3%

    uint256       public reputationRatio = 0.0005E18; // reputation points ratio:  tradeAmount * reputationRatio = Points
}