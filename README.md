# StakeVault

A full-stack DeFi staking protocol built with **Solidity, Foundry, React, Vite, Ethers.js, and Wagmi**.

StakeVault allows users to stake ERC-20 tokens and earn rewards over time based on a configurable reward emission rate. The protocol uses a **finite reward pool**, ensuring that rewards cannot exceed the amount of reward tokens funded into the staking vault.

The project includes a complete smart contract system, a comprehensive Foundry test suite, deployment scripts, and a React frontend that interacts directly with deployed smart contracts.

---

# Live Sepolia Deployment

Due to a temporary network issue with the Sky network, StakeVault was deployed to the **Ethereum Sepolia testnet** as requested by the project team.

## Live Application

**https://defi-staking-c6qp6kvzu-wire4.vercel.app/**

## Network

* **Network:** Ethereum Sepolia
* **Chain ID:** 11155111
* **Deployment Type:** Testnet
* **Frontend:** Vercel
* **Wallet:** MetaMask / WalletConnect / Coinbase Wallet

## Deployed Smart Contracts

| Contract     | Sepolia Address                              |
| ------------ | -------------------------------------------- |
| StakeToken   | `0x6De64f2A0D3C1c93cECB67eF06D4a22ff6e00999` |
| RewardToken  | `0x1D1A21d7468040b306d06E3f1c6c30eeD249F380` |
| StakingVault | `0x9A8a5DdEC15F4B8822BF10E849B5C465D6cf2C1e` |

The frontend is configured with the deployed Sepolia contract addresses and interacts with the contracts using **Wagmi and Ethers.js**.

The live deployment has been tested for:

* Wallet connection
* STAKE balance retrieval
* REWARD balance retrieval
* Staking
* Token approval
* Reward accrual
* Reward claiming
* Withdrawals
* Exit functionality
* Live protocol statistics

---

# Frontend Deployment

The StakeVault frontend is deployed using **Vercel**.

## Production URL

**https://defi-staking-swart.vercel.app/**

The Vercel deployment is connected to the GitHub repository and can be automatically updated when changes are pushed to the `main` branch.

The frontend is configured for Ethereum Sepolia:

```text
Chain ID: 11155111
Network: Ethereum Sepolia
```

The frontend interacts directly with the deployed smart contracts.

**No private keys are exposed to the frontend or stored in the Vercel deployment.**

The deployment wallet and frontend configuration are intentionally separated:

```text
Deployment wallet
       │
       │ PRIVATE_KEY
       ▼
    Foundry
       │
       │ deploys
       ▼
Ethereum Sepolia
       │
       ├── StakeToken
       ├── RewardToken
       └── StakingVault

Frontend
   │
   ▼
Vercel
   │
   ▼
Contract addresses
   │
   ▼
Ethereum Sepolia
```

---

# Features

## Smart Contracts

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

## Frontend

The project includes a React frontend that integrates directly with the deployed smart contracts.

Features include:

* Wallet connection
* MetaMask support
* WalletConnect support
* Coinbase Wallet support
* Automatic network detection
* Ethereum Sepolia support
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
┌──────────────┐           ┌─────────────────┐           ┌──────────────┐
│              │           │                 │           │              │
│    Users     ├──────────►│   StakingVault  │◄──────────┤    Owner     │
│              │           │                 │           │              │
└──────────────┘           └────────┬────────┘           └──────┬───────┘
                                   │                            │
                                   │                            │
                         ┌─────────▼─────────┐          fundRewards()
                         │                   │◄──────────────────┘
                         │ Reward Accounting │
                         │                   │
                         │ rewardPerToken   │
                         │ earned()         │
                         │ rewardRemaining  │
                         └─────────┬─────────┘
                                   │
                                   │ claimRewards()
                                   ▼
                         ┌─────────────────┐
                         │   RewardToken   │
                         │     ERC-20      │
                         └─────────────────┘
```

---

# Protocol Flow

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
         │
         │ Time passes
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

The protocol is tested using **Foundry**.

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

The production testnet deployment is Ethereum Sepolia. **Anvil is provided for local development and testing only.**

## Prerequisites

Install:

* Foundry
* Node.js
* npm
* A browser wallet such as MetaMask

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

## Sepolia Testnet

The production testnet deployment was performed using **Foundry**.

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
```

Deploy using:

```bash
forge script script/DeployStaking.s.sol:DeployStaking \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast
```

The deployment creates:

1. `StakeToken`
2. `RewardToken`
3. `StakingVault`

The deployment script also:

* Funds the reward pool
* Configures the reward emission rate

After deployment, the resulting contract addresses are configured in:

```text
frontend/src/contracts/config.js
```

For the current Sepolia deployment:

```javascript
export const CONTRACTS = {
  stakeToken: "0x6De64f2A0D3C1c93cECB67eF06D4a22ff6e00999",
  rewardToken: "0x1D1A21d7468040b306d06E3f1c6c30eeD249F380",
  stakingVault: "0x9A8a5DdEC15F4B8822BF10E849B5C465D6cf2C1e",
};

export const NETWORK = {
  chainId: 11155111,
  chainName: "Ethereum Sepolia",
};
```

> **Security:** Never commit `.env` or private keys to the repository. The private key is only used by the deployment environment and is not required by the frontend.

---

# Local Development Deployment

For local development, start Anvil:

```bash
anvil
```

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key
```

Deploy locally:

```bash
forge script script/DeployStaking.s.sol:DeployStaking \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast
```

After deployment, configure the frontend with the locally deployed contract addresses.

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

For local development, the application can connect to the local Anvil blockchain.

For the deployed application, use the production configuration for **Ethereum Sepolia**.

Make sure:

1. The selected network matches the configured contract network.
2. The contracts have been deployed.
3. The contract addresses are configured correctly.
4. Your wallet is connected to the correct network.

Update the contract configuration in:

```text
frontend/src/contracts/config.js
```

---

# Wallet Network Configuration

## Ethereum Sepolia

For the live deployment, configure your wallet to use:

```text
Network Name: Ethereum Sepolia
Chain ID: 11155111
Currency Symbol: ETH
```

## Foundry Local

For local development:

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

The frontend does not require or expose the deployment wallet's private key.

---

# Technology Stack

## Smart Contracts

* Solidity
* Foundry
* OpenZeppelin
* Anvil for local development
* Ethereum Sepolia for testnet deployment

## Frontend

* React
* Vite
* Ethers.js
* Wagmi
* WalletConnect
* MetaMask
* Coinbase Wallet
* Vercel

---

# Future Improvements

Potential future improvements include:

* Support for multiple staking pools
* Different reward tokens
* Reward lockup periods
* Early withdrawal penalties
* Governance-controlled reward parameters
* Mainnet deployment
* Subgraph or indexing support
* Historical staking analytics
* APY calculations
* Transaction history
* Mobile UI improvements

---

# License

MIT
