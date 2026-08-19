import "./App.css";

import WalletButton from "./components/WalletButton";
import StakingCard from "./components/StakingCard";
import RewardsCard from "./components/RewardsCard";
import StatsCard from "./components/StatsCard";

import { useWallet } from "./hooks/useWallet";
import { useStaking } from "./hooks/useStaking";

function App() {
  const wallet = useWallet();

  const staking = useStaking(wallet.provider, wallet.account);

  return (
    <main className="app">
      <header className="navbar">
        <div>
          <h1>StakeVault</h1>
          <span>DeFi Staking Protocol</span>
        </div>

        <WalletButton
          account={wallet.account}
          isConnected={wallet.isConnected}
          isConnecting={wallet.isConnecting}
          onConnect={wallet.connectWallet}
          onDisconnect={wallet.disconnectWallet}
        />
      </header>

      {wallet.error && <div className="error">{wallet.error}</div>}

      {staking.error && <div className="error">{staking.error}</div>}

      {!wallet.isConnected ? (
        <section className="welcome">
          <h1>Put Your Assets to Work</h1>
          <p>
            Stake tokens, earn rewards, and manage your position
            from one simple DeFi dashboard.
          </p>
        </section>
      ) : (
        <>
          <StatsCard
            totalStaked={staking.totalStaked}
            rewardRate={staking.rewardRate}
            rewardRemaining={staking.rewardRemaining}
          />

          <section className="dashboard">
            <StakingCard
              stakeBalance={staking.stakeBalance}
              stakedAmount={staking.stakedAmount}
              onApprove={staking.approveStake}
              onStake={staking.stake}
              onWithdraw={staking.withdraw}
              loading={staking.loading}
            />

            <RewardsCard
              rewardBalance={staking.rewardBalance}
              earnedRewards={staking.earnedRewards}
              onClaim={staking.claimRewards}
              onExit={staking.exit}
              loading={staking.loading}
            />
          </section>
        </>
      )}
    </main>
  );
}

export default App;
