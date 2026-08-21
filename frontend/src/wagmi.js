import { createConfig, http } from "wagmi";
import { defineChain } from "viem";
import { metaMask, walletConnect, coinbaseWallet } from "wagmi/connectors";

export const sepolia = defineChain({
  id: 11155111,
  name: "Sepolia",
  nativeCurrency: {
    name: "Sepolia Ether",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["https://ethereum-sepolia-rpc.publicnode.com"],
    },
  },
});

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

export const config = createConfig({
  chains: [sepolia],

  connectors: [
    metaMask(),

    walletConnect({
      projectId,
      metadata: {
        name: "StakeVault",
        description: "DeFi Staking Protocol",
        url: window.location.origin,
        icons: [],
      },
    }),

    coinbaseWallet({
      appName: "StakeVault",
    }),
  ],

  transports: {
    [sepolia.id]: http("https://ethereum-sepolia-rpc.publicnode.com"),
  },
});
