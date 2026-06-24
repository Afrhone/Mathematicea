const hre = require("hardhat");
async function main() {
  const initial = hre.ethers.parseUnits(process.env.TOKEN_INITIAL_SUPPLY || "715000000", 18);
  const Token = await hre.ethers.getContractFactory("YettiSnowCredits");
  const token = await Token.deploy(initial);
  await token.waitForDeployment();
  const DAO = await hre.ethers.getContractFactory("YettiDAO");
  const dao = await DAO.deploy();
  await dao.waitForDeployment();
  console.log(JSON.stringify({YettiSnowCredits: await token.getAddress(), YettiDAO: await dao.getAddress(), initialSupply: initial.toString(), network: hre.network.name}, null, 2));
}
main().catch((e) => { console.error(e); process.exit(1); });
