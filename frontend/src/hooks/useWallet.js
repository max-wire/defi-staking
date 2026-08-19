import { useCallback, useEffect, useState } from "react";
import { BrowserProvider } from "ethers";

const ANVIL_NETWORK = {
  chainId: "0x7a69", // 31337
  chainName: "Foundry Local",
  nativeCurrency: {
    name: "Ether",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: ["http://127.0.0.1:8545"],
};

const ANVIL_CHAIN_ID = 31337;

export function useWallet() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [error, setError] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);

  /**
   * Switch MetaMask to the local Anvil network.
   *
   * If Anvil has not been added to MetaMask yet, add it first.
   */
  const switchToAnvil = useCallback(async () => {
    if (!window.ethereum) {
      throw new Error("MetaMask is not installed.");
    }

    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: ANVIL_NETWORK.chainId }],
      });
    } catch (err) {
      // 4902 = chain has not been added to MetaMask
      if (err?.code === 4902) {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [ANVIL_NETWORK],
        });
      } else {
        throw err;
      }
    }
  }, []);

  /**
   * Make sure MetaMask is connected to Anvil.
   */
  const ensureCorrectNetwork = useCallback(async () => {
    if (!window.ethereum) {
      throw new Error("MetaMask is not installed.");
    }

    const currentChainId = await window.ethereum.request({
      method: "eth_chainId",
    });

    const numericChainId = parseInt(currentChainId, 16);

    if (numericChainId !== ANVIL_CHAIN_ID) {
      await switchToAnvil();
    }

    return ANVIL_CHAIN_ID;
  }, [switchToAnvil]);

  /**
   * Connect the wallet.
   */
  const connectWallet = useCallback(async () => {
    if (!window.ethereum) {
      setError("MetaMask or another compatible wallet is not installed.");
      return;
    }

    try {
      setIsConnecting(true);
      setError(null);

      // Ask MetaMask for account access.
      await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      // Make sure we are on Anvil before creating the provider.
      await ensureCorrectNetwork();

      const browserProvider = new BrowserProvider(window.ethereum);

      const signer = await browserProvider.getSigner();
      const address = await signer.getAddress();
      const network = await browserProvider.getNetwork();

      setProvider(browserProvider);
      setAccount(address);
      setChainId(Number(network.chainId));
    } catch (err) {
      console.error("Wallet connection error:", err);

      if (err?.code === 4001) {
        setError("Wallet connection was rejected.");
      } else if (err?.code === 4902) {
        setError("Could not add the Foundry Local network to MetaMask.");
      } else {
        setError(
          err?.shortMessage ||
            err?.message ||
            "Failed to connect wallet.",
        );
      }

      setAccount(null);
      setProvider(null);
      setChainId(null);
    } finally {
      setIsConnecting(false);
    }
  }, [ensureCorrectNetwork]);

  /**
   * Disconnect the application.
   *
   * MetaMask itself does not provide a programmatic disconnect.
   * We simply clear the application's connection state.
   */
  const disconnectWallet = useCallback(() => {
    setAccount(null);
    setProvider(null);
    setChainId(null);
    setError(null);
  }, []);

  /**
   * Initialize an already-authorized wallet.
   *
   * eth_accounts does NOT trigger a MetaMask popup.
   */
  useEffect(() => {
    if (!window.ethereum) {
      setIsInitializing(false);
      return;
    }

    const initializeWallet = async () => {
      try {
        const browserProvider = new BrowserProvider(window.ethereum);

        const accounts = await browserProvider.send("eth_accounts", []);

        if (accounts.length === 0) {
          return;
        }

        const network = await browserProvider.getNetwork();
        const currentChainId = Number(network.chainId);

        // Do not initialize staking against the wrong network.
        if (currentChainId !== ANVIL_CHAIN_ID) {
          setError(
            "Please switch MetaMask to the Foundry Local network.",
          );
          return;
        }

        setProvider(browserProvider);
        setAccount(accounts[0]);
        setChainId(currentChainId);
      } catch (err) {
        console.error("Failed to initialize wallet:", err);

        setError(
          err?.shortMessage ||
            err?.message ||
            "Failed to initialize wallet.",
        );
      } finally {
        setIsInitializing(false);
      }
    };

    const handleAccountsChanged = async (accounts) => {
      if (accounts.length === 0) {
        disconnectWallet();
        return;
      }

      try {
        const browserProvider = new BrowserProvider(window.ethereum);
        const network = await browserProvider.getNetwork();

        if (Number(network.chainId) !== ANVIL_CHAIN_ID) {
          setError(
            "Please switch MetaMask to the Foundry Local network.",
          );
          return;
        }

        setProvider(browserProvider);
        setAccount(accounts[0]);
        setChainId(Number(network.chainId));
        setError(null);
      } catch (err) {
        setError(
          err?.shortMessage ||
            err?.message ||
            "Failed to update wallet.",
        );
      }
    };

    const handleChainChanged = () => {
      // Reinitialize the provider/account against the new chain.
      initializeWallet();
    };

    initializeWallet();

    window.ethereum.on("accountsChanged", handleAccountsChanged);
    window.ethereum.on("chainChanged", handleChainChanged);

    return () => {
      window.ethereum.removeListener(
        "accountsChanged",
        handleAccountsChanged,
      );

      window.ethereum.removeListener(
        "chainChanged",
        handleChainChanged,
      );
    };
  }, [disconnectWallet]);

  return {
    account,
    provider,
    chainId,
    error,
    isConnecting,
    isInitializing,
    isConnected: Boolean(
      account &&
        provider &&
        chainId === ANVIL_CHAIN_ID,
    ),
    connectWallet,
    disconnectWallet,
  };
}