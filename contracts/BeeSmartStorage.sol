// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./components/IReputation.sol";
import "./libs/Order.sol";
import "./components/AgentManager.sol";

contract BeeSmartStorage {

    modifier onlyExistOrder(uint256 id) {
        require(orders[id].updatedAt != 0, "order not exist");
        _;
    }

    uint256 public constant RatioPrecision = 1E18;
    uint8   public initialized = 1;
    uint256 public totalOrdersCount;

    EnumerableSet.AddressSet supportedTokens; // supported ERC20.
    // token address => decimals
    mapping(address => uint256) supportedTokenDecimals;

    mapping(uint256 => Order.Record) public orders; // total orders, includes pendings and finished orders.

    // orderId => AdjustInfo
    mapping(uint256 => Order.AdjustInfo) public adjustedOrder;
    // orderId => OrderRewards
    mapping(uint256 => Order.Rewards) public orderRewards;

    mapping(address => uint256[]) public sellOrdersOfUser;
    mapping(address => uint256[]) public buyOrdersOfUser;

    // trader => airdrop points
    mapping(address => uint256) public airdropPoints;

    IReputation   public reputation;
    AgentManager  public agentMgr;

    address       public communityWallet;
    address       public agentsWallet;
    address       public globalShareWallet;

    uint64        public orderStatusDurationSec  = 30 * 60; // 30 minutes waiting for order status
    uint256       public communityFeeRatio       = 0.2E18;  // fee ratio: 20%
    uint256       public agentFeeRatio           = 0.1E18;  // top agent ratio 10%
    uint256       public globalShareFeeRatio     = 0.1E18; // global share fee ratio
    uint256       public sameLevelFeeRatio       = 0.1E18; // same level fee ratio
    uint256       public chargesBaredBuyerRatio  = 0.005E18;  // 0.5% buyer fee ratio
    uint256       public chargesBaredSellerRatio = 0.005E18;  // 0.5% seller fee ratio
    uint256       public reputationRatio         = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points

    EnumerableSet.UintSet lockedOrders;  // all locked orders
    mapping(address => EnumerableSet.UintSet) userLockedOrders;
    // trader address => agent address
    mapping(address => address) public boundAgents;

    // address => payToken => rewards
    mapping(address => mapping(address => uint256)) public pendingRewards;
    // agent id => payToken => trade amount
    mapping(uint96 => mapping(address => uint256)) public agentTradeVolumn;
}
