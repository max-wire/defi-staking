import { useState } from "react";

function WalletButton({
  account,
  isConnected,
  isConnecting,
  onConnect,
  onDisconnect,
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const shortenAddress = (address) => {
    if (!address) return "";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const handleDisconnect = () => {
    setIsOpen(false);
    onDisconnect();
  };

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(account);
      setCopied(true);

      setTimeout(() => {
        setCopied(false);
      }, 1500);
    } catch (error) {
      console.error("Failed to copy address:", error);
    }
  };

  if (isConnected) {
    return (
      <div className="wallet-menu">
        <button
          type="button"
          className="wallet-address"
          onClick={() => setIsOpen((previous) => !previous)}
        >
          <span className="wallet-dot" />

          <span>{shortenAddress(account)}</span>

          <span className="wallet-chevron">
            {isOpen ? "▲" : "▼"}
          </span>
        </button>

        {isOpen && (
          <div className="wallet-dropdown">
            <div className="wallet-account">
              <span>Connected Wallet</span>
              <strong>{shortenAddress(account)}</strong>
            </div>

            <button
              type="button"
              className="wallet-action"
              onClick={handleCopy}
            >
              {copied ? "✓ Copied" : "Copy Address"}
            </button>

            <button
              type="button"
              className="wallet-action disconnect"
              onClick={handleDisconnect}
            >
              Disconnect
            </button>
          </div>
        )}
      </div>
    );
  }

  return (
    <button
      type="button"
      className="connect-wallet"
      onClick={onConnect}
      disabled={isConnecting}
    >
      {isConnecting ? "Connecting..." : "Connect Wallet"}
    </button>
  );
}

export default WalletButton;