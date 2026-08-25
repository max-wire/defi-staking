import { useCallback, useEffect, useState } from "react";
import { useAccount, useConnect, useDisconnect, useChainId } from "wagmi";
import { BrowserProvider } from "ethers";

const SEPOLIA_CHAIN_ID = 11155111;

export function useWallet() {
  const [provider, setProvider] = useState(null);
  const [error, setError] = useState(null);
  const [isInitializing, setIsInitializing] = useState(true);

  const { address: account, isConnected: wagmiIsConnected } = useAccount();

  const chainId = useChainId();

  const { connectAsync, connectors, isPending: isConnecting } = useConnect();

  const { disconnect } = useDisconnect();

  /**
   * Create an Ethers BrowserProvider from the
   * browser wallet's EIP-1193 provider.
   */
  useEffect(() => {
    let mounted = true;

    const initializeProvider = async () => {
      if (!wagmiIsConnected || !account || chainId !== SEPOLIA_CHAIN_ID) {
        if (mounted) {
          setProvider(null);
          setIsInitializing(false);
        }

        return;
      }

      try {
        if (!window.ethereum) {
          throw new Error(
            "No browser wallet detected. Please install MetaMask.",
          );
        }

        const browserProvider = new BrowserProvider(window.ethereum);

        // Verify that the provider is usable.
        await browserProvider.getNetwork();

        if (mounted) {
          setProvider(browserProvider);
          setError(null);
        }
      } catch (err) {
        console.error("Failed to initialize wallet provider:", err);

        if (mounted) {
          setProvider(null);

          setError(
            err?.shortMessage ||
              err?.message ||
              "Failed to initialize wallet provider.",
          );
        }
      } finally {
        if (mounted) {
          setIsInitializing(false);
        }
      }
    };

    initializeProvider();

    return () => {
      mounted = false;
    };
  }, [account, wagmiIsConnected, chainId]);

  /**
   * Connect to a selected wallet connector.
   */
  const connectWallet = useCallback(
    async (selectedConnector) => {
      try {
        setError(null);
        setIsInitializing(true);

        await connectAsync({
          connector: selectedConnector,
          chainId: SEPOLIA_CHAIN_ID,
        });
      } catch (err) {
        console.error("Wallet connection error:", err);

        if (err?.code === 4001) {
          setError("Wallet connection was rejected.");
        } else {
          setError(
            err?.shortMessage || err?.message || "Failed to connect wallet.",
          );
        }

        setProvider(null);
      } finally {
        setIsInitializing(false);
      }
    },
    [connectAsync],
  );

  /**
   * Disconnect the application wallet.
   */
  const disconnectWallet = useCallback(() => {
    disconnect();

    setProvider(null);
    setError(null);
  }, [disconnect]);

  return {
    account,
    provider,
    chainId,
    connectors,
    error,
    isConnecting,
    isInitializing,

    isConnected: Boolean(account && provider) && chainId === SEPOLIA_CHAIN_ID,

    connectWallet,
    disconnectWallet,
  };
}
