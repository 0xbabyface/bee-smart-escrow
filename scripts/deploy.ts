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

  // const BeeSmart = await ethers.deployContract("BeeSmart", {gasPrice: 30000000000});
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

  // const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, adminship], {gasPrice: 30000000000});
  // await BeeSmartProxy.waitForDeployment();

  const BeeSmartProxy = {target: "0xe5390EB434544F55d0dFeEf1286B3FFA691e517F"}

  console.log(`BeeSmartProxy: ${BeeSmartProxy.target}`)

  // const AgentManager = await ethers.deployContract("AgentManager", {gasPrice: 30000000000});
  // await AgentManager.waitForDeployment();
  // const agentInit = AgentManager.interface.encodeFunctionData(
  //   'initialize',
  //   [BeeSmartProxy.target]
  // );
  // const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, adminship], {gasPrice: 30000000000});
  // await AgentManagerProxy.waitForDeployment();

  const AgentManagerProxy = {target: "0x8c07F390Ae85A757641365246BC5Df2596eEa712"}

  console.log(`AgentManagerProxy: ${AgentManagerProxy.target}`)

  // const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  // await BeeSmartLens.waitForDeployment();

  // const ManagementLens = await ethers.deployContract("ManagementLens", {gasPrice: 30000000000});
  // await ManagementLens.waitForDeployment();

  const ManagementLens = {target: "0xB01906Ae93B045CbFC91482A6D6E4F834811a8d7"};

  console.log(`ManagementLens: ${ManagementLens.target}`)

  // const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target], {gasPrice: 30000000000});
  // await Reputation.waitForDeployment();

  const Reputation = {target: "0x7df8865dAABB77a18BeDC1916d9E6F298f99928c"}

  console.log(`Reputation: ${Reputation.target}`)

  // const Reputation = {target: "0xd43c151fb76b9c648d1aafe4d58e47018940e065"}

  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  let tx = await smart.setReputation(Reputation.target, {gasPrice: 30000000000});
  await tx.wait();

  console.log(`hash: ${tx.hash}`)

  tx = await smart.setAgentManager(AgentManagerProxy.target, {gasPrice: 30000000000});
  await tx.wait();
  console.log(`hash: ${tx.hash}`)
  console.log(`
    {
      "BeeSmartProxy":      "${BeeSmartProxy.target}",
      "AgentManagerProxy":  "${AgentManagerProxy.target}",
      "Reputation":         "${Reputation.target}",
      "BeeSmart":           "${BeeSmart.target}",
      "ManagementLens":     "${ManagementLens.target}",
      "TestUSDT":           "${USDT.target}",
      "TestUSDC":           "${USDC.target}"
    }
  `)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
