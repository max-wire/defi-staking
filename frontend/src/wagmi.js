import { createConfig, http } from "wagmi";
import { defineChain } from "viem";
import { metaMask, walletConnect, coinbaseWallet } from "wagmi/connectors";

export const foundryLocal = defineChain({
  id: 31337,
  name: "Foundry Local",
  nativeCurrency: {
    name: "Ether",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:8545"],
    },
  },
});

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

export const config = createConfig({
  chains: [foundryLocal],

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
    [foundryLocal.id]: http("http://127.0.0.1:8545"),
  },
});
