import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";

describe("BeeSmart", function () {
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

    return { smart, buyer, seller, USDC, USDT };
  }

  describe("orders", function () {
    it("make and confirm order", async function () {
      const { smart, seller, buyer, USDT } = await loadFixture(deployBeeSmarts);

      await smart.connect(seller).makeOrder(USDT.target, ethers.parseEther("180"), buyer.address);
      await smart.connect(seller).confirmOrder(1);

      console.log(`rewards: ${await smart.orderRewards(1)}`);
    });

  });

});
