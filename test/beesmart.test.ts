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
      ethers.parseEther("1.0"),   // buyer charged
      ethers.parseEther("0.0")    // seller charged
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
    await smart.addSupportTokens([USDT.target, USDC.target, Candy.target]);
    await smart.setCommunityWallet(owner.address);
    await smart.setFinancialWallet(owner.address);
    await smart.setRewardToken(Candy.target);
    await Candy.connect(owner).approve(smart.target, ethers.parseEther("1000000000000"));

    return { smart, buyer, seller, USDC, USDT };
  }

  async function buyerFee(smart: BeeSmart, sellAmount: bigint) {
    const cr = await smart.communityFeeRatio();
    const r = await smart.chargesBaredBuyerRatio();
    return cr * sellAmount * r / Precision / Precision;
  }

  async function sellerFee(smart: BeeSmart, sellAmount: bigint) {
    const cr = await smart.communityFeeRatio();
    const r = await smart.chargesBaredSellerRatio();
    return cr * sellAmount * r / Precision / Precision;
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
    console.log("after each")
  })

  describe("orders", function () {
    it("make and confirm order", async function () {
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      const sellAmount = ethers.parseEther("180");
      await smart.connect(seller).makeOrder(USDT.target, sellAmount, buyer.address);
      const buyerOrdersLength = await smart.getLengthOfBuyOrders(buyer.address);
      const sellerOrdersLength = await smart.getLengthOfSellOrders(seller.address);

      expect(buyerOrdersLength).to.equal(sellerOrdersLength);

      const orderId = await smart.totalOrdersCount();
      expect(await smart.buyOrdersOfUser(buyer.address, buyerOrdersLength - 1n)).to.equal(orderId);
      expect(await smart.sellOrdersOfUser(seller.address, sellerOrdersLength - 1n)).to.equal(orderId);

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

      let rewards = await smart.orderRewards(orderId);
      expect(rewards[0]).to.equal(await buyerRewards(smart, sellAmount));
      expect(rewards[1]).to.equal(await sellerRewards(smart, sellAmount));
      expect(rewards[2]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[3]).to.equal(await airdropRewards(smart, sellAmount));
      expect(rewards[4]).to.equal(await reputationRewards(smart, sellAmount));
      expect(rewards[5]).to.equal(await reputationRewards(smart, sellAmount));

      // calculate rebates
    });

  });

});
