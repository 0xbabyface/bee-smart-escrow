// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

enum StarLevel { NoneStar, Star1, Star2, Star3 }
struct Agent {
    uint96                   selfId;        // self id
    address                  selfWallet;        // wallet address
    address                  parentWallet;      // parent id
    StarLevel                starLevel;     // star level
    bool                     canAddSubAgent;// if this agent can has its own sub agent
    bool                     removed;
    // EnumerableSet.AddressSet subAgents;     // wallet address of sub agents
}

struct RewardAgent {
    address  wallet;
    uint256  feeRatio;
}

contract AgentManager is Ownable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    uint96  public constant RootId = 100000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    // wallet address => Agent
    mapping(address => Agent) agents;
    // wallet address => wallets of sub agents
    mapping(address => EnumerableSet.AddressSet) subAgents;
    // agent id => agent wallet
    mapping(uint96 => address) public agentId2Wallet;
    // star level => share fee ratio
    mapping(StarLevel => uint256) public shareFeeRatio;

    uint96 public totalAgents;
    uint96        idCounter;

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
    function nextId() internal returns(uint96) {
        ++idCounter;
        ++totalAgents;
        return RootId + idCounter;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        _transferOwnership(_owner);
        Agent storage rootAgent = agents[RootWallet];
        rootAgent.selfId     = RootId;
        rootAgent.selfWallet = RootWallet;

        shareFeeRatio[StarLevel.NoneStar] = 0;
        shareFeeRatio[StarLevel.Star1] = 0.2E18;
        shareFeeRatio[StarLevel.Star2] = 0.3E18;
        shareFeeRatio[StarLevel.Star3] = 0.5E18;
    }
    // to add top agent by platform owner
    function addTopAgent(address agent, StarLevel starLevel, bool canAddSubAgent) external validStarLevel(starLevel) onlyOwner {
        // require(!agents[RootWallet].subAgents.contains(agent), "already added");
        require(!subAgents[RootWallet].contains(agent), "already added");
        subAgents[RootWallet].add(agent);

        Agent storage newAgent = agents[agent];
        newAgent.selfId         = nextId();
        newAgent.selfWallet     = agent;
        newAgent.parentWallet   = RootWallet;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;

        agentId2Wallet[newAgent.selfId] = agent;

        emit AgentAdded(RootWallet, agent, starLevel, canAddSubAgent);
    }
    /**
    * add sub agent for msg.sender
     */
    function addAgent(address subAgent, StarLevel starLevel, bool canAddSubAgent) external validStarLevel(starLevel) returns(uint96) {
        Agent storage upAgent = agents[msg.sender];
        require(upAgent.canAddSubAgent, "can not add sub agent");
        require(!subAgents[upAgent.selfWallet].contains(subAgent), "sub agent is added");
        require(agents[subAgent].selfId == 0, "sub agent has bound");
        require(starLevel <= upAgent.starLevel, "star level should less than sender");

        subAgents[upAgent.selfWallet].add(subAgent);

        Agent storage newAgent  = agents[subAgent];
        newAgent.selfId         = nextId();
        newAgent.selfWallet     = subAgent;
        newAgent.parentWallet   = upAgent.selfWallet;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;

        agentId2Wallet[newAgent.selfId] = subAgent;

        emit AgentAdded(upAgent.selfWallet, subAgent, starLevel, canAddSubAgent);

        return newAgent.selfId;
    }

    function changeWallet(address oldWallet, address newWallet) external {
        require(agents[oldWallet].selfId != 0, "invalid agent");
        require(!agents[oldWallet].removed, "removed agent");


        require(
            agents[oldWallet].selfWallet == msg.sender ||
            owner() == msg.sender,
            "invalid msg.sender"
        );

        agentId2Wallet[agents[oldWallet].selfId] = newWallet;
        agents[oldWallet].selfWallet = newWallet;
    }

    function setAgentStarLevel(address agent, StarLevel newStarLevel) validStarLevel(newStarLevel) external {
        require(
            subAgents[msg.sender].contains(agent) ||
            agents[msg.sender].parentWallet == RootWallet,
            "not your sub agent"
        );
        require(
            !agents[agent].removed,
            "agent is removed"
        );

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

    function setAgentAbility(address agent, bool newAbility) external {
        require(
            subAgents[msg.sender].contains(agent) ||
            agents[msg.sender].parentWallet == RootWallet,
            "not your sub agent"
        );

        Agent storage subAgent = agents[agent];
        bool oldAbility = subAgent.canAddSubAgent;
        require(oldAbility != newAbility, "star level not changed");

        subAgent.canAddSubAgent = newAbility;

        emit AgentAbilityChanged(agent, oldAbility, newAbility);
    }
    /**
    * comman agent can only remove its own sub agent
    * @param agent sub agent to be removed
     */
    function removeSubAgent(address agent) external {
        require(subAgents[msg.sender].contains(agent), "not your sub agent");

        subAgents[msg.sender].remove(agent);
        agents[agent].removed = true;

        emit AgentRemoved(msg.sender, agent);
    }

    /**
    * topest agent can remove any agent but topest agent
     */
    function removeAnyAgent(address agent) external {
        require(agents[msg.sender].selfWallet == RootWallet, "you are not top agent");
        require(agents[agent].selfWallet != RootWallet, "can not remove top agent");

        agents[agent].removed = true;

        Agent storage pAgent = agents[agent];
        subAgents[pAgent.selfWallet].remove(agent);

        emit AgentRemoved(msg.sender, agent);
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
        while(agents[temp].removed && agents[temp].parentWallet != RootWallet) {
            temp = agents[temp].parentWallet;
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
            if (agents[temp].parentWallet  == RootWallet) break;

            temp = agents[temp].parentWallet;
        } while(count < 4);

        RewardAgent[] memory upper = new RewardAgent[](count);
        if (count > 0) {
            uint i;
            temp = fromAgent;
            do {
                if (!agents[temp].removed) {
                    upper[i] = RewardAgent(
                        agents[temp].selfWallet,
                        rewardRatioForStarLevel(
                            agents[temp].starLevel,
                            i == 0 ? StarLevel.NoneStar : agents[upper[i - 1].wallet].starLevel)
                    );
                    ++i;
                }
                if (agents[temp].parentWallet  == RootWallet) break;

                temp = agents[temp].parentWallet;
            } while (i < count);
        }

        return upper;
    }

    function rewardRatioForStarLevel(StarLevel currentLevel, StarLevel preLevel) internal view returns(uint256) {
        return shareFeeRatio[currentLevel] - shareFeeRatio[preLevel];
    }

    function getAgentBasic(address wallet) external view returns(Agent memory) {
        return agents[wallet];
    }

    function getSubAgents(address wallet) external view returns(address[] memory) {
        return subAgents[wallet].values();
    }
}
