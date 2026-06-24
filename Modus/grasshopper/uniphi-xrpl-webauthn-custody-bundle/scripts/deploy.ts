import { ethers } from "hardhat";

async function main() {
  const Factory = await ethers.getContractFactory("UniphiRegistry");
  const c = await Factory.deploy();
  await c.waitForDeployment();
  console.log("UniphiRegistry deployed to:", await c.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
