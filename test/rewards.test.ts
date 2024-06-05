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

  describe("rewards for traders", function () {

    it("rewards share: 3-3-3-3", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 3, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 3, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("25"))
    });

    it("rewards share: 3-3-3-2", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 3, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 2, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("15"))
    });

    it("rewards share: 3-3-3-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 3, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 1, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("15"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-3-2-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 2, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 1, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-2-2-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 2, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 2, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 1, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-2-1-1", async function () {
      const { smart,operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 2, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 1, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 1, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-1-1-1", async function () {
      const { smart,operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 1, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 1, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent3.address, agent4.address, 1, true, 'agent 4');

      const agentId = await agentManager.getAgentId(agent4.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceBefore = await smart.pendingRewards(agent4.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);
      const agent4BalanceAfter = await smart.pendingRewards(agent4.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("15"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent4BalanceAfter - agent4BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-3-3", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 3, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("0"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("25"))
    });

    it("rewards share: 3-3-2", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 2, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("15"))
    });

    it("rewards share: 3-3-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 1, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("15"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-2-2", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 2, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 2, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("15"))
    });

    it("rewards share: 3-2-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 2, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 1, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-1-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 1, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 1, true, 'agent 3');

      const agentId = await agentManager.getAgentId(agent3.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceBefore = await smart.pendingRewards(agent3.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);
      const agent3BalanceAfter = await smart.pendingRewards(agent3.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("15"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent3BalanceAfter - agent3BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3-3", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');

      const agentId = await agentManager.getAgentId(agent2.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("5"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("25"))
    });

    it("rewards share: 3-2", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 2, true, 'agent 2');

      const agentId = await agentManager.getAgentId(agent2.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("10"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("15"))
    });

    it("rewards share: 3-1", async function () {
      const { smart, operator, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);

      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 1, true, 'agent 2');

      const agentId = await agentManager.getAgentId(agent2.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceBefore = await smart.pendingRewards(agent2.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);
      const agent2BalanceAfter = await smart.pendingRewards(agent2.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("15"))
      expect(agent2BalanceAfter - agent2BalanceBefore).to.equal(ethers.parseEther("10"))
    });

    it("rewards share: 3", async function () {
      const { smart, seller, buyer, USDT, communityWallet, operatorWallet, globalShareWallet, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);


      const agentId = await agentManager.getAgentId(agent1.address);
      await smart.connect(buyer).bindRelationship(agentId);
      await smart.connect(seller).bindRelationship(agentId);

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceBefore = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceBefore = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceBefore = await smart.pendingRewards(agent1.address, USDT.target);

      const sellAmount = ethers.parseEther("5000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await forwardBlockTimestamp(10);
      await smart.connect(seller).confirmOrder(orderId);

      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const operatorBalanceAfter = await smart.pendingRewards(operatorWallet, USDT.target);
      const globalShareBalanceAfter = await smart.pendingRewards(globalShareWallet, USDT.target);
      const agent1BalanceAfter = await smart.pendingRewards(agent1.address, USDT.target);

      expect(communityBalanceAfter - communityBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(operatorBalanceAfter - operatorBalanceBefore).to.equal(ethers.parseEther("10"));
      expect(globalShareBalanceAfter - globalShareBalanceBefore).to.equal(ethers.parseEther("5"));
      expect(agent1BalanceAfter - agent1BalanceBefore).to.equal(ethers.parseEther("25"))
    });

    it('test case 3-3-3', async function() {
      const { smart, operator, seller, buyer, USDT, agent1, agent2, agent3, agent4, agentManager } =  await loadFixture(deployBeeSmarts);
      const agent5 = {address: '0x81bD01D0A9E8e8E40FAf22B779Bb21BaFbf8f7AC'};
      const agent6 = {address: '0x45b3BDbb5dCE0F251280Ad19A50e31568cF3B0BC'};

      // await agentManager.connect(owner).addTopAgent(agent1.address, 3, true);
      await agentManager.connect(operator).addAgent(agent1.address, agent2.address, 3, true, 'agent 2');
      await agentManager.connect(operator).addAgent(agent1.address, agent4.address, 3, true, 'agent 4');
      await agentManager.connect(operator).addAgent(agent2.address, agent3.address, 3, true, 'agent 3');
      await agentManager.connect(operator).addAgent(agent4.address, agent5.address, 3, true, 'agent 5');
      await agentManager.connect(operator).addAgent(agent4.address, agent6.address, 3, true, 'agent 6');

      const agent3Id = await agentManager.getAgentId(agent3.address);
      const agent6Id = await agentManager.getAgentId(agent6.address);

      await smart.connect(seller).bindRelationship(agent3Id);
      await smart.connect(buyer).bindRelationship(agent6Id);

      const sellAmount = ethers.parseEther("1000");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();
      await smart.connect(seller).confirmOrder(orderId);

      expect(await smart.pendingRewards(agent3.address, USDT.target)).to.equal(ethers.parseEther('2.5'));
      expect(await smart.pendingRewards(agent2.address, USDT.target)).to.equal(ethers.parseEther('0.5'));
      expect(await smart.pendingRewards(agent1.address, USDT.target)).to.equal(ethers.parseEther('0'));
      expect(await smart.pendingRewards(agent6.address, USDT.target)).to.equal(ethers.parseEther('2.5'));
      expect(await smart.pendingRewards(agent4.address, USDT.target)).to.equal(ethers.parseEther('0.5'));
    });
  });
});
