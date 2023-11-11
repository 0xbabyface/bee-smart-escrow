import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { BeeSmart } from "../typechain-types";

enum Status {
  UNKNOWN = 0,       // occupate the default status
  NORMAL,        // normal status
  ADJUSTED,      // buyer adjuste amount
  CONFIRMED,     // seller confirmed
  CANCELLED,     // buyer adjust amount to 0
  SELLERDISPUTE, // seller dispute
  BUYERDISPUTE,  // buyer dispute
  LOCKED,        // both buyer and seller disputed
  RECALLED       // seller dispute and buyer no response
}
const Precision = ethers.parseEther("1");

describe("BeeSmart", async function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployBeeSmarts() {
    const Reputation = await ethers.deployContract("Reputation");
    await Reputation.waitForDeployment();

    const Relationship = await ethers.deployContract("Relationship");
    await Relationship.waitForDeployment();

    const Rebate = await ethers.deployContract("Rebate");
    await Rebate.waitForDeployment();

    const Candy = await ethers.deployContract("Candy");
    await Candy.waitForDeployment();

    const BeeSmart = await ethers.deployContract("BeeSmart");
    await BeeSmart.waitForDeployment();

    const [owner, buyer, seller] = await ethers.getSigners();
    const initializeData = BeeSmart.interface.encodeFunctionData("initialize", [[owner.address], []])
    const BeeSmartProxy = await ethers.deployContract("BeeSmartProxy", [BeeSmart.target, initializeData, owner.address]);
    await BeeSmartProxy.waitForDeployment();

    const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
    await BeeSmartLens.waitForDeployment();

    // to initialize system
    const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
    await smart.setRelationship(Relationship.target);
    await smart.setReputation(Reputation.target);
    await smart.setRebate(Rebate.target);
    await smart.setCommunityFeeRatio(
      ethers.parseEther("0.03"),  // community fee ratio
      ethers.parseEther("0.8"),   // buyer charged
      ethers.parseEther("0.2")    // seller charged
    );

    await smart.setRewardFeeRatio(
      ethers.parseEther("0.03"),  // reward ratio for buyer
      ethers.parseEther("0.03")   // reward ratio for seller
    );

    await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy
    await smart.setRebateRatio(ethers.parseEther("0.1"));   // rebate ratio 10%

    await smart.setOrderStatusDurationSec(30 * 60);  // order wait for 30 minutes then can disputing

    await Candy.setMinter(BeeSmartProxy.target, true);

    const USDT = await ethers.deployContract("TestUSDT");
    await USDT.waitForDeployment();

    const USDC = await ethers.deployContract("TestUSDC");
    await USDC.waitForDeployment();

    await USDC.mint(seller.address, ethers.parseEther("10000000"));
    await USDT.mint(seller.address, ethers.parseEther("10000000"));

    await USDC.connect(seller).approve(smart.target, ethers.parseEther("1000000000"));
    await USDT.connect(seller).approve(smart.target, ethers.parseEther("1000000000"));

    await Relationship.connect(seller).bind(100000000, 0);
    await Relationship.connect(buyer).bind(100000000, 0);

    // add support tokens
    const communityWallet = owner.address;
    const financialWallet = owner.address;
    await smart.addSupportTokens([USDT.target, USDC.target, Candy.target]);
    await smart.setCommunityWallet(communityWallet);
    await smart.setFinancialWallet(financialWallet);
    await smart.setRewardToken(Candy.target);
    await Candy.connect(owner).approve(smart.target, ethers.parseEther("1000000000000"));

    return { smart, buyer, seller, USDC, USDT, Reputation, Relationship, communityWallet, financialWallet };
  }

  async function forwardBlockTimestamp(forwardSecs: number) {
    await ethers.provider.send("evm_increaseTime", [forwardSecs]);
    await ethers.provider.send("evm_mine", []);
  }

  async function communityFee(smart: BeeSmart, sellAmount: bigint) {
    const cr = await smart.communityFeeRatio();
    return cr * sellAmount / Precision;
  }

  async function rebateFee(smart: BeeSmart, sellAmount: bigint) {
    const cr = await smart.rebateRatio();
    return await communityFee(smart, sellAmount) * cr / Precision;
  }

  async function buyerFee(smart: BeeSmart, sellAmount: bigint) {
    const r = await smart.chargesBaredBuyerRatio();
    return await communityFee(smart, sellAmount) * r / Precision ;
  }

  async function sellerFee(smart: BeeSmart, sellAmount: bigint) {
    const r = await smart.chargesBaredSellerRatio();
    return  await communityFee(smart, sellAmount) * r / Precision;
  }

  async function buyerRewards(smart: BeeSmart, sellAmount: bigint) {
    const r = await smart.rewardForBuyerRatio();
    return sellAmount * r / Precision;
  }

  async function sellerRewards(smart: BeeSmart, sellAmount: bigint) {
    const r = await smart.rewardForSellerRatio();
    return sellAmount * r / Precision;
  }

  async function reputationRewards(smart: BeeSmart, sellAmount: bigint) {
    const r = await smart.reputationRatio();
    return sellAmount * r / Precision;
  }

  async function airdropRewards(smart: BeeSmart, sellAmount: bigint) {
    return 1n;
  }

  afterEach(async () => {
    // console.log("after each")
  })

  describe("normal procedures of order", function () {

    it("make order over reputations", async function () {
      const { smart, seller, buyer, USDT, Reputation, Relationship } = await loadFixture(deployBeeSmarts);
      const sellerRelationId = await Relationship.getRelationId(seller.address);
      const buyerRelationId = await Relationship.getRelationId(buyer.address);

      const sellerReputation = await Reputation.reputationPoints(smart.target, sellerRelationId);
      const buyerReputation = await Reputation.reputationPoints(smart.target, buyerRelationId);

      const sellAmount = sellerReputation + 1n;
      await expect(smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address))
        .to
        .revertedWith("not enough reputation for buyer");
    });

    it("normal make and confirm order", async function () {
      const { smart, seller, buyer, USDT, communityWallet, Reputation, Relationship } = await loadFixture(deployBeeSmarts);
      const sellerRelationId = await Relationship.getRelationId(seller.address);
      const buyerRelationId = await Relationship.getRelationId(buyer.address);

      const sellerBalanceBefore = await USDT.balanceOf(seller.address);
      const buyerBalanceBefore = await USDT.balanceOf(buyer.address);
      const sellerReputationBefore = await Reputation.reputationPoints(smart.target, sellerRelationId);
      const buyerReputationBefore = await Reputation.reputationPoints(smart.target, buyerRelationId);
      const communityBalanceBefore = await USDT.balanceOf(communityWallet);
      const buyerAirdropBefore = await smart.airdropPoints(buyerRelationId);
      const sellerAirdropBefore = await smart.airdropPoints(sellerRelationId);

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
      expect(rewards[0]).to.equal(await buyerRewards(smart, sellAmount));
      expect(rewards[1]).to.equal(await sellerRewards(smart, sellAmount));
      expect(rewards[2]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[3]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[4]).to.equal(await reputationRewards(smart, sellAmount));
      expect(rewards[5]).to.equal(await reputationRewards(smart, sellAmount));

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      const buyerBalanceAfter = await USDT.balanceOf(buyer.address);
      const communityBalanceAfter = await USDT.balanceOf(communityWallet);
      const sellerReputationAfter = await Reputation.reputationPoints(smart.target, sellerRelationId);
      const buyerReputationAfter = await Reputation.reputationPoints(smart.target, buyerRelationId);
      const buyerAirdropAfter = await smart.airdropPoints(buyerRelationId);
      const sellerAirdropAfter = await smart.airdropPoints(sellerRelationId);

      const communityF = await communityFee(smart, sellAmount);
      const rebateF = await rebateFee(smart, sellAmount);
      // to check balance of sell, buyer, community wallet
      expect(sellerBalanceBefore - sellerBalanceAfter).to.equal(sellAmount + await sellerFee(smart, sellAmount));
      expect(buyerBalanceAfter - buyerBalanceBefore).to.equal(sellAmount - await buyerFee(smart, sellAmount));
      expect(communityBalanceAfter - communityBalanceBefore).to.equal(communityF - rebateF);
      expect(sellerReputationAfter - sellerReputationBefore).to.equal(await reputationRewards(smart, sellAmount));
      expect(buyerReputationAfter - buyerReputationBefore).to.equal(await reputationRewards(smart, sellAmount));
      expect(sellerAirdropAfter - sellerAirdropBefore).to.equal(await airdropRewards(smart, sellAmount));
      expect(buyerAirdropAfter - buyerAirdropBefore).to.equal(await airdropRewards(smart, sellAmount));

      // TODO: to check rebates for upper agents
    });

    it("make and adjust order", async function () {
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const orderId = await smart.totalOrdersCount();
      const adjustAmount = ethers.parseEther("35");
      await expect(smart.connect(seller).adjustOrder(orderId, adjustAmount)).to.revertedWith("only buyer allowed");

      await smart.connect(buyer).adjustOrder(orderId, adjustAmount);
      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount - adjustAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.ADJUSTED);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount - adjustAmount));
      expect(order[9]).to.equal(0n);

      let adjustInfo = await smart.adjustedOrder(orderId);
      expect(adjustInfo[0]).to.equal(sellAmount);
      expect(adjustInfo[1]).to.equal(sellAmount - adjustAmount);
    });

    it("make and adjust to cancel order", async function () {
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      const sellerBalanceBefore = await USDT.balanceOf(seller.address);
      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);

      const sellerBalance = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore - sellerBalance).to.equal(sellAmount + await sellerFee(smart, sellAmount));

      const orderId = await smart.totalOrdersCount();
      const adjustAmount = sellAmount;

      await smart.connect(buyer).adjustOrder(orderId, adjustAmount);
      let order = await smart.orders(orderId);
      expect(order[1]).to.equal(sellAmount);
      expect(order[3]).to.equal((await ethers.provider.getBlock('latest'))!.timestamp);
      expect(order[6]).to.equal(Status.CANCELLED);
      expect(order[7]).to.equal(Status.NORMAL);
      expect(order[8]).to.equal(await sellerFee(smart, sellAmount - adjustAmount));
      expect(order[9]).to.equal(0n);

      const sellerBalanceAfter = await USDT.balanceOf(seller.address);
      expect(sellerBalanceBefore).to.equal(sellerBalanceAfter);
    });

    it("seller dispute and recall", async function () {
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(seller).sellerDispute(orderId)).to.revertedWith("status in waiting time");
      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(buyer).sellerDispute(orderId)).to.revertedWith("only seller allowed");

      await expect(smart.connect(seller).sellerRecallDispute(orderId)).to.revertedWith("seller can not recall now");

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
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const orderId = await smart.totalOrdersCount();

      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(buyer).buyerDispute(orderId)).to.revertedWith("status in waiting time");
      await forwardBlockTimestamp(20 * 60); // forward 20minutes
      await expect(smart.connect(seller).buyerDispute(orderId)).to.revertedWith("only buyer allowed");

      await expect(smart.connect(buyer).buyerRecallDispute(orderId)).to.revertedWith("buyer can not recall now");

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

    });

    it("buyer dispute and dispute again", async function () {

    });

    it("seller dispute then buyer dispute", async function () {

    });

    it("buyer dispute then seller dispute", async function () {

    });

    it("community decide seller win for locked order", async function () {

    });

    it("community decide buyer win for locked order", async function () {

    });

    it("community decide draw for locked order", async function () {

    });

  });

});
