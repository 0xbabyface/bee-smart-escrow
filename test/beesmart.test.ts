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
    const agent1Id = await cc.agentManager.getAgentId(cc.agent1.address);

    await cc.smart.connect(cc.buyer).bindRelationship(agent1Id);
    await cc.smart.connect(cc.seller).bindRelationship(agent1Id);

    contracts = cc;
  })

  afterEach(async () => {
    // console.log("after each")
  })

  describe("normal procedures of order", function () {

    it("make order over reputations", async function () {
      const { smart, seller, buyer, USDT, Reputation } = contracts;

      const sellerReputation = await Reputation.reputationPoints(seller.address);
      const buyerReputation = await Reputation.reputationPoints(buyer.address);

      const sellAmount = sellerReputation + 1n;
      await expect(smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address))
        .to
        .revertedWith("not enough reputation for buyer");
    });

    it("normal make and confirm order", async function () {
      const { smart, seller, buyer, USDT, communityWallet, Reputation } = contracts;

      const communityBalanceBefore = await smart.pendingRewards(communityWallet, USDT.target);
      const sellerBalanceBefore = await USDT.balanceOf(seller.address);
      const buyerBalanceBefore = await USDT.balanceOf(buyer.address);
      const sellerReputationBefore = await Reputation.reputationPoints(seller.address);
      const buyerReputationBefore = await Reputation.reputationPoints(buyer.address);
      const sellerAirdropBefore = await smart.airdropPoints(seller.address);
      const buyerAirdropBefore = await smart.airdropPoints(buyer.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const sellerBalance = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore - sellerBalance).to.equal(sellAmount + await sellerFee(smart, sellAmount));

      const buyerOrdersLength = await smart.getLengthOfBuyOrders(buyer.address);
      const sellerOrdersLength = await smart.getLengthOfSellOrders(seller.address);

      expect(buyerOrdersLength).to.equal(sellerOrdersLength);

      const orderId = await smart.totalOrdersCount();
      expect(await smart.buyOrdersOfUser(buyer.address, buyerOrdersLength - 1n)).to.equal(orderId);
      expect(await smart.sellOrdersOfUser(seller.address, sellerOrdersLength - 1n)).to.equal(orderId);
      // to check order status is correct
      let order = await smart.orders(orderId);
      expect(order[0]).to.equal(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[2]).to.equal(USDT.target);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[4]).to.equal(buyer.address);
      expect(order[5]).to.equal(seller.address);
      expect(order[6]).to.equal(Status.NORMAL);
      expect(order[7]).to.equal(Status.UNKNOWN);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);

      await smart.connect(seller).confirmOrder(orderId);
      order = await smart.orders(orderId);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.CONFIRMED);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(await buyerFee(smart, sellAmount));

      // to check reward amount is correct
      let rewards = await smart.orderRewards(orderId);
      expect(rewards[0]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[1]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[2]).to.equal(await reputationRewards(smart, sellAmount));
      expect(rewards[3]).to.equal(await reputationRewards(smart, sellAmount));

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      const buyerBalanceAfter = await USDT.balanceOf(buyer.address);
      const communityBalanceAfter = await smart.pendingRewards(communityWallet, USDT.target);
      const sellerReputationAfter = await Reputation.reputationPoints(seller.address);
      const buyerReputationAfter = await Reputation.reputationPoints(buyer.address);
      const buyerAirdropAfter = await smart.airdropPoints(buyer.address);
      const sellerAirdropAfter = await smart.airdropPoints(seller.address);

      const communityF = await communityFee(smart, sellAmount);
      // to check balance of sell, buyer, community wallet
      expect(sellerBalanceBefore - sellerBalanceAfter).to.equal(sellAmount + await sellerFee(smart, sellAmount));
      expect(buyerBalanceAfter - buyerBalanceBefore).to.equal(sellAmount - await buyerFee(smart, sellAmount));
      expect(communityBalanceAfter - communityBalanceBefore).to.equal(communityF);
      expect(sellerReputationAfter - sellerReputationBefore).to.equal(await reputationRewards(smart, sellAmount));
      expect(buyerReputationAfter - buyerReputationBefore).to.equal(await reputationRewards(smart, sellAmount));
      expect(sellerAirdropAfter - sellerAirdropBefore).to.equal(await airdropRewards(smart, sellAmount));
      expect(buyerAirdropAfter - buyerAirdropBefore).to.equal(await airdropRewards(smart, sellAmount));
    });

    it("make and adjust order", async function () {
      const { smart, seller, buyer, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const orderId = await smart.totalOrdersCount();
      const adjustAmount = ethers.parseEther("35");
      await expect(smart.connect(seller).adjustOrder(orderId, adjustAmount)).to.revertedWith("only buyer allowed");

      await smart.connect(buyer).adjustOrder(orderId, adjustAmount);
      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(adjustAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.ADJUSTED);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, adjustAmount));
      expect(order[9]).to.equal(0n);

      let adjustInfo = await smart.adjustedOrder(orderId);
      expect(adjustInfo[0]).to.equal(sellAmount);
      expect(adjustInfo[1]).to.equal(adjustAmount);
    });

    it("make and adjust to cancel order", async function () {
      const { smart, seller, buyer, USDT } = contracts;

      const sellerBalanceBefore = await USDT.balanceOf(seller.address);
      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const sellerBalance = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore - sellerBalance).to.equal(sellAmount + await sellerFee(smart, sellAmount));

      const orderId = await smart.totalOrdersCount();
      const adjustAmount = 0n;

      await smart.connect(buyer).adjustOrder(orderId, adjustAmount);
      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.CANCELLED);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, adjustAmount));
      expect(order[9]).to.equal(0n);

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore).to.equal(sellerBalanceAfter);
    });

    it("seller dispute and recall", async function () {
      const { smart, seller, buyer, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(seller).sellerDispute(orderId)).to.revertedWith("status in waiting time");
      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(buyer).sellerDispute(orderId)).to.revertedWith("only seller allowed");

      await expect(smart.connect(seller).sellerRecallDispute(orderId)).to.revertedWith("can not recall");

      await smart.connect(seller).sellerDispute(orderId);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.SELLERDISPUTE);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);

      await forwardBlockTimestamp(60);

      await smart.connect(seller).sellerRecallDispute(orderId);
      order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.NORMAL);
      expect(order[7]).to.equal(Status.SELLERDISPUTE);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });

    it("buyer dispute and recall", async function () {
      const { smart, seller, buyer, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(buyer).buyerDispute(orderId)).to.revertedWith("status in waiting time");
      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(seller).buyerDispute(orderId)).to.revertedWith("only buyer allowed");

      await expect(smart.connect(buyer).buyerRecallDispute(orderId)).to.revertedWith("can not recall");

      await smart.connect(buyer).buyerDispute(orderId);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.BUYERDISPUTE);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);

      await forwardBlockTimestamp(60);

      await smart.connect(buyer).buyerRecallDispute(orderId);
      order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.NORMAL);
      expect(order[7]).to.equal(Status.BUYERDISPUTE);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });


    it("seller dispute and dispute again", async function () {
      const { smart, seller, buyer, USDT } = contracts;
      const sellerBalanceBefore = await USDT.balanceOf(seller.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(seller).sellerDispute(orderId)).to.revertedWith("status in waiting time");
      await forwardBlockTimestamp(10 * 60 + 1);
      await smart.connect(seller).sellerDispute(orderId);

      await forwardBlockTimestamp(20 * 60);
      await expect(smart.connect(seller).sellerDispute(orderId)).to.revertedWith("status in waiting time");

      await forwardBlockTimestamp(20 * 60);
      await smart.connect(seller).sellerDispute(orderId); // dispute again

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.CONFIRMED);
      expect(order[7]).to.equal(Status.SELLERDISPUTE);
      expect(order[8]).to.equal(0n);
      expect(order[9]).to.equal(0n);

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore).to.equal(sellerBalanceAfter);
    });

    it("buyer dispute and dispute again", async function () {
      const { smart, seller, buyer, USDT } = contracts;
      const buyerBalanceBefore = await USDT.balanceOf(buyer.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);

      await forwardBlockTimestamp(20 * 60);
      await expect(smart.connect(buyer).buyerDispute(orderId)).to.revertedWith("status in waiting time");

      await forwardBlockTimestamp(20 * 60);
      await smart.connect(buyer).buyerDispute(orderId); // dispute again

      const buyerF = await buyerFee(smart, sellAmount);
      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.CONFIRMED);
      expect(order[7]).to.equal(Status.BUYERDISPUTE);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(buyerF);

      const buyerBalanceAfter = await USDT.balanceOf(buyer.address);
      expect(buyerBalanceAfter - buyerBalanceBefore).to.equal(sellAmount - buyerF);
    });

    it("seller dispute then buyer dispute", async function () {
      const { smart, seller, buyer, USDT } = contracts;
      const sellerBalanceBefore = await USDT.balanceOf(seller.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(seller).sellerDispute(orderId);
      await smart.connect(buyer).buyerDispute(orderId);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.LOCKED);
      expect(order[7]).to.equal(Status.SELLERDISPUTE);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });

    it("buyer dispute then seller dispute", async function () {
      const { smart, seller, buyer, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);
      await smart.connect(seller).sellerDispute(orderId);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.LOCKED);
      expect(order[7]).to.equal(Status.BUYERDISPUTE);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });

    it("community decide seller win for locked order", async function () {
      const { smart, seller, buyer, communitier, USDT, Reputation } = contracts;

      const sellerBalanceBefore = await USDT.balanceOf(seller.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);
      await smart.connect(seller).sellerDispute(orderId);

      await smart.connect(communitier).communityDecide(orderId, 1);

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore).to.equal(sellerBalanceAfter);

      const buyerReputationPoints = await Reputation.reputationPoints(buyer.address);
      expect(buyerReputationPoints).to.equal(0n);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.SELLERWIN);
      expect(order[7]).to.equal(Status.LOCKED);
      expect(order[8]).to.equal(0n);
      expect(order[9]).to.equal(0n);
    });

    it("community decide buyer win for locked order", async function () {
      const { smart, seller, buyer, communitier, USDT, Reputation } = contracts;

      const buyerBalanceBefore = await USDT.balanceOf(buyer.address);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);
      await smart.connect(seller).sellerDispute(orderId);

      await smart.connect(communitier).communityDecide(orderId, 0);

      const buyerBalanceAfter = await USDT.balanceOf(buyer.address);
      expect(buyerBalanceAfter - buyerBalanceBefore).to.equal(sellAmount - await buyerFee(smart, sellAmount));

      const sellerReputationPoints = await Reputation.reputationPoints(seller.address);
      expect(sellerReputationPoints).to.equal(0n);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.BUYERWIN);
      expect(order[7]).to.equal(Status.LOCKED);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(await buyerFee(smart, sellAmount));
    });

    it("community decide draw for locked order", async function () {
      const { smart, seller, buyer, communitier, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);
      await smart.connect(seller).sellerDispute(orderId);

      await smart.connect(communitier).communityDecide(orderId, 2);

      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.NORMAL);
      expect(order[7]).to.equal(Status.LOCKED);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });

    it("new order while locked orders in progress", async function () {
      const { smart, seller, buyer, communitier, USDT } = contracts;

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(30 * 60 + 1);
      await smart.connect(buyer).buyerDispute(orderId);
      await smart.connect(seller).sellerDispute(orderId);
      // can not make new order while locked order in progress
      await expect(smart.connect(seller).makeOrder(USDT.target, sellAmount, communitier.address)).to.rejectedWith("seller has locked order")
      await expect(smart.connect(communitier).makeOrder(USDT.target, sellAmount, buyer.address)).to.rejectedWith("buyer has locked order")

      await smart.connect(communitier).communityDecide(orderId, 2);
      // community decide the locked order, can make new order again
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const newOrderId = await smart.totalOrdersCount();
      let order = await smart.orders(newOrderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.NORMAL);
      expect(order[7]).to.equal(Status.UNKNOWN);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount));
      expect(order[9]).to.equal(0n);
    });
  });
});
