// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BeeSmartStorage.sol";

contract BeeSmart is AccessControl, BeeSmartStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Order for Order.Record;

    bytes32 public constant AdminRole     = keccak256("BeeSmart.Admin");
    bytes32 public constant CommunityRole = keccak256("BeeSmart.Community");

    event OrderMade(uint256 indexed orderId, address indexed seller, address indexed buyer, address payToken, uint256 amount);
    event OrderCancelled(uint256 indexed orderId, address indexed seller, address indexed buyer);
    event OrderAdjusted(uint256 indexed orderId, address indexed seller, address indexed buyer, uint256 preAmount, uint256 nowAmount);
    event OrderDisputed(uint256 indexed orderId, address indexed firedBy, Order.Status s);
    event OrderDisputeRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderConfirmed(uint256 indexed orderId, uint256 buyerGotAmount, uint256 feeAmount);
    event CommunityDecided(uint256 indexed orderId, address indexed judger, uint8 decision);

    event CommunityWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event OperatorWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event GlobalShareWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);

    event ShareFeeRatioSet(address indexed admin, uint256 communityRatio, uint256 agentRatio, uint256 globalRatio, uint256 sameLevelRatio);
    event RoleSet(address indexed admin, bytes32 role, address account, bool toGrant);
    event ReputationRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event DisputeWinnerFeeRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event TraderFeeRatioSet(address indexed admin, uint256 oldSellerFeeRatio, uint256 newSellerFeeRatio, uint256 oldBuyerFeeRatio, uint256 newBuyerFeeRatio);

    event ReputationSet(address indexed reputation);
    event AgentManagerSet(address indexed agtManager);
    event RewardClaimed(address indexed owner, address payToken, uint256 amount);

    function initialize(
        address[] memory admins,
        address[] memory communities,
        address[] memory payTokens,
        address _communityWallet,
        address _globalWallet
    )
        external
    {
        require(initialized == 0, "already initialized");
        initialized = 1;

        for (uint i = 0; i < admins.length; ++i) {
            _grantRole(AdminRole, admins[i]);
        }

        for (uint i = 0; i < communities.length; ++i) {
            _grantRole(CommunityRole, communities[i]);
        }

        for (uint i = 0; i < payTokens.length; ++i) {
            supportedTokens.add(payTokens[i]);
            supportedTokenDecimals[payTokens[i]] = IERC20Metadata(payTokens[i]).decimals();
        }

        orderStatusDurationSec  = 30 * 60;   // 30 minutes waiting for order status
        disputeStatusDurationSec  = 120 * 60;   // 120 minutes waiting for order status
        communityFeeRatio       = 0.2E18;    // fee ratio: 20%
        operatorFeeRatio        = 0.1E18;    // top agent ratio 10%
        globalShareFeeRatio     = 0.1E18;    // global share fee ratio
        sameLevelFeeRatio       = 0.1E18;    // same level fee ratio
        chargesBaredBuyerRatio  = 0.005E18;  // 0.5% buyer fee ratio
        chargesBaredSellerRatio = 0.005E18;  // 0.5% seller fee ratio
        reputationRatio         = 1E18;
        disputeWinnerFeeRatio   = 0.03E18;

        communityWallet     = _communityWallet;
        globalShareWallet   = _globalWallet;
    }

    // set community wallet
    function setCommunityWallet(address w) external onlyRole(AdminRole) {
        require(w != address(0), "wallet is null");
        require(w != communityWallet, "same wallet");

        address oldWallet = communityWallet;
        communityWallet = w;
        emit CommunityWalletSet(msg.sender, oldWallet, w);
    }

    function setOperatorWallet(uint96 agentId, address w) external onlyRole(AdminRole) {
        uint96 key = agentId / 1e4;
        require(w != address(0), "wallet is null");
        require(w != operatorWallets[key], "same wallet");

        address oldWallet = operatorWallets[key];
        operatorWallets[key] = w;
        operatorWallets2Id[w] = key;
        emit OperatorWalletSet(msg.sender, oldWallet, w);
    }

    function setGlobalShareWallet(address w) external onlyRole(AdminRole) {
        require(w != address(0), "wallet is null");
        require(w != globalShareWallet, "same wallet");

        address oldWallet = globalShareWallet;
        globalShareWallet = w;
        emit GlobalShareWalletSet(msg.sender, oldWallet, w);
    }

    // set community fee ratio
    function setShareFeeRatio(uint256 communityRatio, uint256 operatorRatio, uint256 globalRatio, uint256 sameLevelRatio) external onlyRole(AdminRole) {
        require(
            communityRatio + operatorRatio + globalRatio + sameLevelRatio == 0.5E18,
            "share ratio is not 50%"
        );

        communityFeeRatio = communityRatio;
        operatorFeeRatio = operatorRatio;
        globalShareFeeRatio = globalRatio;
        sameLevelFeeRatio = sameLevelRatio;

        emit ShareFeeRatioSet(msg.sender, communityRatio, operatorRatio, globalRatio, sameLevelRatio);
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
        require(0 <= r && r <= 1E18, "fee ratio invalid");
        uint256 oldRatio = reputationRatio;
        reputationRatio = r;
        emit ReputationRatioSet(msg.sender, oldRatio, r);
    }
    // set dispute winner fee ratio
    function setDisputeWinnerFeeRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r <= 1E18, "fee ratio invalid");
        uint256 oldRatio = disputeWinnerFeeRatio;
        disputeWinnerFeeRatio = r;
        emit DisputeWinnerFeeRatioSet(msg.sender, oldRatio, r);
    }

    // set charge traders fee
    function setTraderFeeRatio(uint sellerFeeRatio, uint256 buyerFeeRatio) external onlyRole(AdminRole) {
        require(0 <= sellerFeeRatio && sellerFeeRatio <= 1E18, "seller fee ratio invalid");
        require(0 <= buyerFeeRatio && buyerFeeRatio <= 1E18, "buyer fee ratio invalid");

        uint256 oldSellerFee = chargesBaredSellerRatio;
        uint256 oldBuyerFee = chargesBaredBuyerRatio;

        chargesBaredSellerRatio = sellerFeeRatio;
        chargesBaredBuyerRatio = buyerFeeRatio;

        emit TraderFeeRatioSet(msg.sender, oldSellerFee, sellerFeeRatio, oldBuyerFee, buyerFeeRatio);
    }

    // add tradable tokens
    function addSupportTokens(address[] memory tokens) external onlyRole(AdminRole) {
        for (uint i = 0; i < tokens.length; ++i) {
            if (supportedTokens.contains(tokens[i])) continue;
            else {
                supportedTokens.add(tokens[i]);
                supportedTokenDecimals[tokens[i]] = IERC20Metadata(tokens[i]).decimals();
            }
        }
    }

    // remove tradable tokens
    function removeSupportTokens(address[] memory tokens) external onlyRole(AdminRole) {
        for (uint i = 0; i < tokens.length; ++i) {
            if (supportedTokens.contains(tokens[i])) supportedTokens.remove(tokens[i]);
        }
    }

    function setReputation(IReputation rep) external onlyRole(AdminRole) {
        require(address(rep).code.length > 0, "invalid reputaion contract");
        reputation = rep;
        emit ReputationSet(address(rep));
    }

    function setAgentManager(address agtManager) external onlyRole(AdminRole) {
        require(agtManager.code.length > 0, "invalid agentmanager contract");

        agentMgr = AgentManager(agtManager);

        emit AgentManagerSet(agtManager);
    }

    function setOrderStatusDurationSec(uint64 sec) external onlyRole(AdminRole) {
        orderStatusDurationSec = sec;
    }

    function setDisputeStatusDurationSec(uint64 sec) external onlyRole(AdminRole) {
        disputeStatusDurationSec = sec;
    }

    function alignAmount18(address payToken, uint256 sellAmount) internal view returns(uint256) {
        return sellAmount * 10**(18 - supportedTokenDecimals[payToken]);
    }

    // bind relationship
    function bindRelationship(uint96 agentId) external {
        require(boundAgents[msg.sender] == 0, "already bound");
        require(agentMgr.isAgentId(agentId), "agent id invalid");

        uint96 userId = reputation.onRelationBound(msg.sender);

        boundAgents[msg.sender] = (uint192(userId) << 96) + uint192(agentId);
    }

    // once add a new agent, change its bound info to itself
    function onNewAgent(address agent, uint96 agentId) external {
        require(msg.sender == address(agentMgr), "only agent manager");
        uint96 userId;
        if (boundAgents[agent] == 0) {
            userId = reputation.onRelationBound(agent);
        } else {
            userId = uint96(boundAgents[agent] >> 96);
        }
        boundAgents[agent] = (uint192(userId) << 96) + uint192(agentId);
    }

    function onNewTopAgent(uint96 agentId, address operatorWallet) external {
        require(msg.sender == address(agentMgr), "only agent manager");
        require(
            operatorWallets2Id[operatorWallet] == 0,
            "operaotr wallet have been used"
        );
        uint96 operatorId = agentId / 1e4;

        operatorWallets[operatorId] = operatorWallet;
        operatorWallets2Id[operatorWallet] = operatorId;
    }

    // agents and community and any one claim reward
    function claimPendingRewards(address payToken) external {
        require(pendingRewards[msg.sender][payToken] > 0, "no pending rewards");

        uint256 rewards = pendingRewards[msg.sender][payToken];
        pendingRewards[msg.sender][payToken] = 0;

        SafeERC20.safeTransfer(IERC20Metadata(payToken), msg.sender, rewards);

        emit RewardClaimed(msg.sender, payToken, rewards);
    }

    // seller makes a order
    function makeOrder(address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens.contains(payToken), "token not support");
        require(sellAmount > 0, "sell amount is zero");
        require(userLockedOrders[msg.sender].length() == 0, "seller has locked order");
        require(userLockedOrders[buyer].length() == 0, "buyer has locked order");
        require(boundAgents[buyer] != 0, "buyer not registered");
        require(boundAgents[msg.sender] != 0, "seller not registered");

        require(msg.sender != buyer, "can not sell to self");

        uint256 alignedAmount = alignAmount18(payToken, sellAmount);
        require(reputation.isReputationEnough(buyer, alignedAmount), "not enough reputation for buyer");
        require(reputation.isReputationEnough(msg.sender, alignedAmount), "not enough reputation for seller");

        ++totalOrdersCount;

        uint256 sellerFee = sellAmount * chargesBaredSellerRatio / RatioPrecision;
        SafeERC20.safeTransferFrom(IERC20Metadata(payToken), msg.sender, address(this), sellAmount + sellerFee);

        uint256 orderId = totalOrdersCount;
        orders[orderId] = Order.Record(
                                orderId,
                                sellAmount,
                                payToken,
                                uint64(block.timestamp),
                                buyer,
                                msg.sender,
                                Order.Status.NORMAL,
                                Order.Status.UNKNOWN,
                                sellerFee,
                                0,
                                uint64(block.timestamp)
        );
        sellOrdersOfUser[msg.sender].push(orderId);
        buyOrdersOfUser[buyer].push(orderId);

        emit OrderMade(orderId, msg.sender, buyer, payToken, sellAmount);
    }

    // buyer want to adjust amount of order
    function adjustOrder(uint256 orderId, uint256 targetAmount) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];

        require(order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED, "order status mismatch");
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.sellAmount > targetAmount, "amount should less than now");

        uint256 rebateFee = (order.sellAmount - targetAmount) * order.sellerFee / order.sellAmount; // rebate sell fee by ratio
        if (rebateFee > 0) order.sellerFee -= rebateFee;

        if (targetAmount == 0) {
            order.toStatus(Order.Status.CANCELLED);
            emit OrderCancelled(orderId, order.seller, order.buyer);
        } else {
            order.toStatus(Order.Status.ADJUSTED);

            uint256 preAmount = order.sellAmount;
            order.sellAmount = targetAmount;
            adjustedOrder[orderId] = Order.AdjustInfo(preAmount, targetAmount);

            emit OrderAdjusted(orderId, order.seller, order.buyer, preAmount, order.sellAmount);
        }

        SafeERC20.safeTransfer(IERC20Metadata(order.payToken), order.seller, order.sellAmount + rebateFee - targetAmount);
    }

    // seller confirmed and want to finish an order.
    function confirmOrder(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];

        require(order.seller == msg.sender, "only seller allowed");
        require(order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED, "order status mismatch");

        order.toStatus(Order.Status.CONFIRMED);

        uint256 buyerGotAmount  = releaseToBuyer(order, false);

        // S1: rewards for agents, buyer, seller
        dispatchFees(order.orderId, order.buyerFee, order.payToken, order.buyer);
        dispatchFees(order.orderId, order.sellerFee, order.payToken, order.seller);
        dispatchReputationAndAirdrop(order, true);

        emit OrderConfirmed(orderId, buyerGotAmount, order.buyerFee + order.sellerFee);
    }

    // seller wants to dispute
    function sellerDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.seller == msg.sender, "only seller allowed");

        if (order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // order is in normal status, and seller raise a dispute
            order.toStatus(Order.Status.SELLERDISPUTE);
        } else if (order.currStatus == Order.Status.SELLERDISPUTE) {
            require(order.updatedAt + disputeStatusDurationSec <= block.timestamp, "status in waiting time");
            // two dispute by seller, send token back to seller
            // this order is handled like being cancelled
            // no reputation nor CANDY reward is granted
            order.toStatus(Order.Status.CONFIRMED);
            releaseToSeller(order, false);
        } else if (order.currStatus == Order.Status.BUYERDISPUTE) {
            // both seller and buyer dispute
            // the order is locked, and should waiting for community's decision
            order.toStatus(Order.Status.LOCKED);
            lockedOrders.add(order.orderId);
            userLockedOrders[order.buyer].add(orderId);
            userLockedOrders[order.seller].add(orderId);
        } else {
            require(false, "seller can not dispute now");
        }

        emit OrderDisputed(orderId, msg.sender, order.currStatus);
    }

    // seller recall dispute
    function sellerRecallDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.seller == msg.sender, "only seller allowed");
        require(order.currStatus == Order.Status.SELLERDISPUTE, "can not recall");

        order.toStatus(Order.Status.NORMAL);

        emit OrderDisputeRecalled(orderId, msg.sender);
    }

    // buyer wants to dispute
    function buyerDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.buyer == msg.sender, "only buyer allowed");

        if (order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // order is in normal status, and buyer raise a dispute
            order.toStatus(Order.Status.BUYERDISPUTE);
        } else if (order.currStatus == Order.Status.BUYERDISPUTE) {
            require(order.updatedAt + disputeStatusDurationSec <= block.timestamp, "status in waiting time");
            // two dispute by buyer, send token to buyer
            // charge community fee from this order,
            // but no reputation nor CANDY granted
            order.toStatus(Order.Status.CONFIRMED);

            releaseToBuyer(order, false);
            dispatchFees(order.orderId, order.buyerFee, order.payToken, order.buyer);
            dispatchReputationAndAirdrop(order, false);
        } else if (order.currStatus == Order.Status.SELLERDISPUTE) {
            // both seller and buyer dispute
            // the order is locked, and should waiting for community's decision
            order.toStatus(Order.Status.LOCKED);
            lockedOrders.add(order.orderId);
            userLockedOrders[order.buyer].add(orderId);
            userLockedOrders[order.seller].add(orderId);
        } else {
            require(false, "buyer can not dispute now");
        }

        emit OrderDisputed(orderId, msg.sender, order.currStatus);
    }

    // buyer recall dispute
    function buyerRecallDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.currStatus == Order.Status.BUYERDISPUTE, "can not recall");

        order.toStatus(Order.Status.NORMAL);

       emit OrderDisputeRecalled(orderId, msg.sender);
    }

    // community decide a locked order.
    // decision should be:
    //    0: buyer win
    //    1: seller win
    //    2: no winner, set order to NORMAL status
    function communityDecide(uint256 orderId, uint8 decision)
        external
        onlyRole(CommunityRole)
        onlyExistOrder(orderId)
    {
        Order.Record storage order = orders[orderId];
        require(order.currStatus == Order.Status.LOCKED, "not locked order");
        decision = decision % 3;

        if (decision == 0 /* Buyer Win */) {
            order.toStatus(Order.Status.BUYERWIN);
            releaseToBuyer(order, true);
            dispatchFees(order.orderId, order.sellerFee, order.payToken, order.seller);
            dispatchFees(order.orderId, order.buyerFee, order.payToken, order.buyer);
            clearReputation(order.seller);
        } else if (decision == 1 /* Seller Win*/) {
            order.toStatus(Order.Status.SELLERWIN);
            releaseToSeller(order, true);
            clearReputation(order.buyer);
        } else { /* set order to NORMAL */
            order.toStatus(Order.Status.NORMAL);
        }

        lockedOrders.remove(orderId);
        userLockedOrders[order.buyer].remove(orderId);
        userLockedOrders[order.seller].remove(orderId);

        emit CommunityDecided(orderId, msg.sender, decision);
    }

    //
    function getLengthOfSellOrders(address wallet) public view returns(uint256) {
        return sellOrdersOfUser[wallet].length;
    }

    function getLengthOfBuyOrders(address wallet) public view returns(uint256) {
        return buyOrdersOfUser[wallet].length;
    }

    function getSupportTokens() public view returns(address[] memory) {
        return supportedTokens.values();
    }

    function getAllLockedOrderIds() public view returns(uint256[] memory) {
        return lockedOrders.values();
    }

    function getUserLockedOrderIds(address user) public view returns(uint256[] memory) {
        return userLockedOrders[user].values();
    }

    function getAgentRebateLength(uint96 agentId) public view returns(uint256) {
        return agentRebates[agentId].length;
    }

    function getAgentRebate(uint96 agentId, uint256 index) public view returns(Order.Rebates memory) {
        return agentRebates[agentId][index];
    }

    function getOperatorWallet(address wallet) public view returns(address) {
        uint96 operatorId = uint96(boundAgents[wallet]) / 1e4;
        return operatorWallets[operatorId];
    }

// --------------------- internal functions -------------------------------
    function releaseToBuyer(Order.Record storage order, bool chargeDisputeWinnerFee) internal returns(uint256) {
        uint256 buyerFee     = order.sellAmount * chargesBaredBuyerRatio / RatioPrecision;
        uint256 buyerGotAmount = order.sellAmount - buyerFee;

        if (chargeDisputeWinnerFee) {
            uint256 disputeWinnerFee = order.sellAmount * disputeWinnerFeeRatio / RatioPrecision;
            buyerGotAmount -= disputeWinnerFee;

            pendingRewards[communityWallet][order.payToken] += disputeWinnerFee;
        }

        order.buyerFee = buyerFee;

        uint96 agentId = uint96(boundAgents[order.buyer] & (0xffff_ffff_ffff_ffff_ffff_ffff));
        agentTradeVolumn[agentId][order.payToken] += order.sellAmount;

        SafeERC20.safeTransfer(IERC20Metadata(order.payToken), order.buyer, buyerGotAmount);
        return buyerGotAmount;
    }

    function releaseToSeller(Order.Record storage order, bool chargeDisputeWinnerFee) internal {
        uint256 sellerGotAmount = order.sellAmount + order.sellerFee;
        if (chargeDisputeWinnerFee) {
            uint256 disputeWinnerFee = order.sellAmount * disputeWinnerFeeRatio / RatioPrecision;
            sellerGotAmount -= disputeWinnerFee;

            pendingRewards[communityWallet][order.payToken] += disputeWinnerFee;
        }

        SafeERC20.safeTransfer(IERC20Metadata(order.payToken), order.seller, sellerGotAmount);
        order.sellerFee = 0;
    }

    function clearReputation(address dealer) internal {
        uint256 points = reputation.reputationPoints(dealer);
        reputation.takeback(dealer, points);
    }

    struct FeeParams {
        uint256 communityFee;
        uint256 operatorFee;
        uint256 globalFee ;
        uint256 sameLevelFee;
    }
    function dispatchFees(uint256 orderId, uint256 totalFee, address payToken, address trader)
        internal
    {
        if (totalFee == 0) return;
        // dispatch fee to agents and community
        address operatorWallet = getOperatorWallet(trader);

        FeeParams memory p = FeeParams(0,0,0,0);
        p.communityFee = totalFee * communityFeeRatio / RatioPrecision;
        p.operatorFee  = totalFee * operatorFeeRatio / RatioPrecision;
        p.globalFee    = totalFee * globalShareFeeRatio / RatioPrecision;
        p.sameLevelFee = totalFee * sameLevelFeeRatio / RatioPrecision;

        pendingRewards[communityWallet][payToken]   += p.communityFee;
        pendingRewards[operatorWallet][payToken]    += p.operatorFee;
        pendingRewards[globalShareWallet][payToken] += p.globalFee;

        // uint96 agentId = uint96(boundAgents[trader] & (0xffff_ffff_ffff_ffff_ffff_ffff));
        RewardAgent[] memory upperAgents = agentMgr.getUpperAgents(
           // agentMgr.agentId2Wallet(agentId)
           agentMgr.agentId2Wallet(uint96(boundAgents[trader] & (0xffff_ffff_ffff_ffff_ffff_ffff)))
        );
        uint len = upperAgents.length;
        uint agentTotalFee = totalFee / 2; // 50% fee share to agents
        uint leftFee = agentTotalFee;
        for (uint i = 0; i < len; ++i) {
            RewardAgent memory agt = upperAgents[i];
            if (agt.feeRatio != 0) {
                uint256 r = agentTotalFee * agt.feeRatio / RatioPrecision;
                pendingRewards[agt.wallet][payToken] += r;
                leftFee -= r;

                if (r > 0) agentRebates[agt.agentId].push(Order.Rebates(orderId, r));
            } else {
                if (p.sameLevelFee != 0) { // if agent fee ratio is 0, share same level fee
                    pendingRewards[agt.wallet][payToken] += p.sameLevelFee;
                    agentRebates[agt.agentId].push(Order.Rebates(orderId, p.sameLevelFee));

                    p.sameLevelFee = 0;
                }
            }
        }

        if (leftFee > 0) {
            pendingRewards[operatorWallet][payToken] += leftFee;
        }

        if (p.sameLevelFee > 0) {
            pendingRewards[operatorWallet][payToken] += p.sameLevelFee;
        }
    }

    function dispatchReputationAndAirdrop(Order.Record memory order, bool forSeller) internal {
        uint256 points = alignAmount18(order.payToken, order.sellAmount) * reputationRatio / RatioPrecision;
        Order.Rewards storage rewards = orderRewards[order.orderId];

        reputation.grant(order.buyer, points);
        airdropPoints[order.buyer]  += 1;
        rewards.buyerReputation = uint128(points);
        rewards.buyerAirdropPoints  = uint128(1);

        if (forSeller) {
            reputation.grant(order.seller, points);
            airdropPoints[order.seller] += 1;
            rewards.sellerReputation = uint128(points);
            rewards.sellerAirdropPoints = uint128(1);
        }
    }
}
