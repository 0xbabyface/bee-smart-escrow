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
  const initializeData = BeeSmart.interface.encodeFunctionData("initialize", [[owner.address], [owner.address]])

  const BeeSmartProxy = await ethers.deployContract("BeeSmartProxy", [BeeSmart.target, initializeData, owner.address]);
  await BeeSmartProxy.waitForDeployment();

  const BeeSmartLens = await ethers.deployContract("BeeSmartLens");
  await BeeSmartLens.waitForDeployment();

  // to initialize system
  const smart = await ethers.getContractAt("BeeSmart", BeeSmartProxy.target);
  await smart.setRelationship(Relationship.target);
  await smart.setReputation(Reputation.target);
  // await smart.setCommunityFeeRatio(
  //   ethers.parseEther("0.03"),  // community fee ratio
  //   ethers.parseEther("1.0"),   // buyer charged
  //   ethers.parseEther("0.0")    // seller charged
  // );

  // await smart.setRewardFeeRatio(
  //   ethers.parseEther("0.7"),  // reward ratio for buyer
  //   ethers.parseEther("0.3")   // reward ratio for seller
  // );

  // await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy
  // await smart.setRebateRatio(ethers.parseEther("0.1"));   // rebate ratio 10%

  // await smart.setOrderStatusDurationSec(30 * 60);  // order wait for 30 minutes then can disputing
  await smart.setCommunityWallet(owner.address);

  await Candy.setMinter(BeeSmartProxy.target, true);

  // const USDT = await ethers.deployContract("TestUSDT");
  // await USDT.waitForDeployment();

  // const USDC = await ethers.deployContract("TestUSDC");
  // await USDC.waitForDeployment();
  const USDT = {target: "0x8021B51333Cb1C387ae6c4a7f1a43779DE602ec1"}
  const USDC = {target: "0x1c2D7E574F25E5D31E802763127016C5aD66260C"}


  // add support tokens
  await smart.addSupportTokens([USDT.target, USDC.target, Candy.target]);

  console.log(`
  Bee Smart System Deployed:
    Candy:          ${Candy.target}
    Reputation:     ${Reputation.target}
    Relationship:   ${Relationship.target}
    Rebate:         ${Rebate.target}
    BeeSmart:       ${BeeSmart.target}
    BeeSmartProxy:  ${BeeSmartProxy.target}
    BeeSmartLens:   ${BeeSmartLens.target}
    TestUSDT:       ${USDT.target}
    TestUSDC:       ${USDC.target}
  `)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
