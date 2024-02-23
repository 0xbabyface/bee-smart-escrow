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

      const agent = await manager.getAgentByWallet(agent2.address);
      expect(agent[0]).to.equal(100000002);
      expect(agent[1]).to.equal(agent2.address);
      expect(agent[2]).to.equal(100000001);
      expect(agent[3]).to.equal(2);
      expect(agent[4]).to.be.true;
      expect(agent[5]).to.be.false;

      await manager.connect(agent2).addAgent(agent2.address, agent3.address, 2, true);
      await manager.connect(agent3).addAgent(agent3.address, agent4.address, 2, false)

      await expect(
        manager.connect(topAgent).setAgentStarLevel(agent3.address, 3)
      ).to.revertedWith("star level bigger than father's");

      // remove agent3
      await manager.connect(topAgent).removeAgent(agent2.address, agent3.address);
      // now agent4's father node is agent2
      const agt4= await manager.getAgentByWallet(agent4.address);
      expect(agent2.address).to.equal(
        await manager.agentId2Wallet(agt4[2])
      );
      expect((await manager.getSubAgents(agent2.address)).includes(agent4.address)).to.be.true;
      //
    });
  });
});
