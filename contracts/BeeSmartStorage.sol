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
        uint64  statusTimestamp;
        address disputeOriginator;
    }

    uint256 public constant RatioPrecision = 1E18;

    mapping(address => bool) public supportedTokens; // supported ERC20.

    mapping(bytes32 => Order) public orders; // total orders, includes pendings and finished orders.

    // relationId => erc20 => rebate
    mapping(uint256 => mapping (address => uint256)) public rebateRewards;

    IRelationship public relathionship;
    IReputation   public reputation;
    IRebate       public rebate;

    address       public communityWallet;
    uint256       public communityFeeRatio = 0.003E18;  // fee ratio: 0.3%

    uint256       public reputationRatio = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points
    uint256       public rebateRatio = 0.1E18;  // 10% of community fee will rebate to parents
    uint64        public statusDurationSec = 30 * 60; // 30 minutes
}