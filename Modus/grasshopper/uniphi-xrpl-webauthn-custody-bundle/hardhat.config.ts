import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const rpcUrl = process.env.EVM_RPC_URL || "https://rpc.xrplevm.org";
const chainId = Number(process.env.EVM_CHAIN_ID || "1440000");
const pk = process.env.EVM_PRIVATE_KEY || "";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    xrplevm: {
      url: rpcUrl,
      chainId,
      accounts: pk ? [pk] : [],
    },
    xrplevmTestnet: {
      url: process.env.EVM_RPC_URL || "https://rpc.testnet.xrplevm.org",
      chainId: Number(process.env.EVM_CHAIN_ID || "1449000"),
      accounts: pk ? [pk] : [],
    },
  },
};

export default config;
