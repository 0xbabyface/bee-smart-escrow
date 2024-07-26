
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IBeeSmart.sol";

contract ManagementLens {

    uint16 constant RoleCommon    = 0x00;
    uint16 constant RoleAdmin     = 0x01;
    uint16 constant RoleCommunity = 0x02;
    uint16 constant RoleOperator  = 0x04;
    uint16 constant RoleTopAgent  = 0x08;
    uint16 constant RoleAgent     = 0x10;

    struct OperatorWallet {
        uint96 operatorId;
        address wallet;
    }

    struct SysSettings {
        address   reputation;               // 声誉合约
        address   agentMgr;                 // 代理管理合约

        address   communityWallet;          // 社区钱包
        address   globalShareWallet;        // 全球分享合约

        uint64    orderStatusDurationSec;   // 交易状态进行时间(秒数), 默认 30 * 60 s
        uint64    disputeStatusDurationSec; // 争议处理时间(秒数), 默认 120 * 60 s
        uint256   communityFeeRatio;        // 社区分成比例: 20%
        uint256   operatorFeeRatio;         // 运营分成比例 10%
        uint256   globalShareFeeRatio;      // 全球分享比例
        uint256   sameLevelFeeRatio;        // 同级代理分享比例
        uint256   chargesBaredBuyerRatio ;  // 买家交易手续费 0.5%
        uint256   chargesBaredSellerRatio;  // 卖家交易手续费 0.5%
        uint256   reputationRatio;          // 声誉值/交易量兑换比例  tradeAmount * reputationRatio = Points
        uint256   disputeWinnerFeeRatio;    // 争议处理费比例:  交易额 * 比例

        OperatorWallet[] operatorWallets;
    }

    struct RewardInfo {
        address tokenAddress;
        string  symbol;
        uint8   decimals;
        uint256 pendingRewards;
    }

    struct UserInfo {
        uint16 role;
        RewardInfo[] rewards;
    }

    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint8 decimals;
    }

    function getSupportTokens(IBeeSmart smart) external view returns(TokenInfo[] memory) {
        address[] memory supportTokens = smart.getSupportTokens();
        uint len = supportTokens.length;
        TokenInfo[] memory tokens = new TokenInfo[](len);
        for (uint i = 0; i < len; ++i) {
            IERC20Metadata token = IERC20Metadata(supportTokens[i]);

            tokens[i] = TokenInfo({
                tokenAddress: address(token),
                symbol: token.symbol(),
                decimals: token.decimals()
            });
        }
        return tokens;
    }

    function getHistoryOrders(IBeeSmart smart, uint offset, uint limit) external view returns(uint256, Order.Record[] memory) {
        uint256 totalOrders = smart.totalOrdersCount();
        uint256 start;
        uint256 end;
        if (totalOrders >= offset + limit) {
            start = totalOrders - offset;
            end = start - limit;
        } else if (totalOrders >= offset) {
            start = totalOrders - offset;
            end = 0;
        } /*else {
            start = 0;
            end = 0;
        }*/

        Order.Record[] memory records = new Order.Record[](start - end);
        uint j;
        for (uint i = start; i > end; --i) {
            records[j] = smart.orders(i);
            ++j;
        }

        return (totalOrders, records);
    }

    function getRole(IBeeSmart smart, address wallet) external view returns(UserInfo memory) {
        uint16 r = RoleCommon;
        if (smart.hasRole(smart.AdminRole(), wallet))     r += RoleAdmin;
        if (smart.hasRole(smart.CommunityRole(), wallet)) r += RoleCommunity;
        if (smart.operatorWallets2Id(wallet) != 0)        r += RoleOperator;

        Agent memory agent = smart.agentMgr().getAgentByWallet(wallet);
        if (agent.selfId != 0) {
            if (agent.parentId == smart.agentMgr().RootId())
                r += RoleTopAgent;
            else
                r += RoleAgent;
        }

        address[] memory supportTokens = smart.getSupportTokens();
        uint len = supportTokens.length;
        RewardInfo[] memory rewards = new RewardInfo[](len);
        for (uint i = 0; i < len; ++i) {
            IERC20Metadata token = IERC20Metadata(supportTokens[i]);

            rewards[i] = RewardInfo({
                tokenAddress:   address(token),
                symbol:         token.symbol(),
                decimals:       token.decimals(),
                pendingRewards: smart.pendingRewards(wallet, address(token))
            });
        }

        UserInfo memory info = UserInfo({
            role: r,
            rewards: rewards
        });

        return info;
    }

    function getSysSettings(IBeeSmart smart) external view returns(SysSettings memory) {
        uint96 operatorIds = smart.agentMgr().operatorId();

        SysSettings memory s = SysSettings({
            reputation:              address(smart.reputation()),
            agentMgr:                address(smart.agentMgr()),
            communityWallet:         smart.communityWallet(),
            globalShareWallet:       smart.globalShareWallet(),
            orderStatusDurationSec:  smart.orderStatusDurationSec(),
            disputeStatusDurationSec: smart.disputeStatusDurationSec(),
            communityFeeRatio:       smart.communityFeeRatio(),
            operatorFeeRatio:        smart.operatorFeeRatio(),
            globalShareFeeRatio:     smart.globalShareFeeRatio(),
            sameLevelFeeRatio:       smart.sameLevelFeeRatio(),
            chargesBaredBuyerRatio:  smart.chargesBaredBuyerRatio(),
            chargesBaredSellerRatio: smart.chargesBaredSellerRatio(),
            reputationRatio:         smart.reputationRatio(),
            disputeWinnerFeeRatio:   smart.disputeWinnerFeeRatio(),
            operatorWallets:         new OperatorWallet[](operatorIds - 80)
        });

        for (uint96 i = 80; i < operatorIds; ++i) {
            s.operatorWallets[i-80] = OperatorWallet({
                operatorId: (i) * 10**4,
                wallet: smart.operatorWallets(i)
            });
        }

        return s;
    }

    struct AgentInfo {
        uint96     selfId;            // 代理ID
        address    selfWallet;        // 钱包地址
        uint96     parentId;          // 父代理ID
        StarLevel  starLevel;         // 星级
        bool       canAddSubAgent;    // 是否允许增加下级
        bool       removed;           // 是否已经被删除
        bool       isGlobalAgent;     // 是否全球代理
        address[]  subAgents;         // 子代理账号
        string     nickName;          //
        address    operatorWallet;    // 运营钱包
    }
    function getAgentInfo(IBeeSmart smart, address wallet) external view returns(AgentInfo memory) {
        Agent memory agent = smart.agentMgr().getAgentByWallet(wallet);

        AgentInfo memory a = AgentInfo({
            selfId:         agent.selfId,
            selfWallet:     agent.selfWallet,
            parentId:       agent.parentId,
            starLevel:      agent.starLevel,
            canAddSubAgent: agent.canAddSubAgent,
            removed:        agent.removed,
            isGlobalAgent:  smart.agentMgr().isGlobalAgent(wallet),
            subAgents:      smart.agentMgr().getSubAgents(wallet),
            nickName:       agent.nickName,
            operatorWallet: smart.getOperatorWallet(wallet)
        });

        return a;
    }

    function getAgentInfoByOperator(IBeeSmart smart, address operatorWallet)
        external
        view
        returns(AgentInfo memory a )
    {
        address RootWallet   = address(0x000000000000000000000000000000000000dEaD);
        address[] memory topAgents = smart.agentMgr().getSubAgents(RootWallet);
        uint256 len = topAgents.length;
        for (uint i; i < len; ++i) {
            Agent memory  agt = smart.agentMgr().getAgentByWallet(topAgents[i]);
            uint96 operatorId = agt.selfId / 1E4;
            address o = smart.operatorWallets(operatorId);
            if (o == operatorWallet) {
                a = this.getAgentInfo(smart, agt.selfWallet);
                break;
            }
        }
    }

    struct AgentRebateInfo {
        uint256 orderId;         // 订单ID
        address buyer;           // 买家
        address seller;          // 卖家
        address payToken;        // token
        string  symbol;          // symbol
        uint8   decimals;         // decimal
        uint256 sellAmount;      // 交易金额
        uint256 rebateAmount;    //返利金额
        uint64  timestamp;       // 返利时间
    }
    function getRebateInfo(IBeeSmart smart, uint96 agentId, uint256 offset, uint256 limit)
        external
        view
        returns(uint256, AgentRebateInfo[] memory)
    {
        Agent memory agent = smart.agentMgr().getAgentById(agentId);
        if (agent.selfId == 0) {
            return (0, new AgentRebateInfo[](0));
        }

        uint256 total = smart.getAgentRebateLength(agentId);
        if (total == 0) {
            return (0, new AgentRebateInfo[](0));
        }

        if (total <= offset) {
            return (0, new AgentRebateInfo[](0));
        }

        uint256 start;
        uint256 end;
        if (total >= offset + limit) {
            start = total - offset - 1;
            end = start + 1 - limit;
        } else if (total > offset) {
            start = total - offset - 1;
            end = 0;
        }

        AgentRebateInfo[] memory records = new AgentRebateInfo[](start + 1 - end);
        uint j;
        for (uint i = start; i >= end;) {
            Order.Rebates memory rebate = smart.getAgentRebate(agentId, i);
            Order.Record  memory order = smart.orders(rebate.orderId);
            IERC20Metadata payToken = IERC20Metadata(order.payToken);
            records[j] = AgentRebateInfo({
                orderId:      order.orderId,
                buyer:        order.buyer,
                seller:       order.seller,
                payToken:     order.payToken,
                symbol:       payToken.symbol(),
                decimals:     payToken.decimals(),
                sellAmount:   order.sellAmount,
                rebateAmount: rebate.amount,
                timestamp:    order.updatedAt
            });
            ++j;

            if (i == 0) break;
            --i;
        }

        return (total, records);
    }
}