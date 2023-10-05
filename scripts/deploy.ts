import { ethers } from "hardhat";

async function main() {

  const Reputation = await ethers.deployContract("Reputation");
  await Reputation.waitForDeployment();

  const Relationship = await ethers.deployContract("Relationship");
  await Relationship.waitForDeployment();

  const Rebate = await ethers.deployContract("Rebate");
  await Rebate.waitForDeployment();

  const Candy = await ethers.deployContract("Candy");
  await Candy.waitForDeployment();

  const BeeSmart = await ethers.deployContract("BeeSmart");
  await BeeSmart.waitForDeployment();

  const [owner] = await ethers.getSigners();
  const initializeData = BeeSmart.interface.encodeFunctionData("initialize", [[owner.address], []])

  const BeeSmartProxy = await ethers.deployContract("BeeSmartProxy", [BeeSmart.target, initializeData, owner.address]);
  await BeeSmartProxy.waitForDeployment();

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();

  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  await smart.setRelationship(Relationship.target);
  await smart.setReputation(Reputation.target);
  await smart.setRebate(Rebate.target);

  await Candy.setMinter(BeeSmartProxy.target, true);

  console.log(`
  Bee Smart System Deployed:
    Candy:          ${Candy.target}
    Reputation:     ${Reputation.target}
    Relationship:   ${Relationship.target}
    Rebate:         ${Rebate.target}
    BeeSmart:       ${BeeSmart.target}
    BeeSmartProxy:  ${BeeSmartProxy.target}
    BeeSmartLens:   ${BeeSmartLens.target}
  `)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
