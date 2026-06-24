require("@nomicfoundation/hardhat-toolbox");
module.exports = { solidity: "0.8.24", networks: { localhost: { url: process.env.EVM_RPC_URL || "http://127.0.0.1:8545", chainId: Number(process.env.CHAIN_ID || 31337) } } };
