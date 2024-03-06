import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { deployBeeSmarts } from "./common";

enum StarLevel { NoneStar, Star1, Star2, Star3 }

describe("AgentManager", async function () {

  function parseUserInfo(id: bigint) {
    const userId = id >> BigInt(96);
    const agentId = id & BigInt("0xffffffffffffffff");

    return {userId, agentId};
  }

  describe("normal", function () {

    it("normal operations", async function () {
      const { agentManager: manager, agent1: topAgent, agent2, agent3, agent4 } = await loadFixture(deployBeeSmarts);

      await manager.connect(topAgent).addAgent(topAgent.address, agent2.address, StarLevel.Star2, true, "sub agent2");

      await expect(
        manager.connect(topAgent).addAgent(agent2.address, agent3.address, StarLevel.Star3, true, 'sub agent 3')
      ).to.revertedWith("star level greater than father's");

      const agent = await manager.getAgentByWallet(agent2.address);
      expect(agent[0]).to.equal(100000002);
      expect(agent[1]).to.equal(agent2.address);
      expect(agent[2]).to.equal(100000001);
      expect(agent[3]).to.equal(2);
      expect(agent[4]).to.be.true;
      expect(agent[5]).to.be.false;

      await manager.connect(agent2).addAgent(agent2.address, agent3.address, 2, true, 'sub agent 3');
      await manager.connect(agent3).addAgent(agent3.address, agent4.address, 2, false, 'sub agent 4')

      await expect(
        manager.connect(topAgent).setAgentStarLevel(agent3.address, 3)
      ).to.revertedWith("star level greater than father's");

      await manager.connect(topAgent).setAgentStarLevel(agent2.address, 3)
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

    it('bind to topAgent then become agent', async function () {
      const { smart, agentManager: manager, agent1: topAgent, agent2 } = await loadFixture(deployBeeSmarts);

      const topAgentId = await manager.getAgentId(topAgent.address);

      await smart.connect(agent2).bindRelationship(topAgentId);
      let boundId = await smart.boundAgents(agent2.address);
      let {userId: userid1, agentId: agentId1} = parseUserInfo(boundId);
      expect(agentId1).to.equal(topAgentId);

      await manager.connect(topAgent).addAgent(topAgent.address, agent2.address, StarLevel.Star2, true, "sub agent2");
      const agent2Id = await manager.getAgentId(agent2.address);

      let boundId2 = await smart.boundAgents(agent2.address);
      let {userId: userid2, agentId: agentid2} = parseUserInfo(boundId2);
      expect(agentid2).to.equal(agent2Id);
      expect(userid1).to.equal(userid2);
    });

    it('become agent then self bound', async function () {
      const { smart, agentManager: manager, agent1: topAgent, agent2 } = await loadFixture(deployBeeSmarts);

      await manager.connect(topAgent).addAgent(topAgent.address, agent2.address, StarLevel.Star2, true, "sub agent2");
      const agent2Id = await manager.getAgentId(agent2.address);

      let boundId2 = await smart.boundAgents(agent2.address);
      let {agentId: agentid2} = parseUserInfo(boundId2);
      expect(agentid2).to.equal(agent2Id);
    })
  });
});
