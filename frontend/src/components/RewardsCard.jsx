import { formatTokenAmount } from "../utils/formatters";

function RewardsCard({
  rewardBalance,
  earnedRewards,
  onClaim,
  onExit,
  loading,
}) {
  const hasRewards = Number(earnedRewards) > 0;

  return (
    <section className="card rewards-card">
      <div className="card-header">
        <div>
          <span className="card-eyebrow">REWARD</span>
          <h2>Rewards</h2>
        </div>

        <div className="token-icon reward-icon">R</div>
      </div>

      <div className="position-summary">
        <div className="balance-item">
          <span>Available Balance</span>
          <strong>{formatTokenAmount(rewardBalance)} REWARD</strong>
        </div>

        <div className="balance-item highlight">
          <span>Accrued Rewards</span>
          <strong>{formatTokenAmount(earnedRewards)} REWARD</strong>
        </div>
      </div>

      <div className="reward-display">
        <span>Available to claim</span>

        <strong>
          {formatTokenAmount(earnedRewards)}
          <small> REWARD</small>
        </strong>
      </div>

      <div className="actions">
        <button
          type="button"
          className="primary-action"
          onClick={onClaim}
          disabled={loading || !hasRewards}
        >
          {loading ? "Processing..." : "Claim Rewards"}
        </button>

        <button
          type="button"
          className="secondary-action"
          onClick={onExit}
          disabled={loading}
        >
          Unstake & Exit
        </button>
      </div>
    </section>
  );
}

export default RewardsCard;