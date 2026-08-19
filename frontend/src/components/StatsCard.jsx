import { formatTokenAmount } from "../utils/formatters";

function StatsCard({ totalStaked, rewardRate, rewardRemaining }) {
  return (
    <section className="stats">
      <div className="stat-card">
        <span className="stat-label">Total Staked</span>

        <strong className="stat-value">
          {formatTokenAmount(totalStaked)}{" "}
          <span>STAKE</span>
        </strong>
      </div>

      <div className="stat-card">
        <span className="stat-label">Reward Rate</span>

        <strong className="stat-value">
          {formatTokenAmount(rewardRate, {
            maxDecimals: 6,
          })}{" "}
          <span>REWARD/sec</span>
        </strong>
      </div>

      <div className="stat-card">
        <span className="stat-label">Remaining Rewards</span>

        <strong className="stat-value">
          {formatTokenAmount(rewardRemaining)}{" "}
          <span>REWARD</span>
        </strong>
      </div>
    </section>
  );
}

export default StatsCard;