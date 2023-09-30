// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
    uint256 public constant RebateLevels = 10;

    mapping(address => bool) public supportedTokens; // supported ERC20.

    mapping(bytes32 => Order) public orders; // total orders, includes pendings and finished orders.
    mapping(address => bytes32[]) public ordersOfUser;

    // relationId => erc20 => rebate
    mapping(uint256 => mapping (address => uint256)) public rebateRewards;

    uint64        public orderStatusDurationSec = 30 * 60; // 30 minutes

    IRelationship public relathionship;
    IReputation   public reputation;
    IRebate       public rebate;

    address       public communityWallet;

    uint256       public communityFeeRatio = 0.03E18;  // fee ratio: 0.3%
    uint256       public chargesBaredBuyerRatio = 0.03E18;  // 3% buyer fee ratio
    uint256       public chargesBaredSellerRatio = 0.03E18;  // 3% buyer fee ratio
    uint256       public rewardForBuyerRatio = 0.03E18;  // reward for buyer
    uint256       public rewardForSellerRatio = 0.03E18;  // reward for seller

    uint256       public reputationRatio = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points

    uint256       public rebateRatio = 0.1E18;  // 10% of community fee will rebate to parents
}