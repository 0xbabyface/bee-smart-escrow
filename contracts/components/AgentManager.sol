// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

struct Agent {
    uint96                   selfId;        // self id
    uint32                   starLevel;     // star level
    bool                     canAddSubAgent;// if this agent can has its own sub agent
    address                  parentWallet;      // parent id
    address                  selfWallet;        // wallet address
    EnumerableSet.AddressSet subAgents;     // wallet address of sub agents
}

struct SimpleAgent {
    address wallet;
    uint32  startLevel;
}

contract AgentManager is Ownable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    uint96  public constant RootId = 100000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);


    // wallet address => Agent
    mapping(address => Agent) agents;
    // agent id => agent wallet
    mapping(uint96 => address) walletMapping;
    uint96 public totalAgents;
    uint96        idCounter;

    event AgentAdded(address indexed parent, address indexed self, uint32 starLevel, bool canAddSubAgent);
    event AgentStarLevelChanged(address indexed agent, uint32 oldStarLevel, uint32 newStarLevel);
    event AgentAbilityChanged(address indexed agent, bool oldAbility, bool newAbility);
    event AgentRemoved(address indexed operator, address indexed agent);

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
    }

    function addTopAgent(address agent, uint32 starLevel, bool canAddSubAgent) external onlyOwner {
        require(!agents[RootWallet].subAgents.contains(agent), "already added");
        agents[RootWallet].subAgents.add(agent);

        Agent storage newAgent = agents[agent];
        newAgent.selfId         = nextId();
        newAgent.selfWallet     = agent;
        newAgent.parentWallet   = RootWallet;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;

        walletMapping[newAgent.selfId] = RootWallet;

        emit AgentAdded(RootWallet, agent, starLevel, canAddSubAgent);
    }
    /**
    *
     */
    function addAgent(address subAgent, uint32 starLevel, bool canAddSubAgent) external returns(uint96) {
        Agent storage agent = agents[msg.sender];
        require(agent.canAddSubAgent, "can not add sub agent");
        require(!agent.subAgents.contains(subAgent), "sub agent is added");
        require(agents[subAgent].selfId == 0, "sub agent has bound");

        agent.subAgents.add(subAgent);

        Agent storage newAgent  = agents[subAgent];
        newAgent.selfId         = nextId();
        newAgent.selfWallet     = subAgent;
        newAgent.parentWallet   = agent.selfWallet;
        newAgent.starLevel      = starLevel;
        newAgent.canAddSubAgent = canAddSubAgent;

        walletMapping[newAgent.selfId] = subAgent;

        emit AgentAdded(agent.selfWallet, subAgent, starLevel, canAddSubAgent);

        return newAgent.selfId;
    }

    function setAgentStarLevel(address agent, uint32 newStarLevel) external {
        require(agents[msg.sender].subAgents.contains(agent), "not your sub agent");

        Agent storage subAgent = agents[agent];
        uint32 oldStarLevel = subAgent.starLevel;
        require(oldStarLevel != newStarLevel, "star level not changed");

        subAgent.starLevel = newStarLevel;

        emit AgentStarLevelChanged(agent, oldStarLevel, newStarLevel);
    }

    function setAgentAbility(address agent, bool newAbility) external {
        require(agents[msg.sender].subAgents.contains(agent), "not your sub agent");

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
        require(agents[msg.sender].subAgents.contains(agent), "not your sub agent");

        doRemoveAgent(msg.sender, agent);
    }

    /**
    * topest agent can remove any agent but topest agent
     */
    function removeAnyAgent(address agent) external {
        require(agents[msg.sender].selfWallet == RootWallet, "you are not top agent");
        require(agents[agent].selfWallet != RootWallet, "can not remove top agent");

        doRemoveAgent(agents[agent].parentWallet, agent);
    }

    function doRemoveAgent(address parent, address son) internal {
        Agent storage removedAgent = agents[son];
        Agent storage parentAgent = agents[parent];
        address[] memory sons = removedAgent.subAgents.values();
        uint256 len = sons.length;
        for (uint256 i = 0; i < len; ++i) {
            parentAgent.subAgents.add(sons[i]);
        }

        delete walletMapping[removedAgent.selfId];
        delete agents[son];
        --totalAgents;

        emit AgentRemoved(msg.sender, son);
    }
// -------------- view functions -----------------------------------------
    function isAgentId(uint96 aid) external view returns(bool) {
        return walletMapping[aid] != address(0);
    }

    function isAgentWallet(address wallet) external view returns(bool) {
        return agents[wallet].selfWallet != address(0);
    }
    /**
    * get upper 4 agents if have
    */
    function getUpperAgents(address fromAgent) external view returns(SimpleAgent[] memory) {

        uint count = 1;
        address temp = fromAgent;
        for (uint i = 0; i < 4; ++i) {
            if (agents[temp].parentWallet == RootWallet) break;

            ++count;
            temp = agents[temp].parentWallet;
        }

        temp = fromAgent;
        SimpleAgent[] memory upper = new SimpleAgent[](count);
        for (uint i = 0; i < count; ++i) {
            upper[i] = SimpleAgent(agents[temp].selfWallet, agents[temp].starLevel);

            if (agents[temp].parentWallet == RootWallet) break;
            temp = agents[temp].parentWallet;
        }

        return upper;
    }
}