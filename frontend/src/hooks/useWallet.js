import { useCallback, useEffect, useState } from "react";
import { useAccount, useConnect, useDisconnect, useChainId } from "wagmi";
import { BrowserProvider } from "ethers";

const SEPOLIA_CHAIN_ID = 11155111;

export function useWallet() {
  const [provider, setProvider] = useState(null);
  const [error, setError] = useState(null);
  const [isInitializing, setIsInitializing] = useState(true);

  const {
    address: account,
    isConnected: wagmiIsConnected,
    connector,
  } = useAccount();

  const chainId = useChainId();

  const { connectAsync, connectors, isPending: isConnecting } = useConnect();

  const { disconnect } = useDisconnect();

  /**
   * Convert the Wagmi connector provider into an ethers BrowserProvider.
   *
   * This allows the existing useStaking hook to continue using ethers.
   */
  useEffect(() => {
    let mounted = true;

    const initializeProvider = async () => {
      if (!connector || !wagmiIsConnected) {
        if (mounted) {
          setProvider(null);
          setIsInitializing(false);
        }

        return;
      }

      try {
        const walletProvider = await connector.getProvider();

        if (!walletProvider) {
          throw new Error("Wallet provider is not available.");
        }

        const browserProvider = new BrowserProvider(walletProvider);

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
  }, [connector, wagmiIsConnected]);

  /**
   * Connect to a selected wallet connector.
   *
   * The wallet connection and network switching are handled by Wagmi.
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
    connector,
    connectors,
    error,
    isConnecting,
    isInitializing,

    isConnected: Boolean(account && provider) && chainId === SEPOLIA_CHAIN_ID,

    connectWallet,
    disconnectWallet,
  };
}
