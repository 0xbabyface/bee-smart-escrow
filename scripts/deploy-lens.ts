import { ethers } from "hardhat";

async function main() {
  // const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  // await BeeSmartLens.waitForDeployment();

  // console.log(`BeeSmartLens deployed at: ${BeeSmartLens.target}`);

  const ManagementLens = await ethers.deployContract('ManagementLens');
  await ManagementLens.waitForDeployment();

  console.log(`Management: ${ManagementLens.target}`);
}

main();