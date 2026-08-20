import { useState } from "react";
import { formatTokenAmount } from "../utils/formatters";

function StakingCard({
  stakeBalance,
  stakedAmount,
  onApprove,
  onStake,
  onWithdraw,
  loading,
}) {
  const [amount, setAmount] = useState("");

  const handleStake = async () => {
    if (!amount || Number(amount) <= 0) return;

    try {
      await onApprove(amount);
      await onStake(amount);
      setAmount("");
    } catch {
      // Error is handled by useStaking.
    }
  };

  const handleWithdraw = async () => {
    if (!amount || Number(amount) <= 0) return;

    try {
      await onWithdraw(amount);
      setAmount("");
    } catch {
      // Error is handled by useStaking.
    }
  };

  const setMaxStake = () => {
    if (stakeBalance && Number(stakeBalance) > 0) {
      setAmount(stakeBalance);
    }
  };

  return (
    <section className="card staking-card">
      <div className="card-header">
        <div>
          <span className="card-eyebrow">STAKE</span>
          <h2>Your Position</h2>
        </div>

        <div className="token-icon stake-icon">S</div>
      </div>

      <div className="position-summary">
        <div className="balance-item">
          <span>Available Balance</span>
          <strong>{formatTokenAmount(stakeBalance)} STAKE</strong>
        </div>

        <div className="balance-item">
          <span>Staked Amount</span>
          <strong>{formatTokenAmount(stakedAmount)} STAKE</strong>
        </div>
      </div>

      <div className="amount-section">
        <div className="amount-label">
          <span>Enter staking amount</span>

          <button type="button" onClick={setMaxStake} disabled={loading}>
            MAX
          </button>
        </div>

        <div className="amount-input">
          <input
            type="number"
            min="0"
            step="any"
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            placeholder="0.00"
            disabled={loading}
          />

          <span>STAKE</span>
        </div>
      </div>

      <div className="actions">
        <button
          type="button"
          className="primary-action"
          onClick={handleStake}
          disabled={loading || !amount || Number(amount) <= 0}
        >
          {loading ? "Processing..." : "Approve & Stake"}
        </button>

        <button
          type="button"
          className="secondary-action"
          onClick={handleWithdraw}
          disabled={
            loading ||
            !amount ||
            Number(amount) <= 0 ||
            Number(amount) > Number(stakedAmount)
          }
        >
          Withdraw
        </button>
      </div>
    </section>
  );
}

export default StakingCard;
