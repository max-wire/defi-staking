# StakeVault

A full-stack DeFi staking protocol built with **Solidity, Foundry, React, Vite, Ethers.js, and Wagmi**.

StakeVault allows users to stake ERC-20 tokens and earn rewards over time based on a configurable reward emission rate. The protocol uses a **finite reward pool**, ensuring that rewards cannot exceed the amount of reward tokens funded into the staking vault.

The project includes a complete smart contract system, a comprehensive Foundry test suite, deployment scripts, and a React frontend that interacts directly with the deployed contracts.

## Features

### Smart Contracts

* ERC-20 `StakeToken`
* ERC-20 `RewardToken`
* `StakingVault` for staking and reward distribution
* Time-based reward accrual
* Configurable reward emission rate
* Finite reward pool
* Multiple user staking support
* Proportional reward distribution
* Reward claiming
* Partial and full withdrawals
* `exit()` functionality for withdrawing stake and claiming rewards
* Owner-controlled reward funding
* Owner-controlled reward rate updates
* Emergency pause functionality
* Reentrancy protection
* Custom errors
* Event emission for major protocol actions

### Frontend

The project also includes a React frontend that integrates directly with the deployed smart contracts.

Features include:

* Wallet connection
* MetaMask support
* WalletConnect support
* Coinbase Wallet support
* Automatic network detection
* Local Anvil network support
* STAKE token balance display
* REWARD token balance display
* Staked balance display
* Total protocol stake
* Reward rate display
* Remaining reward pool
* Accrued rewards
* Token approval
* Staking
* Withdrawal
* Reward claiming
* Exit functionality
* Automatic blockchain data refresh

---

# Architecture

```text
                         ┌─────────────────┐
                         │   StakeToken    │
                         │    ERC-20       │
                         └────────┬────────┘
                                  │
                                  │ stake()
                                  ▼
┌──────────────┐          ┌─────────────────┐          ┌──────────────┐
│              │          │                 │          │              │
│    Users     ├─────────►│   StakingVault  │◄─────────┤    Owner     │
│              │          │                 │          │              │
└──────────────┘          └────────┬────────┘          └──────┬───────┘
                                   │                          │
                                   │                          │
                         ┌─────────▼─────────┐       fundRewards()
                         │                   │◄───────────────┘
                         │  Reward Accounting│
                         │                   │
                         │ rewardPerToken    │
                         │ earned()          │
                         │ rewardRemaining   │
                         └─────────┬─────────┘
                                   │
                                   │ claimRewards()
                                   ▼
                         ┌─────────────────┐
                         │   RewardToken   │
                         │     ERC-20      │
                         └─────────────────┘
```

## Protocol Flow

```text
User
 │
 │ Approve STAKE
 ▼
StakeToken.approve()
 │
 ▼
StakingVault.stake()
 │
 ├── Transfers STAKE into vault
 ├── Updates totalStaked
 ├── Updates user balance
 └── Updates reward accounting

        Time passes
             │
             ▼

     rewardPerToken increases
             │
             ▼

       User accrues rewards
             │
             ├──────────────► claimRewards()
             │
             └──────────────► exit()
                                  │
                                  ├── Claims rewards
                                  └── Withdraws all STAKE
```

---

# Reward Mechanism

Rewards are emitted over time according to the configured reward rate.

```text
reward = elapsedTime × rewardRate
```

Rewards are distributed proportionally based on each user's share of the total staked amount.

The reward system uses a cumulative `rewardPerToken` accounting model to efficiently calculate rewards for multiple users.

Conceptually:

```text
rewardPerToken =
    rewardPerTokenStored
    + (newRewards × PRECISION / totalStaked)
```

A user's earned rewards are calculated from their staking balance and the increase in cumulative rewards per token.

The protocol also maintains a finite reward pool:

```solidity
rewardRemaining
```

Rewards cannot exceed the amount funded into the vault. Once the reward pool is exhausted, reward emissions stop until additional rewards are funded.

This prevents the protocol from creating reward liabilities greater than the available REWARD token balance.

---

# Project Structure

```text
defi-staking/
│
├── src/
│   ├── staking/
│   │   └── StakingVault.sol
│   │
│   └── tokens/
│       ├── StakeToken.sol
│       └── RewardToken.sol
│
├── script/
│   └── DeployStaking.s.sol
│
├── test/
│   └── unit/
│       ├── StakeToken.t.sol
│       ├── RewardToken.t.sol
│       └── StakingVault.t.sol
│
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── contracts/
│   │   ├── hooks/
│   │   └── App.jsx
│   │
│   ├── .env.example
│   └── package.json
│
├── foundry.toml
└── README.md
```

---

# Smart Contract Testing

The protocol is tested using Foundry.

The current test suite contains **80 passing tests** covering the STAKE token, REWARD token, and `StakingVault`.

## Token Tests

Tests include:

* Initial supply
* Token ownership
* Token metadata
* Decimals
* Transfers
* Approvals
* `transferFrom`
* Total supply invariants
* Balance checks

## StakingVault Tests

Tests include:

* Staking
* Multiple staking operations
* Withdrawals
* Full withdrawals
* Reward accrual over time
* Proportional reward distribution
* Multiple user reward calculations
* Reward claiming
* Exit functionality
* Reward funding
* Reward rate updates
* Pause and unpause functionality
* Event emission verification

## Security and Edge Cases

The test suite also covers:

* Zero-amount staking
* Zero-amount withdrawals
* Withdrawal attempts above deposited balances
* Claiming rewards when no rewards exist
* Zero token address validation
* Owner-only reward funding
* Owner-only reward rate updates
* Pause protection
* Reward funding while paused
* Reward pool exhaustion
* Prevention of rewards exceeding the funded amount
* Reward rate changes not applying retroactively
* Prevention of reward accrual when no users are staking
* Time-based reward accounting
* View function consistency
* `totalStaked` accounting invariants

Run the tests:

```bash
forge test
```

For more detailed output:

```bash
forge test -vvv
```

---

# Local Development

## Prerequisites

Install:

* Foundry
* Node.js
* npm
* A browser wallet such as MetaMask

Foundry documentation:

[Foundry Book](https://book.getfoundry.sh/?utm_source=chatgpt.com)

## Installation

Clone the repository:

```bash
git clone <your-repository-url>
```

Navigate into the project:

```bash
cd defi-staking
```

Install dependencies:

```bash
forge install
```

Build the contracts:

```bash
forge build
```

Run the tests:

```bash
forge test
```

---

# Running a Local Blockchain

Start Anvil:

```bash
anvil
```

By default, Anvil runs at:

```text
http://127.0.0.1:8545
```

The local chain ID is:

```text
31337
```

---

# Deployment

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key
```

Deploy the protocol:

```bash
forge script script/DeployStaking.s.sol:DeployStaking \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast
```

The deployment script deploys:

1. `StakeToken`
2. `RewardToken`
3. `StakingVault`

It also:

* Funds the reward pool
* Configures the reward emission rate

After deployment, update the frontend contract configuration.

Example:

```javascript
export const CONTRACTS = {
  stakeToken: "YOUR_STAKE_TOKEN_ADDRESS",
  rewardToken: "YOUR_REWARD_TOKEN_ADDRESS",
  stakingVault: "YOUR_STAKING_VAULT_ADDRESS",
};

export const NETWORK = {
  chainId: 31337,
  chainName: "Foundry Local",
};
```

---

# Frontend

Navigate to the frontend directory:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
```

Start the development server:

```bash
npm run dev
```

The application will connect to the local Anvil blockchain.

Make sure:

1. Anvil is running.
2. The contracts have been deployed.
3. The contract addresses are configured correctly.
4. Your wallet is connected to the Foundry Local network.

Update the contract configuration in:

```text
frontend/src/contracts/config.js
```

---

# Wallet Network Configuration

For local development, configure your wallet with:

```text
Network Name: Foundry Local
RPC URL: http://127.0.0.1:8545
Chain ID: 31337
Currency Symbol: ETH
```

---

# Available Smart Contract Functions

## User Functions

### `stake`

```solidity
stake(uint256 amount)
```

Stake STAKE tokens in the vault.

### `withdraw`

```solidity
withdraw(uint256 amount)
```

Withdraw a specified amount of staked tokens.

### `claimRewards`

```solidity
claimRewards()
```

Claim all accrued REWARD tokens.

### `exit`

```solidity
exit()
```

Claim accrued rewards and withdraw the user's entire staking position.

## Admin Functions

### `fundRewards`

```solidity
fundRewards(uint256 amount)
```

Fund the vault with additional REWARD tokens.

### `setRewardRate`

```solidity
setRewardRate(uint256 newRate)
```

Update the reward emission rate.

### `pause`

```solidity
pause()
```

Pause staking operations.

### `unpause`

```solidity
unpause()
```

Resume staking operations.

---

# Security Considerations

The protocol includes several security mechanisms:

* `ReentrancyGuard` protection for token-moving operations
* `SafeERC20` for secure ERC-20 interactions
* Owner-only administrative functions
* Input validation
* Zero-address validation
* Custom errors
* Emergency pause functionality
* Finite reward pool accounting
* Reward emission caps
* Accounting tests and invariants

---

# Technology Stack

## Smart Contracts

* Solidity
* Foundry
* OpenZeppelin
* Anvil

## Frontend

* React
* Vite
* Ethers.js
* Wagmi
* WalletConnect
* MetaMask
* Coinbase Wallet

---

# Future Improvements

Potential future improvements include:

* Support for multiple staking pools
* Different reward tokens
* Reward lockup periods
* Early withdrawal penalties
* Governance-controlled reward parameters
* Mainnet or testnet deployment
* Subgraph or indexing support
* Historical staking analytics
* APY calculations
* Transaction history
* Mobile UI improvements

---

# License

MIT
