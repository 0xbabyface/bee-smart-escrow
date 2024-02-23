import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const [owner] = await ethers.getSigners();
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);
  const agentManager = await ethers.getContractAt('AgentManager', contracts.AgentManagerProxy);
  console.log(`owner address: ${owner.address}`);
  // console.log(`2hasRole: ${await smart.hasRole(await smart.AdminRole(), owner.address)}`)
  /* reset Reputation */
  // const r = await ethers.deployContract("Reputation");
  // await r.waitForDeployment();
  // console.log('r: ', r.target);
  // let tx = await smart.setReputation(r.target);
  // await tx.wait();

  /* reset community wallet*/
  let tx: any;
  // await smart.setCommunityWallet("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
  // await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy
  // tx = await smart.setOrderStatusDurationSec(60);  // order wait for 30 minutes then can disputing

  // edmond settings
  tx =  await smart.setRole(await smart.AdminRole(), '0x7413521899ded2719a5BFaEAe6a8375A0Be622dD', true); // edmond
  await tx.wait();
  tx = await smart.setRole(await smart.CommunityRole(), '0xacB93B394cFc772C2273f54389c3081aa92Cf0C8', true); // edmond
  await tx.wait();
  tx = await agentManager.addTopAgent('0xBBB553176222Cd4eBE601ED224CE549A2f738776', 3, true);
  await tx.wait();


  // enpeng settings
  // tx = await smart.setRole(await smart.CommunityRole(), '0x6B26D93522511fa0c64107235402c40B18Cd42b3', true);
  // await tx.wait();
  // tx = await smart.setRole(await smart.AdminRole(), '0x55a0e984bC0C2650a16E2300a372b1D94CbD3E63', true);
  // await tx.wait();
  // tx = await agentManager.addTopAgent('0xF2b3CCBc45bdA7d0aa5a25172C0a270ad55D2473', 3, true);
  // await tx.wait();

  // liangqin settings
  // tx = await smart.setRole(await smart.AdminRole(), '0x18d3C20a79fbCeb89fA1DAd8831dcF6EBbe27491', true);
  // await tx.wait();
  // tx = await smart.setRole(await smart.CommunityRole(), '0xe806c1d508C33C65fe49A2175199A7C3E0afAdaf', true);
  // await tx.wait();
  // tx = await agentManager.addTopAgent('0x81bD01D0A9E8e8E40FAf22B779Bb21BaFbf8f7AC', 3, true);
  // await tx.wait();


  console.log(`community role: ${await smart.hasRole(await smart.CommunityRole(), "0xacB93B394cFc772C2273f54389c3081aa92Cf0C8")}`)
  console.log(`admin role: ${await smart.hasRole(await smart.AdminRole(), "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD")}`)
  console.log(`agent: ${await agentManager.getAgentByWallet('0xBBB553176222Cd4eBE601ED224CE549A2f738776')}`)

}

main();
