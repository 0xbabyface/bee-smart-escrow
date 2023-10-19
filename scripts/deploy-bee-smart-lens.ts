import { ethers } from "hardhat";

async function main() {
  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();

  console.log(`BeeSmartLens deployed at: ${BeeSmartLens.target}`);
}

main();