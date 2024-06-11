import { ethers } from "hardhat";

let smartAdmins: string[] = [];
let smartCommunities: string[] = [];
let payTokens: string[] = [];
let communityWallet = "";
let operatorWallet = "";
let globalShareWallet = "";
let agentManagerOwner = "";
let adminship = "";

async function main() {
  const [owner] = await ethers.getSigners();
  console.log(`owner: ${owner.address}`);
  // const USDT = await ethers.deployContract("TestUSDT");
  // await USDT.waitForDeployment();

  // console.log(`USDT: ${USDT.target}`)

  // const USDC = await ethers.deployContract("TestUSDC");
  // await USDC.waitForDeployment();
  // console.log(`USDC: ${USDC.target}`)

  const USDT = {target: "0x66803B16Cfcd7AF1B49F9D584C654cdcfC72Bf51"}
  const USDC = {target: "0x94a1A696E7Fb537B55ea2EDC135c0744637b79e7"}

  // ---- for test ------
  smartAdmins.push(owner.address);
  smartCommunities.push(owner.address);
  payTokens.push(USDT.target as string);
  payTokens.push(USDC.target as string);

  communityWallet = owner.address;
  operatorWallet = owner.address;
  globalShareWallet = owner.address;
  agentManagerOwner = owner.address;
  adminship = owner.address;
  // ------------------

  // const BeeSmart = await ethers.deployContract("BeeSmart");
  // await BeeSmart.waitForDeployment();
  // const initializeData = BeeSmart.interface.encodeFunctionData(
  //   "initialize",
  //   [
  //     smartAdmins,
  //     smartCommunities,
  //     payTokens,
  //     communityWallet,
  //     globalShareWallet,
  //   ]
  // );

  // const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, adminship]);
  // await BeeSmartProxy.waitForDeployment();

  const BeeSmartProxy = {target: "0x856B6bf21f3CdE40117B7E9D4bc5c82A7a924228"}

  console.log(`BeeSmartProxy: ${BeeSmartProxy.target}`)

  // const AgentManager = await ethers.deployContract("AgentManager");
  // await AgentManager.waitForDeployment();
  // const agentInit = AgentManager.interface.encodeFunctionData(
  //   'initialize',
  //   [BeeSmartProxy.target]
  // );
  // const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, adminship]);
  // await AgentManagerProxy.waitForDeployment();

  const AgentManagerProxy = {target: "0xEDcAd7cCc2c3E8CadF02E7e49cc6e2a847499B27"}

  // console.log(`AgentManagerProxy: ${AgentManagerProxy.target}`)

  // const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  // await BeeSmartLens.waitForDeployment();

  // const ManagementLens = await ethers.deployContract("ManagementLens");
  // await ManagementLens.waitForDeployment();

  // const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target]);
  // await Reputation.waitForDeployment();

  const Reputation = {target: "0xd43c151fb76b9c648d1aafe4d58e47018940e065"}

  // console.log(`Reputation: ${Reputation.target}`);

  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  let tx = await smart.setReputation(Reputation.target);
  await tx.wait();

  console.log(`hash: ${tx.hash}`)

  tx = await smart.setAgentManager(AgentManagerProxy.target);
  await tx.wait();
  console.log(`hash: ${tx.hash}`)
  // console.log(`
  //   {
  //     "BeeSmartProxy":      "${BeeSmartProxy.target}",
  //     "AgentManagerProxy":  "${AgentManagerProxy.target}",
  //     "Reputation":         "${Reputation.target}",
  //     "BeeSmart":           "${BeeSmart.target}",
  //     "BeeSmartLens":       "${BeeSmartLens.target}",
  //     "ManagementLens":     "${ManagementLens.target}",
  //     "TestUSDT":           "${USDT.target}",
  //     "TestUSDC":           "${USDC.target}"
  //   }
  // `)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
