// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./BeeSmart.sol";
import "./CommonProxy.sol";
import "./components/AgentManager.sol";
import "./components/Reputation.sol";

contract DeployerFactory is Ownable {

    constructor() {

    }

    struct DParams {
        address communityWallet;
        address agentWallet;
        address globalWallet;
        address adminship;
        address agentMangerOwner;
        bytes32 salt;
    }
    function deploySmartSystem(
        address[] memory admins,
        address[] memory communities,
        DParams memory p
    ) external onlyOwner returns(address, address) {

        BeeSmart smart = new BeeSmart{salt: p.salt}();
        bytes memory smartInit = abi.encodeWithSelector(smart.initialize.selector,
            admins,
            communities,
            p.communityWallet,
            p.agentWallet,
            p.globalWallet
        );
        CommonProxy smartProxy = new CommonProxy{salt: p.salt}(address(smart), smartInit, p.adminship);

        Reputation reputation = new Reputation{salt: p.salt}(address(smartProxy));
        (bool success, bytes memory reason) = address(smartProxy).call(abi.encodeWithSelector(smart.setReputation.selector, address(reputation)));
        require(success, string(reason));

        AgentManager agtManager = new AgentManager{salt: p.salt}();
        bytes memory agtInit = abi.encodeWithSelector(agtManager.initialize.selector, p.agentMangerOwner);
        CommonProxy agtProxy = new CommonProxy{salt: keccak256(abi.encode(p.salt))}(address(agtManager), agtInit, p.adminship);

        return (address(smartProxy), address(agtProxy));
    }

    function getSmartAddress(
        address[] memory admins,
        address[] memory communities,
        DParams memory p
    ) external view returns(address smartProxy, address agentProxy) {
        address smart = Create2.computeAddress(p.salt, keccak256(type(BeeSmart).creationCode));
        bytes memory smartInit = abi.encodeWithSelector(BeeSmart.initialize.selector,
            admins,
            communities,
            p.communityWallet,
            p.agentWallet,
            p.globalWallet
        );
        bytes32 smartProxyCodeHash = keccak256(abi.encodePacked(type(CommonProxy).creationCode, smart, smartInit, p.adminship));
        smartProxy = Create2.computeAddress(p.salt, smartProxyCodeHash);

        address agentManager = Create2.computeAddress(p.salt, keccak256(type(AgentManager).creationCode));
        bytes memory agtInit = abi.encodeWithSelector(AgentManager.initialize.selector, p.agentMangerOwner);
        bytes32 agentProxyCodeHash = keccak256(abi.encodePacked(type(CommonProxy).creationCode, agentManager, agtInit, p.adminship));

        agentProxy = Create2.computeAddress(keccak256(abi.encode(p.salt)), agentProxyCodeHash);
    }
}