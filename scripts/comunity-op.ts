import { ethers } from "hardhat";

import {contracts} from "./env";

enum CommunityDecision { BUYER_WIN = 0, SELLER_WINER = 1, DRAW = 2 }
async function main() {
  const [owner] = await ethers.getSigners();
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  // await smart.connect(owner).setRole(await smart.CommunityRole(), owner.address, true);
  // await smart.connect(owner).communityDecide(8, CommunityDecision.BUYER_WIN);
  // await smart.connect(owner).bindRelationship(100000001);
  console.log(`boundAgents: ${await smart.boundAgents(owner.address)}`);
}

main();
