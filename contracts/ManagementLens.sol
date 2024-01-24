
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IBeeSmart.sol";

contract ManagementLens {

    struct SysSettings {
        address   reputation;               // 声誉合约
        address   agentMgr;                 // 代理管理合约

        address   communityWallet;          // 社区钱包
        address   operatorWallet;           // 运营钱包
        address   globalShareWallet;        // 全球分享合约

        uint64    orderStatusDurationSec;   // 交易状态进行时间(秒数), 默认 30 * 60 s
        uint256   communityFeeRatio;        // 社区分成比例: 20%
        uint256   operatorFeeRatio;         // 运营分成比例 10%
        uint256   globalShareFeeRatio;      // 全球分享比例
        uint256   sameLevelFeeRatio;        // 同级代理分享比例
        uint256   chargesBaredBuyerRatio ;  // 买家交易手续费 0.5%
        uint256   chargesBaredSellerRatio;  // 卖家交易手续费 0.5%
        uint256   reputationRatio;          // 声誉值/交易量兑换比例  tradeAmount * reputationRatio = Points
        uint256   disputeWinnerFeeRatio;    // 争议处理费比例:  交易额 * 比例
    }

    enum Role {Common, Admin, Community, Agent }
    struct RewardInfo {
        address tokenAddress;
        string  symbol;
        uint8   decimals;
        uint256 pendingRewards;
    }

    struct UserInfo {
        Role role;
        RewardInfo[] rewards;
    }

    function getRole(IBeeSmart smart, address wallet) external view returns(UserInfo memory) {
        Role r;
        if (smart.hasRole(smart.AdminRole(), wallet)) r = Role.Admin;
        else if (smart.hasRole(smart.CommunityRole(), wallet)) r = Role.Community;
        else if (smart.agentMgr().getAgentId(wallet) != 0) r = Role.Agent;

        UserInfo memory info = UserInfo({
            role: r,
            rewards: new RewardInfo[](0)
        });

        if (r != Role.Common) {
            address[] memory supportTokens = smart.getSupportTokens();
            uint len = supportTokens.length;
            RewardInfo[] memory rewards = new RewardInfo[](len);
            for (uint i = 0; i < len; ++i) {
                IERC20Metadata token = IERC20Metadata(supportTokens[i]);

                rewards[i] = RewardInfo({
                    tokenAddress: address(token),
                    symbol: token.symbol(),
                    decimals: token.decimals(),
                    pendingRewards: smart.pendingRewards(wallet, address(token))
                });
            }

            info.rewards = rewards;
        }

        return info;
    }

    function getSysSettings(IBeeSmart smart) external view returns(SysSettings memory) {
        SysSettings memory s = SysSettings({
            reputation:              address(smart.reputation()),
            agentMgr:                address(smart.agentMgr()),
            communityWallet:         smart.communityWallet(),
            operatorWallet:          smart.operatorWallet(),
            globalShareWallet:       smart.globalShareWallet(),
            orderStatusDurationSec:  smart.orderStatusDurationSec(),
            communityFeeRatio:       smart.communityFeeRatio(),
            operatorFeeRatio:        smart.operatorFeeRatio(),
            globalShareFeeRatio:     smart.globalShareFeeRatio(),
            sameLevelFeeRatio:       smart.sameLevelFeeRatio(),
            chargesBaredBuyerRatio:  smart.charegesBaredBuyerRatio(),
            chargesBaredSellerRatio: smart.chargesBaredSellerRatio(),
            reputationRatio:         smart.reputationRatio(),
            disputeWinnerFeeRatio:   smart.disputeWinnerFeeRatio()
        });

        return s;
    }

    struct AgentInfo {
        uint96     selfId;            // 代理ID
        address    selfWallet;        // 钱包地址
        address    parentWallet;      // 父代理ID
        StarLevel  starLevel;         // 星级
        bool       canAddSubAgent;    // 是否允许增加下级
        bool       removed;           // 是否已经被删除
        address[]  subAgents;         // 子代理账号
    }
    function getAgentInfo(IBeeSmart smart, address wallet) external view returns(AgentInfo memory) {
        Agent memory agent = smart.agentMgr().getAgentBasic(wallet);

        AgentInfo memory a = AgentInfo({
            selfId: agent.selfId,
            selfWallet: agent.selfWallet,
            parentWallet: agent.parentWallet,
            starLevel: agent.starLevel,
            canAddSubAgent: agent.canAddSubAgent,
            removed: agent.removed,
            subAgents: smart.agentMgr().getSubAgents(wallet)
        });

        return a;
    }
}