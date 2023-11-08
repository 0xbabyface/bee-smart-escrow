// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./components/IRelationship.sol";
import "./components/IReputation.sol";
import "./components/IRebate.sol";

contract BeeSmartStorage {

    enum OrderStatus { UNKNOWN, WAITING, ADJUSTED, CONFIRMED, CANCELLED, DISPUTING, RECALLED }
    struct Order {
        uint256 orderId;
        address payToken;
        uint256 sellAmount;
        address buyer;
        address seller;
        OrderStatus status;
        uint64  updatedAt;
    }

    struct OrderRewards {
        uint128 buyerRewards;
        uint128 sellerRewards;
        uint128 buyerAirdropPoints;
        uint128 sellerAirdropPoints;
        uint128 buyerReputation;
        uint128 sellerReputation;
    }

    struct DisputeInfo {
        address originator;
    }

    struct AdjustInfo {
        uint256 preAmount;
        uint256 curAmount;
    }

    uint256 public constant RatioPrecision = 1E18;
    uint256 public constant RebateLevels = 10;

    uint256 public totalOrdersCount;

    EnumerableSet.AddressSet supportedTokens; // supported ERC20.
    // token address => decimals
    mapping(address => uint256) supportedTokenDecimals;

    mapping(uint256 => Order) public orders; // total orders, includes pendings and finished orders.
    // orderId => DisputeInfo
    mapping(uint256 => DisputeInfo) public disputedOrder;
    // orderId => AdjustInfo
    mapping(uint256 => AdjustInfo) public adjustedOrder;
    // orderId => OrderRewards
    mapping(uint256 => OrderRewards) public orderRewards;

    mapping(address => uint256[]) public sellOrdersOfUser;
    mapping(address => uint256[]) public buyOrdersOfUser;

    // relationId => rebate (for CANDY)
    mapping(uint256 => uint256) public rebateRewards;
    // relationId => airdrop points
    mapping(uint256 => uint256) public airdropPoints;

    uint8         public initialized;
    uint64        public orderStatusDurationSec = 30 * 60; // 30 minutes

    IRelationship public relationship;
    IReputation   public reputation;
    IRebate       public rebate;

    address       public communityWallet;

    uint256       public communityFeeRatio = 0.03E18;  // fee ratio: 0.3%
    uint256       public chargesBaredBuyerRatio = 1E18;  // 100% buyer fee ratio
    uint256       public chargesBaredSellerRatio = 0;  // 0% seller fee ratio

    uint256       public rewardForBuyerRatio = 0.03E18;  // reward for buyer
    uint256       public rewardForSellerRatio = 0.03E18;  // reward for seller

    uint256       public reputationRatio = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points

    uint256       public rebateRatio = 0.1E18;  // 10% of community fee will rebate to parents

}