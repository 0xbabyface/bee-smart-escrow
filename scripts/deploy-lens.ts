import { ethers } from "hardhat";
import { contracts } from "./env";

async function main() {
  // const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  // await BeeSmartLens.waitForDeployment();

  // console.log(`BeeSmartLens deployed at: ${BeeSmartLens.target}`);

  const ManagementLens = await ethers.deployContract('ManagementLens');
  await ManagementLens.waitForDeployment();

  // const ManagementLens = await ethers.getContractAt('ManagementLens', contracts.ManagementLens)
  console.log(`getAgentInfo: ${await ManagementLens.getAgentInfoByOperator(contracts.BeeSmartProxy, "0xb5DFdD7B4d67ae75D5A800B490ee4356e2DC1f97")}`)
  // console.log(`getRole: ${await ManagementLens.getRole(contracts.BeeSmartProxy, "0x22bd48Eb5eeEbA9B9A2FE4F2Fd8983c31B3AC886")}`)

  console.log(`Management: ${ManagementLens.target}`);
}

main();