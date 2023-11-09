// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./components/IRelationship.sol";
import "./components/IReputation.sol";
import "./components/IRebate.sol";
import "./libs/Order.sol";

contract BeeSmartStorage {

    // enum OrderStatus {
    //     UNKNOWN,       // occupate the default status
    //     NORMAL,        // normal status
    //     ADJUSTED,      // buyer adjuste amount
    //     CONFIRMED,     // seller confirmed
    //     CANCELLED,     // buyer adjust amount to 0
    //     SELLERDISPUTE, // seller dispute
    //     BUYERDISPUTE,  // buyer dispute
    //     LOCKED,        // both buyer and seller disputed
    //     RECALLED       // seller dispute and buyer no response
    // }

    // struct Order {
    //     uint256 orderId;
    //     address payToken;
    //     uint256 sellAmount;
    //     address buyer;
    //     address seller;
    //     OrderStatus status;
    //     uint64  updatedAt;
    // }

    // struct OrderRewards {
    //     uint128 buyerRewards;
    //     uint128 sellerRewards;
    //     uint128 buyerAirdropPoints;
    //     uint128 sellerAirdropPoints;
    //     uint128 buyerReputation;
    //     uint128 sellerReputation;
    // }

    // struct StatusTransform {
    //     OrderStatus currStatus;
    //     OrderStatus prevStatus;
    // }

    // function orderToStatus(StatusTransform storage st, OrderStatus s) internal {
    //     st.prevStatus = st.currStatus;
    //     st.currStatus = s;
    // }

    // struct AdjustInfo {
    //     uint256 preAmount;
    //     uint256 curAmount;
    // }

    modifier onlyExistOrder(uint256 id) {
        require(orders[id].updatedAt != 0, "order not exist");
        _;
    }

    uint256 public constant RatioPrecision = 1E18;
    uint256 public constant RebateLevels = 10;

    uint256 public totalOrdersCount;

    EnumerableSet.AddressSet supportedTokens; // supported ERC20.
    // token address => decimals
    mapping(address => uint256) supportedTokenDecimals;

    mapping(uint256 => Order.Record) public orders; // total orders, includes pendings and finished orders.
    // orderId => DisputeInfo
    // mapping(uint256 => StatusTransform) public statusTransform;
    // orderId => AdjustInfo
    mapping(uint256 => Order.AdjustInfo) public adjustedOrder;
    // orderId => OrderRewards
    mapping(uint256 => Order.Rewards) public orderRewards;

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