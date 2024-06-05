// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./components/IReputation.sol";
import "./components/AgentManager.sol";
import "./libs/Order.sol";
import "./IBeeSmart.sol";


enum FilterType { SellOngoing, BuyOngoing, SellHistory, BuyHistory}
contract BeeSmartLens {

    function _filterOngoingOrders(FilterType fType, IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        internal
        view
        returns(Order.Record[] memory)
    {
        uint256 length;

        if (fType == FilterType.SellOngoing)
            length = smart.getLengthOfSellOrders(wallet);
        else
            length = smart.getLengthOfBuyOrders(wallet);

        uint256[] memory hashes = new uint256[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId;
            if (fType == FilterType.SellOngoing) {
                orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            } else if (fType == FilterType.BuyOngoing) {
                orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            }

            Order.Record memory ord = smart.orders(orderId);
            if (_isOngoingOrder(ord, timestamp)) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order.Record[] memory resultOrders = new Order.Record[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
        }
        return resultOrders;
    }

    function _filterHistoryOrders(FilterType fType, IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        internal
        view
        returns(Order.Record[] memory, Order.Rewards[] memory)
    {
        uint256 length;

        if (fType == FilterType.SellHistory)
            length = smart.getLengthOfSellOrders(wallet);
        else
            length = smart.getLengthOfBuyOrders(wallet);

        uint256[] memory hashes = new uint256[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId;
            if (fType == FilterType.SellHistory) {
                orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            } else if (fType == FilterType.BuyHistory) {
                orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            }

            Order.Record memory ord = smart.orders(orderId);
            if ( _isHistoryOrder(ord, timestamp)) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order.Record[] memory resultOrders = new Order.Record[](resultCount);
        Order.Rewards[] memory historyOrdersRewards = new Order.Rewards[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
            historyOrdersRewards[i] = smart.orderRewards(hashes[count - i - 1]);
        }
        return (resultOrders, historyOrdersRewards);
    }

    function _isOngoingOrder(Order.Record memory ord, uint256 timestamp) internal pure returns(bool) {
        return  ord.updatedAt <= timestamp &&
                (
                ord.currStatus == Order.Status.NORMAL ||
                ord.currStatus == Order.Status.ADJUSTED ||
                ord.currStatus == Order.Status.SELLERDISPUTE ||
                ord.currStatus == Order.Status.BUYERDISPUTE ||
                ord.currStatus == Order.Status.LOCKED
                );
    }

    function _isHistoryOrder(Order.Record memory ord, uint256 timestamp) internal pure returns(bool) {
        return  (ord.updatedAt <= timestamp &&
                (
                ord.currStatus == Order.Status.CONFIRMED ||
                ord.currStatus == Order.Status.CANCELLED ||
                ord.currStatus == Order.Status.BUYERWIN ||
                ord.currStatus == Order.Status.SELLERWIN
                )
            );
    }

    function getOngoingSellOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        public
        view
        returns(Order.Record[] memory)
    {
        return _filterOngoingOrders(FilterType.SellOngoing, smart, wallet, timestamp, maxCount);
    }

    function getOngoingBuyOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount) public view returns(Order.Record[] memory) {
        return _filterOngoingOrders(FilterType.BuyOngoing, smart, wallet, timestamp, maxCount);
    }

    function getHistorySellOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        public
        view
        returns(Order.Record[] memory, Order.Rewards[] memory)
    {
        return _filterHistoryOrders(FilterType.SellHistory, smart, wallet, timestamp, maxCount);
    }

    function getHistoryBuyOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        public
        view
        returns(Order.Record[] memory, Order.Rewards[] memory)
    {
        return _filterHistoryOrders(FilterType.BuyHistory, smart, wallet, timestamp, maxCount);
    }

    function getTotalSellOrders(IBeeSmart smart, address wallet, uint256 startIndex, uint256 itemCount) public view returns(Order.Record[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        uint256 count = length >= (startIndex + itemCount) ? itemCount : (length - startIndex);
        Order.Record[] memory orders = new Order.Record[](count);

        uint256 j = 0;
        for (uint i = startIndex; i < startIndex + count; ++i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderId);
            ++j;
        }

        return orders;
    }

    function getTotalBuyOrders(IBeeSmart smart, address wallet, uint256 startIndex, uint256 itemCount) public view returns(Order.Record[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256 count = length >= (startIndex + itemCount) ? itemCount : (length - startIndex);
        Order.Record[] memory orders = new Order.Record[](count);

        uint256 j = 0;
        for (uint i = startIndex; i < startIndex + count; ++i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderId);
            ++j;
        }

        return orders;
    }

    // read both buyer & seller order of this wallet, less than 200 orders.
    function getStatusUpdatedSellOrder(
        IBeeSmart smart,
        address wallet,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order.Record[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        Order.Record[] memory tempOrders = new Order.Record[](length);

        uint256 j;
        for (uint256 i = length; i>= 1; --i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            Order.Record memory ord = smart.orders(orderId);
            if (ord.updatedAt > updatedAfter) {
                tempOrders[j] = ord;
                ++j;
            }
        }

        uint resultCount = itemCount > j ? j : itemCount;
        Order.Record[] memory resultOrders = new Order.Record[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = tempOrders[i];
        }

        return resultOrders;
    }

    function getStatusUpdatedBuyOrder(
        IBeeSmart smart,
        address wallet,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order.Record[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        Order.Record[] memory tempOrders = new Order.Record[](length);

        uint256 j;
        for (uint256 i = length; i>= 1; --i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            Order.Record memory ord = smart.orders(orderId);
            if (ord.updatedAt > updatedAfter) {
                tempOrders[j] = ord;
                ++j;
            }
        }

        uint resultCount = itemCount > j ? j : itemCount;
        Order.Record[] memory resultOrders = new Order.Record[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = tempOrders[i];
        }

        return resultOrders;
    }

    struct AssetBalance {
        address token;
        string symbol;
        uint8  decimals;
        uint256 balance;
    }

    struct UserInfo {
        uint96 userId;
        uint96 agentId;
        uint256 airdropCount;
        uint256 reputationCount;
        uint256 totalTrades;
        AssetBalance[] assetsBalance;
    }

    function getUserInfo(IBeeSmart smart, address wallet) public view returns(UserInfo memory) {
        IReputation reputation = smart.reputation();

        uint192 boundId = smart.boundAgents(wallet);
        uint96 userId = uint96(boundId >> 96);
        uint96 agentId = uint96(boundId);
        address[] memory tradableTokens = smart.getSupportTokens();

        UserInfo memory info = UserInfo({
            userId: userId,
            agentId: agentId,
            airdropCount: smart.airdropPoints(wallet),
            reputationCount: reputation.reputationPoints(wallet),
            totalTrades: smart.getLengthOfBuyOrders(wallet) + smart.getLengthOfSellOrders(wallet),
            assetsBalance: new AssetBalance[](tradableTokens.length)
        });

        for (uint i = 0; i < tradableTokens.length; ++i) {
            address token = tradableTokens[i];
            IERC20Metadata erc20 = IERC20Metadata(token);
            info.assetsBalance[i] = AssetBalance(tradableTokens[i], erc20.symbol(), erc20.decimals(), erc20.balanceOf(wallet));
        }

        return info;
    }

    // API for manage functions
    function getAllLockedOrders(IBeeSmart smart) public view returns(Order.Record[] memory) {
        uint256[] memory orderIds = smart.getAllLockedOrderIds();
        Order.Record[] memory orders = new Order.Record[](orderIds.length);
        for (uint i; i < orderIds.length; ++i) {
            orders[i] = smart.orders(orderIds[i]);
        }
        return orders;
    }
}