import { ethers } from "hardhat";
import { BeeSmart } from "../typechain-types";

export enum Status {
  UNKNOWN = 0,       // occupate the default status
  NORMAL,        // normal status
  ADJUSTED,      // buyer adjuste amount
  CONFIRMED,     // seller confirmed
  CANCELLED,     // buyer adjust amount to 0
  SELLERDISPUTE, // seller dispute
  BUYERDISPUTE,  // buyer dispute
  LOCKED,        // both buyer and seller disputed
  SELLERWIN,     // community decide seller win
  BUYERWIN       // community decide buyer win
}
export const Precision = ethers.parseEther("1");

export async function deployBeeSmarts() {
  const [owner, buyer, seller, communitier, agent4, agent3, agent2, agent1, globalShare] = await ethers.getSigners();

  const USDT = await ethers.deployContract("TestUSDT");
  await USDT.waitForDeployment();

  const USDC = await ethers.deployContract("TestUSDC");
  await USDC.waitForDeployment();

  let smartAdmins: string[] = [owner.address];
  let smartCommunities: string[] = [owner.address];
  let payTokens: string[] = [USDT.target as string, USDC.target as string];
  let communityWallet = communitier.address;
  let agentWallet = agent3.address;
  let globalShareWallet = globalShare.address;
  let agentManagerOwner = owner.address;
  let adminship = owner.address;

  const AgentManager = await ethers.deployContract("AgentManager");
  await AgentManager.waitForDeployment();
  const agentInit = AgentManager.interface.encodeFunctionData(
    'initialize',
    [agentManagerOwner]
  );
  const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, adminship]);
  await AgentManagerProxy.waitForDeployment();

  const BeeSmart = await ethers.deployContract("BeeSmart");
  await BeeSmart.waitForDeployment();

  const initializeData = BeeSmart.interface.encodeFunctionData("initialize", [
    smartAdmins,
    smartCommunities,
    payTokens,
    communityWallet,
    agentWallet,
    globalShareWallet,
    AgentManagerProxy.target
  ]);
  const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, adminship]);
  await BeeSmartProxy.waitForDeployment();

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();

  const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target]);
  await Reputation.waitForDeployment();
  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  await smart.setReputation(Reputation.target);

  await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy

  await smart.setRole(await smart.CommunityRole(), communitier.address, true);

  await smart.setOrderStatusDurationSec(30 * 60);  // order wait for 30 minutes then can disputing

  await USDC.mint(seller.address, ethers.parseEther("10000000"));
  await USDT.mint(seller.address, ethers.parseEther("10000000"));

  await USDC.connect(seller).approve(smart.target, ethers.parseEther("1000000000"));
  await USDT.connect(seller).approve(smart.target, ethers.parseEther("1000000000"));

  const agentManager = await ethers.getContractAt("AgentManager", AgentManagerProxy.target);
  await agentManager.addTopAgent(agent1.address, 3, true);

  return { smart, agentManager, buyer, seller, agent4, agent3, agent2, agent1, communitier, USDC, USDT, Reputation, communityWallet, agentWallet, globalShareWallet };
}

export async function forwardBlockTimestamp(forwardSecs: number) {
  await ethers.provider.send("evm_increaseTime", [forwardSecs]);
  await ethers.provider.send("evm_mine", []);
}

export async function communityFee(smart: BeeSmart, sellAmount: bigint) {
  const cr = await buyerFee(smart, sellAmount) + await sellerFee(smart, sellAmount);
  const r = await smart.communityFeeRatio();
  return cr * r / Precision;
}

export async function buyerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.chargesBaredBuyerRatio();
  return sellAmount * r / Precision;
}

export async function sellerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.chargesBaredSellerRatio();
  return sellAmount * r / Precision;
}

export async function agentSellerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.agentFeeRatio();
  return (await sellerFee(smart, sellAmount)) * r / Precision;
}

export async function agentBuyerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.agentFeeRatio();
  return (await buyerFee(smart, sellAmount)) * r / Precision;
}

export async function globalSellerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.globalShareFeeRatio();
  return (await sellerFee(smart, sellAmount)) * r / Precision
}

export async function globalBuyerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.globalShareFeeRatio();
  return (await buyerFee(smart, sellAmount)) * r / Precision
}

export async function sameLevelSellerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.sameLevelFeeRatio();
  return (await sellerFee(smart, sellAmount)) * r / Precision
}

export async function sameLevelBuyerFee(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.sameLevelFeeRatio();
  return (await buyerFee(smart, sellAmount)) * r / Precision
}

export async function reputationRewards(smart: BeeSmart, sellAmount: bigint) {
  const r = await smart.reputationRatio();
  return sellAmount * r / Precision;
}

export async function airdropRewards(smart: BeeSmart, sellAmount: bigint) {
  return 1n;
}