import { deploy_logic } from "./deploy-logic";

let smartAdmins: string[] = [
  "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD", // edmond
  "0x18d3C20a79fbCeb89fA1DAd8831dcF6EBbe27491"  // fanshifu
];
let smartCommunities: string[] = [
  "0xacB93B394cFc772C2273f54389c3081aa92Cf0C8", // edmond
];
let payTokens: string[] = [
  "0x55d398326f99059fF775485246999027B3197955", // USDT
  "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d", // USDC
];
let communityWallet = "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD"; // edmond
let operatorWallet = "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD"; // edmond
let globalShareWallet = "0x7413521899ded2719a5BFaEAe6a8375A0Be622dD"; // edmond
let upgradeAdmin = "0x18d3C20a79fbCeb89fA1DAd8831dcF6EBbe27491"; // fanshifu

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy_logic(
  smartAdmins,
  smartCommunities,
  payTokens,
  communityWallet,
  operatorWallet,
  globalShareWallet,
  upgradeAdmin
  ).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
