import { ethers } from "hardhat";
import { contracts } from "./env";

async function main() {
  // const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  // await BeeSmartLens.waitForDeployment();

  // console.log(`BeeSmartLens deployed at: ${BeeSmartLens.target}`);

  const ManagementLens = await ethers.deployContract('ManagementLens');
  await ManagementLens.waitForDeployment();

  console.log(`getRole: ${await ManagementLens.getRole(contracts.BeeSmartProxy, "0x9681Dccbdd0cc9B00BF60673C2Bc5c76dbe35cdB")}`)

  console.log(`Management: ${ManagementLens.target}`);
}

main();