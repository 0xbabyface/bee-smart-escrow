// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./components/IRelationship.sol";
import "./components/IReputation.sol";

enum OrderStatus { UNKNOWN, WAITING, ADJUSTED, CONFIRMED, CANCELLED, TIMEOUT, DISPUTING, RECALLED }
struct Order {
    address payToken;
    uint256 sellAmount;
    address buyer;
    address seller;
    OrderStatus status;
    uint64  updatedAt;
}

interface IBeeSmart {
    function getLengthOfSellOrders(address) external view returns(uint256);
    function getLengthOfBuyOrders(address) external view returns(uint256);
    function sellOrdersOfUser(address, uint256) external view returns(bytes32);
    function buyOrdersOfUser(address, uint256) external view returns(bytes32);
    function orders(bytes32) external view returns(Order memory);
    function relationship() external view returns(IRelationship);
    function reputation() external view returns(IReputation);
    function airdropPoints(uint256) external view returns(uint256);
    function getSupportTokens() external view returns(address[] memory);
    function rebateRewards(uint256,address) external view returns(uint256);
}

contract BeeSmartLens {

    function getTotalSellOrders(IBeeSmart smart, address wallet, uint256 lastN) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        uint256 count = length > lastN ? lastN : length;
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = length - 1; i >= count; --i) {
            bytes32 orderHash =  smart.sellOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
            ++j;
        }

        return orders;
    }

    function getTotalBuyOrders(IBeeSmart smart, address wallet, uint256 lastN) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256 count = length > lastN ? lastN : length;
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = length - 1; i >= count; --i) {
            bytes32 orderHash =  smart.buyOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
            ++j;
        }

        return orders;
    }

    // read both buyer & seller order of this wallet, less than 200 orders.
    function getStatusUpdatedOrder(IBeeSmart smart, address wallet, uint256 updatedAfter) public view returns(Order[] memory, uint256) {
        Order[] memory sellOrders = getTotalSellOrders(smart, wallet, 100);
        Order[] memory buyOrders = getTotalBuyOrders(smart, wallet, 100);
        Order[] memory result = new Order[](sellOrders.length + buyOrders.length);

        uint256 length;
        for (uint256 i = 0; i < sellOrders.length; ++i) {
            if (sellOrders[i].updatedAt >= updatedAfter) {
                result[length] = sellOrders[i];
                ++length;
            }
        }

        for (uint256 i = 0; i < buyOrders.length; ++i) {
            if (buyOrders[i].updatedAt >= updatedAfter) {
                result[length] = buyOrders[i];
                ++length;
            }
        }

        return (result, length);
    }

    struct RebateInfo {
        address token;  // trade token
        uint256 rebate; // rebates
    }

    struct AssetBalance {
        address token;
        string symbol;
        uint8  decimals;
        uint256 balance;
    }

    struct UserInfo {
        uint256 relationId;
        uint256 airdropCount;
        uint256 reputationCount;
        uint256 totalTrades;
        RebateInfo[] rebates;
        AssetBalance[] assetsBalance;
    }

    function getUserInfo(IBeeSmart smart, address wallet) public view returns(UserInfo memory) {
        IRelationship relationship = smart.relationship();
        IReputation reputation = smart.reputation();

        uint256 relationId = relationship.getRelationId(wallet);
        address[] memory tradableTokens = smart.getSupportTokens();

        UserInfo memory info = UserInfo({
            relationId: relationId,
            airdropCount: smart.airdropPoints(relationId),
            reputationCount: reputation.reputationPoints(address(smart), relationId),
            totalTrades: smart.getLengthOfBuyOrders(wallet) + smart.getLengthOfSellOrders(wallet),
            rebates: new RebateInfo[](tradableTokens.length),
            assetsBalance: new AssetBalance[](tradableTokens.length)
        });
        for (uint i = 0; i < tradableTokens.length; ++i) {
            info.rebates[i] = RebateInfo(tradableTokens[i], smart.rebateRewards(relationId, tradableTokens[i]));
        }

        for (uint i = 0; i < tradableTokens.length; ++i) {
            address token = tradableTokens[i];
            IERC20Metadata erc20 = IERC20Metadata(token);
            info.assetsBalance[i] = AssetBalance(tradableTokens[i], erc20.symbol(), erc20.decimals(), erc20.balanceOf(wallet));
        }

        return info;
    }
}