import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { Status, airdropRewards, buyerFee, communityFee, deployBeeSmarts, disputeWinnerFee, forwardBlockTimestamp, reputationRewards, sellerFee } from "./common";

enum StarLevel { NoneStar, Star1, Star2, Star3 }

async function deployAgentManager() {
  const [owner, topAgent, agent2, agent3, agent4] = await ethers.getSigners();
  const AgentManager = await ethers.deployContract("AgentManager");
  await AgentManager.waitForDeployment();
  const agentInit = AgentManager.interface.encodeFunctionData(
    'initialize',
    [owner.address]
  );
  const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, owner.address]);
  await AgentManagerProxy.waitForDeployment();

  const manager = await ethers.getContractAt("AgentManager", AgentManagerProxy.target);

  return {manager, owner, topAgent, agent2, agent3, agent4};
}

describe("AgentManager", async function () {

  describe("normal procedures of order", function () {

    it("make order over reputations", async function () {
      const { manager, owner, topAgent, agent2, agent3, agent4 } = await loadFixture(deployAgentManager);

      await manager.addTopAgent(topAgent.address, StarLevel.Star3, true);

      await manager.connect(topAgent).addAgent(topAgent.address, agent2.address, StarLevel.Star2, true);

      await expect(
        manager.connect(topAgent).addAgent(agent2.address, agent3.address, StarLevel.Star3, true)
      ).to.revertedWith("star level should less than sender");


    });
  });
});
