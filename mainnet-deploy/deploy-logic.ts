import { ethers } from "hardhat";

let smartAdmins: string[] = [
  "0xd2f79dd345b9f384cda0cf9240ae7b2cc13c7bac",
  "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD",
  "0xacB93B394cFc772C2273f54389c3081aa92Cf0C8"
];
let smartCommunities: string[] = [
  "0xd4a7b3c0a8356f4fe4d23d3913d4449002d9dd96",
];
let payTokens: string[] = [];
let communityWallet = "0xe45712f3a9f244e11fbf479d55756d137874e880";
let globalShareWallet = "0x813b6b94fe174d9ed8c7ed611a622f7c1c80580b";
let upgradeAdmin = "0xab0a4d730a00b75de677c54a32269a65eae0f704";

const gasPrice = ethers.parseUnits("0.018", "gwei");
export async function deploy_logic(
  admins: string[],
  communities: string[],
  payTokens: string[],
  communityWallet: string,
  globalShareWallet: string,
  upgradeAdmin: string
)
{
  const [owner] = await ethers.getSigners();
  console.log(`owner: ${owner.address}`);
  admins.push(owner.address);

  const BeeSmart = await ethers.deployContract("BeeSmart", {gasPrice});
  await BeeSmart.waitForDeployment();

  // const BeeSmart = await ethers.getContractAt('BeeSmart', '0x6d9264BB1b13739c6F13854595Cd4E90ED08cD18')

  console.log(`BeeSamrt Impl: ${BeeSmart.target}`);

  const initializeData = BeeSmart.interface.encodeFunctionData(
    "initialize",
    [
      admins,
      communities,
      payTokens,
      communityWallet,
      globalShareWallet,
    ]
  );
  // console.log(`init: ${initializeData}`);

  const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, upgradeAdmin], {gasPrice});
  await BeeSmartProxy.waitForDeployment();
  // const BeeSmartProxy = await ethers.getContractAt('CommonProxy', '0xcA1aF3D66e0b35f00E3bEF5170678DB95678a30f')

  console.log(`BeeSmartProxy: ${BeeSmartProxy.target}`)

  const AgentManager = await ethers.deployContract("AgentManager", {gasPrice});
  await AgentManager.waitForDeployment();
  // const AgentManager = await ethers.getContractAt('AgentManager', "0x7738AFE2Ba2C4E1555259CBfb5Bc6861Fef5b1c6");
  console.log(`AgentManagerImpl: ${AgentManager.target}`);

  const agentInit = AgentManager.interface.encodeFunctionData(
    'initialize',
    [BeeSmartProxy.target]
  );
  const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, upgradeAdmin], {gasPrice});
  await AgentManagerProxy.waitForDeployment();
  // const AgentManagerProxy = await ethers.getContractAt('CommonProxy', '0xF975c48E85Dde3F57D3e0a113940001F450bc762');
  console.log(`AgentManagerProxy: ${AgentManagerProxy.target}`)

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens", {gasPrice});
  await BeeSmartLens.waitForDeployment();
  // const BeeSmartLens = await ethers.getContractAt('BeeSmartLens', '0x592FAA5167665b8C407976eBe4A2Be69634E6a7f');
  console.log(`BeeSmartLens: ${BeeSmartLens.target}`);

  const ManagementLens = await ethers.deployContract("ManagementLens", {gasPrice});
  await ManagementLens.waitForDeployment();
  // const ManagementLens = await ethers.getContractAt('ManagementLens', '0x2a25C082933A2317F34847350D24A911787AD057');
  console.log(`ManagementLens: ${ManagementLens.target}`)

  const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target], {gasPrice});
  await Reputation.waitForDeployment();
  // const Reputation = await ethers.getContractAt('Reputation', '0xc8A12f8DA8a073C90961d8d3b27477c0aC841DE7');
  console.log(`Reputation: ${Reputation.target}`);
  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  let tx: any;
  tx = await smart.setReputation(Reputation.target, {gasPrice});
  console.log(`tx: ${tx.hash}`);
  await tx.wait();

  tx = await smart.setAgentManager(AgentManagerProxy.target, {gasPrice});
  await tx.wait();

  const AdminRole = await smart.AdminRole();
  tx = await smart.setRole(AdminRole, owner.address, false, {gasPrice});
  await tx.wait();

  console.log(`
    {
      "BeeSmartProxy":      "${BeeSmartProxy.target}",
      "AgentManagerProxy":  "${AgentManagerProxy.target}",
      "Reputation":         "${Reputation.target}",
      "BeeSmart":           "${BeeSmart.target}",
      "BeeSmartLens":       "${BeeSmartLens.target}",
      "ManagementLens":     "${ManagementLens.target}",
    }
  `)
}

deploy_logic(
  smartAdmins,
  smartCommunities,
  payTokens,
  communityWallet,
  globalShareWallet,
  upgradeAdmin
  ).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
