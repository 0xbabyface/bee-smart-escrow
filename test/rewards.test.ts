import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { Status, airdropRewards, buyerFee, communityFee, deployBeeSmarts, forwardBlockTimestamp, reputationRewards, sellerFee } from "./common";


describe("BeeSmart", async function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  let contracts: any = {};

  beforeEach(async () => {
    const cc = await loadFixture(deployBeeSmarts);
    // const agent1Id = await cc.agentManager.getAgentId(cc.agent1.address);

    // await cc.smart.connect(cc.buyer).bindRelationship(agent1Id);
    // await cc.smart.connect(cc.seller).bindRelationship(agent1Id);

    contracts = cc;
  })

  afterEach(async () => {
    // console.log("after each")
  })

  describe("rewards for traders", function () {

    it("rewards share: 3-3-3-3", async function () {
      const { smart, seller, buyer, USDT, communityWallet, agentWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } = contracts;

      await agentManager.connect(agent1).addAgent(agent2.address, 3, true);
      await agentManager.connect(agent2).addAgent(agent3.address, 3, true);
      await agentManager.connect(agent3).addAgent(agent4.address, 3, true);

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);
      const tempA = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, tempA, buyer.address);

      const tempOrderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(tempOrderId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const agentBalanceBefore = await smart.pendingRewards(agentWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("10000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);

      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const agentBalanceAfter = await smart.pendingRewards(agentWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);


    });
  });
});
