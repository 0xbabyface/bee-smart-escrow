// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../IBeeSmart.sol";

enum StarLevel { NoneStar, Star1, Star2, Star3 }
struct Agent {
    uint96                   selfId;        // self id
    address                  selfWallet;        // wallet address
    uint96                   parentId;      // parent id
    StarLevel                starLevel;     // star level
    bool                     canAddSubAgent;// if this agent can has its own sub agent
    bool                     removed;
    string                   nickName;
}

struct RewardAgent {
    address  wallet;
    uint256  feeRatio;
    uint96   agentId;
}

contract AgentManager is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    uint96  public constant RootId = 100000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    // wallet address => Agent
    mapping(address => Agent) agents;
    // wallet address => wallets of sub agents
    mapping(address => EnumerableSet.AddressSet) subAgents;
    // wallets of global agents
    EnumerableSet.UintSet globalAgentsId;
    // agent id => agent wallet
    mapping(uint96 => address) public agentId2Wallet;
    // star level => share fee ratio
    mapping(StarLevel => uint256) public shareFeeRatio;

    uint96 public totalAgents;
    uint96        idCounter; // should be removed

    IBeeSmart     smart;

    event AgentAdded(address indexed parent, address indexed self, StarLevel starLevel, bool canAddSubAgent);
    event AgentStarLevelChanged(address indexed agent, StarLevel oldStarLevel, StarLevel newStarLevel);
    event AgentAbilityChanged(address indexed agent, bool oldAbility, bool newAbility);
    event AgentRemoved(address indexed operator, address indexed agent);

    error StarLevelMismatch(address father, address son, StarLevel newLevel, StarLevel sonLevel);

    modifier validStarLevel(StarLevel level) {
        require(level == StarLevel.Star1 || level == StarLevel.Star2 || level == StarLevel.Star3,
            "invalid star level"
        );
        _;
    }

    modifier onlyValidAgent(address agent) {
        require(
            !agents[agent].removed && agents[agent].selfId != 0,
            "agent is invalid"
        );
        _;
    }

    modifier onlyTopAgent(address agent) {
        require(
            !agents[agent].removed && agents[agent].selfId != 0 && agents[agent].parentId == RootId,
            "agent is not top agent"
        );
        _;
    }

    function hasAdminRole(address account) internal view returns(bool) {
        return smart.hasRole(smart.AdminRole(), account);
    }

    modifier onlyAdmin() {
        require(hasAdminRole(msg.sender), "only Admin");
        _;
    }

    function nextId() internal returns(uint96) {
        ++totalAgents;
        return RootId + totalAgents;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IBeeSmart _smart) external initializer {
        smart = _smart;

        Agent storage rootAgent = agents[RootWallet];
        rootAgent.selfId     = RootId;
        rootAgent.selfWallet = RootWallet;

        agentId2Wallet[RootId] = RootWallet;

        shareFeeRatio[StarLevel.NoneStar] = 0;
        shareFeeRatio[StarLevel.Star1] = 0.2E18;
        shareFeeRatio[StarLevel.Star2] = 0.3E18;
        shareFeeRatio[StarLevel.Star3] = 0.5E18;
    }
    // to add top agent by platform owner
    function addTopAgent(
        address agent,
        StarLevel starLevel,
        bool canAddSubAgent,
        string memory nickName
    )
        external
        validStarLevel(starLevel)
        onlyAdmin
    {
        require(!subAgents[RootWallet].contains(agent), "already added");
        require(agent != address(0) && agent != RootWallet, "invalid agent wallet");

        subAgents[RootWallet].add(agent);

        Agent storage newAgent = agents[agent];
        newAgent.selfWallet     = agent;
        newAgent.parentId       = RootId;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;
        newAgent.removed        = false;
        newAgent.nickName       = nickName;

        // if this `agent` has been removed some time, its `selfId` should be kept
        if (newAgent.selfId == 0) {
            newAgent.selfId = nextId();
        }

        agentId2Wallet[newAgent.selfId] = agent;

        smart.onNewAgent(agent, newAgent.selfId);

        emit AgentAdded(RootWallet, agent, starLevel, canAddSubAgent);
    }

    // CAUTION: if too many levels of agents, DDOS happens
    function isSubAgent(address fatherAddress, address subAddress) internal view returns(bool) {
        if (agents[subAddress].removed || agents[fatherAddress].removed) return false;

        address temp = agentId2Wallet[agents[subAddress].parentId];
        while(temp != RootWallet) {
            if (temp == fatherAddress) return true;
            temp = agentId2Wallet[agents[temp].parentId];
        }

        return false;
    }
    /**
    * add sub agent for msg.sender
     */
    function addAgent(
        address fatherAgent,
        address sonAgent,
        StarLevel starLevel,
        bool canAddSubAgent,
        string memory nickName
    )
        external
        validStarLevel(starLevel)
        onlyValidAgent(fatherAgent)
        returns(uint96)
    {
        // should judge next conditions
        // 1. msg.sender is a agent who can add sub agent.
        require(
            !agents[msg.sender].removed && agents[msg.sender].canAddSubAgent,
            "operator address is invalid"
        );
        // 2. fatherAgent is a sub agent of msg.sender, no matter fatherAgent can add sub agent or not.
        require(
            msg.sender == fatherAgent || isSubAgent(msg.sender, fatherAgent),
            "only agent's father"
        );
        // 3. son agent is valid.
        require(
            agents[sonAgent].selfId == 0 || agents[sonAgent].removed,
            "sub agent has been bound"
        );

        require(sonAgent != address(0) && sonAgent != RootWallet, "son agent is invalid");

        Agent storage upAgent = agents[fatherAgent];
        require(starLevel <= upAgent.starLevel, "star level greater than father's");

        subAgents[upAgent.selfWallet].add(sonAgent);

        Agent storage newAgent  = agents[sonAgent];
        newAgent.selfWallet     = sonAgent;
        newAgent.parentId       = upAgent.selfId;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;
        newAgent.removed        = false;
        newAgent.nickName       = nickName;

        // if this `agent` has been removed some time, its `selfId` should be kept
        if (newAgent.selfId == 0) {
            newAgent.selfId = nextId();
        }

        agentId2Wallet[newAgent.selfId] = sonAgent;

        smart.onNewAgent(sonAgent, newAgent.selfId);

        emit AgentAdded(upAgent.selfWallet, sonAgent, starLevel, canAddSubAgent);

        return newAgent.selfId;
    }
    /**
    * comman agent can only remove its own sub agent
    * @param fatherAgent sub agent to be removed
    * @param sonAgent sub agent to be removed
     */
    function removeAgent(
        address fatherAgent,
        address sonAgent
    )
        external
        onlyTopAgent(msg.sender)
        onlyValidAgent(fatherAgent)
        onlyValidAgent(sonAgent)
    {
        require(
            isSubAgent(fatherAgent, sonAgent),
            "not your sub agent"
        );

        subAgents[fatherAgent].remove(sonAgent);
        agents[sonAgent].removed = true;

        address[] memory grandsons = subAgents[sonAgent].values();
        uint256 grandsonsCount = grandsons.length;
        uint96 fatherId = agents[fatherAgent].selfId;
        for (uint i = 0; i < grandsonsCount; ++i) {
            subAgents[fatherAgent].add(grandsons[i]);
            agents[grandsons[i]].parentId = fatherId;
        }
        delete subAgents[sonAgent];

        // just remove global agent, if not exist, do nothing
        globalAgentsId.remove(agents[sonAgent].selfId);

        emit AgentRemoved(fatherAgent, sonAgent);
    }
    // because of some reason, an agent want to change his wallet.
    // himself or owner can do this
    function changeWallet(
        address oldWallet,
        address newWallet
    )
        external
        onlyValidAgent(oldWallet)
    {
        require(
            agents[oldWallet].selfWallet == msg.sender ||
            hasAdminRole(msg.sender),
            "only owner or agent himself"
        );

        require(oldWallet != newWallet, "wallet not changed");
        require(newWallet != address(0) && newWallet != RootWallet, "new wallet is invalid");

        uint96 selfId = agents[oldWallet].selfId;
        uint96 parentId = agents[oldWallet].parentId;

        address parentWallet = agentId2Wallet[parentId];
        subAgents[parentWallet].remove(oldWallet);
        subAgents[parentWallet].add(newWallet);

        address[] memory subWallets = subAgents[oldWallet].values();
        for (uint256 i = 0; i < subWallets.length; ++i) {
            subAgents[newWallet].add(subWallets[i]);
        }
        delete subAgents[oldWallet];

        agents[newWallet] = agents[oldWallet];
        agents[newWallet].selfWallet = newWallet;
        delete agents[oldWallet];

        agentId2Wallet[selfId] = newWallet;
    }

    // only top agent or father agent can do this.
    function setAgentStarLevel(
        address agent,
        StarLevel newStarLevel
    )
        external
        onlyValidAgent(agent)
        validStarLevel(newStarLevel)
    {
        require(
            isSubAgent(msg.sender, agent) ||
            hasAdminRole(msg.sender),
            "only owner or father of agent"
        );

        address fatherAgent = agentId2Wallet[agents[agent].parentId];
        require(newStarLevel <= agents[fatherAgent].starLevel, "star level greater than father's");

        address[] memory nextAgents = subAgents[agent].values();
        uint len = nextAgents.length;
        for (uint i = 0; i < len; ++i) {
            if (agents[nextAgents[i]].starLevel > newStarLevel)
                revert StarLevelMismatch(agent, nextAgents[i], newStarLevel, agents[nextAgents[i]].starLevel);
        }

        Agent storage subAgent = agents[agent];
        StarLevel oldStarLevel = subAgent.starLevel;
        require(oldStarLevel != newStarLevel, "star level not changed");

        subAgent.starLevel = newStarLevel;

        emit AgentStarLevelChanged(agent, oldStarLevel, newStarLevel);
    }
    // only top agent and father agent can do this
    function setAgentAbility(
        address agent,
        bool newAbility
    )
        external
        onlyValidAgent(agent)
    {
        require(
            isSubAgent(msg.sender, agent) ||
            hasAdminRole(msg.sender),
            "only owner or agent's father"
        );

        Agent storage subAgent = agents[agent];
        bool oldAbility = subAgent.canAddSubAgent;
        require(oldAbility != newAbility, "star level not changed");

        subAgent.canAddSubAgent = newAbility;

        emit AgentAbilityChanged(agent, oldAbility, newAbility);
    }

    /**
    * to add a wallet as global agent
     */
    function addGlobalAgent(address wallet) external {
        require(
            agents[msg.sender].parentId == RootId ||
            hasAdminRole(msg.sender),
            "only top agent or owner"
        );
        uint256 agentId = agents[wallet].selfId;
        require(agentId != 0, "agent not exist");
        require(!agents[wallet].removed, "wallet removed");
        require(!globalAgentsId.contains(agentId), "alread set");

        globalAgentsId.add(agentId);
    }

    function removeGlobalAgent(address wallet) external {
        require(
            agents[msg.sender].parentId == RootId ||
            hasAdminRole(msg.sender),
            "only top agent or owner"
        );
        uint256 agentId = agents[wallet].selfId;
        require(agentId != 0, "agent not exist");
        require(globalAgentsId.contains(agentId), "not global agent");

        globalAgentsId.remove(agentId);
    }

    function isGlobalAgent(address wallet) external view returns(bool) {
        return globalAgentsId.contains(agents[wallet].selfId);
    }

    function getGlobalAgents(uint256 offset, uint256 limit) external view returns(address[] memory) {
        uint256 len = globalAgentsId.length();
        uint256 start;
        uint256 end;
        if (offset >= len) { start = 0; end = 0; }
        else if (offset + limit >= len) {
            start = offset;
            end = len;
        } else {
            start = offset;
            end = offset + limit;
        }

        address[] memory gAgents = new address[](end - start);
        for (uint256 i = start; i < end; ++i) {
            uint96 aid = uint96(globalAgentsId.at(i));
            gAgents[i - start] = agentId2Wallet[aid];
        }

        return gAgents;
    }

// -------------- view functions -----------------------------------------
    function isAgentId(uint96 aid) external view returns(bool) {
        address agent = agentId2Wallet[aid];
        return agent != address(0) && !agents[agent].removed;
    }

    function isAgentWallet(address wallet) external view returns(bool) {
        return agents[wallet].selfWallet != address(0) && !agents[wallet].removed;
    }

    // to get agent id
    function getAgentId(address agentAddress) external view returns(uint96) {
        address temp = agentAddress;
        while(agents[temp].removed && agents[temp].parentId != RootId) {
            temp = agentId2Wallet[agents[temp].parentId];
        }

        return agents[temp].selfId;
    }

    /**
    * get upper 4 agents if have
    */
    function getUpperAgents(address fromAgent) external view returns(RewardAgent[] memory) {
        uint count;
        address temp = fromAgent;
        do {
            if (!agents[temp].removed) ++count;
            if (agents[temp].parentId  == RootId) break;

            temp = agentId2Wallet[agents[temp].parentId];
        } while(count < 4);

        RewardAgent[] memory upper = new RewardAgent[](count);
        if (count > 0) {
            uint i;
            temp = fromAgent;
            do {
                if (!agents[temp].removed) {
                    upper[i] = RewardAgent(
                        agents[temp].selfWallet,
                        2 * rewardRatioForStarLevel( // multiply 2 because we should make all share accumulate to 100%
                            agents[temp].starLevel,
                            i == 0 ? StarLevel.NoneStar : agents[upper[i - 1].wallet].starLevel),
                        agents[temp].selfId
                    );
                    ++i;
                }
                if (agents[temp].parentId  == RootId) break;

                temp = agentId2Wallet[agents[temp].parentId];
            } while (i < count);
        }

        return upper;
    }

    function rewardRatioForStarLevel(StarLevel currentLevel, StarLevel preLevel) internal view returns(uint256) {
        return shareFeeRatio[currentLevel] - shareFeeRatio[preLevel];
    }

    function getAgentByWallet(address wallet) external view returns(Agent memory) {
        return agents[wallet];
    }

    function getAgentById(uint96 aid) external view returns(Agent memory) {
        return agents[agentId2Wallet[aid]];
    }

    function getSubAgents(address wallet) external view returns(address[] memory) {
        return subAgents[wallet].values();
    }
}
