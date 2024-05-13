import { ethers } from "hardhat";

export async function deploy_logic(
  admins: string[],
  communities: string[],
  payTokens: string[],
  communityWallet: string,
  operatorWallet: string,
  globalShareWallet: string,
  upgradeAdmin: string
)
{
  const [owner] = await ethers.getSigners();
  console.log(`owner: ${owner.address}`);
  admins.push(owner.address);

  const BeeSmart = await ethers.deployContract("BeeSmart");
  await BeeSmart.waitForDeployment();

  // const BeeSmart = await ethers.getContractAt('BeeSmart', '0x9c6993d02f1ABb9DAb2988E6857C23fA65d805D1')

  console.log(`BeeSamrt Impl: ${BeeSmart.target}`);

  const initializeData = BeeSmart.interface.encodeFunctionData(
    "initialize",
    [
      admins,
      communities,
      payTokens,
      communityWallet,
      operatorWallet,
      globalShareWallet,
    ]
  );
  // console.log(`init: ${initializeData}`);

  const BeeSmartProxy = await ethers.deployContract("CommonProxy", [BeeSmart.target, initializeData, upgradeAdmin]);
  await BeeSmartProxy.waitForDeployment();
  // const BeeSmartProxy = await ethers.getContractAt('CommonProxy', '0xcA1aF3D66e0b35f00E3bEF5170678DB95678a30f')

  console.log(`BeeSmartProxy: ${BeeSmartProxy.target}`)

  const AgentManager = await ethers.deployContract("AgentManager");
  await AgentManager.waitForDeployment();
  // const AgentManager = await ethers.getContractAt('AgentManager', "0x7738AFE2Ba2C4E1555259CBfb5Bc6861Fef5b1c6");
  console.log(`AgentManagerImpl: ${AgentManager.target}`);

  const agentInit = AgentManager.interface.encodeFunctionData(
    'initialize',
    [BeeSmartProxy.target]
  );
  const AgentManagerProxy = await ethers.deployContract("CommonProxy", [AgentManager.target, agentInit, upgradeAdmin]);
  await AgentManagerProxy.waitForDeployment();
  // const AgentManagerProxy = await ethers.getContractAt('CommonProxy', '0xF975c48E85Dde3F57D3e0a113940001F450bc762');
  console.log(`AgentManagerProxy: ${AgentManagerProxy.target}`)

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();
  // const BeeSmartLens = await ethers.getContractAt('BeeSmartLens', '0x592FAA5167665b8C407976eBe4A2Be69634E6a7f');
  console.log(`BeeSmartLens: ${BeeSmartLens.target}`);

  const ManagementLens = await ethers.deployContract("ManagementLens");
  await ManagementLens.waitForDeployment();
  // const ManagementLens = await ethers.getContractAt('ManagementLens', '0x2a25C082933A2317F34847350D24A911787AD057');
  console.log(`ManagementLens: ${ManagementLens.target}`)

  const Reputation = await ethers.deployContract("Reputation", [BeeSmartProxy.target]);
  await Reputation.waitForDeployment();
  // const Reputation = await ethers.getContractAt('Reputation', '0xc8A12f8DA8a073C90961d8d3b27477c0aC841DE7');
  console.log(`Reputation: ${Reputation.target}`);
  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  let tx: any;
  tx = await smart.setReputation(Reputation.target);
  console.log(`tx: ${tx.hash}`);
  await tx.wait();

  tx = await smart.setAgentManager(AgentManagerProxy.target);
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