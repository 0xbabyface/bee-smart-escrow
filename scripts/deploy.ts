import { ethers } from "hardhat";

let smartAdmins: string[] = [];
let smartCommunities: string[] = [];
let payTokens: string[] = [];
let communityWallet = "";
let agentWallet = "";
let globalShareWallet = "";
let agentManagerOwner = "";
let adminship = "";

async function main() {
  const [owner] = await ethers.getSigners();
  const USDT = await ethers.deployContract("TestUSDT");
  await USDT.waitForDeployment();

  const USDC = await ethers.deployContract("TestUSDC");
  await USDC.waitForDeployment();

  // const USDT = {target: "0x8021B51333Cb1C387ae6c4a7f1a43779DE602ec1"}
  // const USDC = {target: "0x1c2D7E574F25E5D31E802763127016C5aD66260C"}

  // ---- for test ------
  smartAdmins.push(owner.address);
  smartCommunities.push(owner.address);
  payTokens.push(USDT.target as string);
  payTokens.push(USDC.target as string);

  communityWallet = owner.address;
  agentWallet = owner.address;
  globalShareWallet = owner.address;
  agentManagerOwner = owner.address;
  adminship = owner.address;
  // ------------------

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
  const initializeData = BeeSmart.interface.encodeFunctionData(
    "initialize",
    [
      smartAdmins,
      smartCommunities,
      payTokens,
      communityWallet,
      agentWallet,
      globalShareWallet,
      AgentManagerProxy.target
    ]
  );

  const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, adminship]);
  await BeeSmartProxy.waitForDeployment();

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();

  const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target]);
  await Reputation.waitForDeployment();

  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  await smart.setReputation(Reputation.target);

  console.log(`
    {
      "BeeSmartProxy":      "${BeeSmartProxy.target}",
      "AgentManagerProxy":  "${AgentManagerProxy.target}",
      "Reputation":         "${Reputation.target}",
      "BeeSmart":           "${BeeSmart.target}",
      "BeeSmartLens":       "${BeeSmartLens.target}",
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
