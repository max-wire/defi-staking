# StakeVault

A full-stack DeFi staking protocol built with **Solidity, Foundry, React, Vite, Ethers.js, and Wagmi**.

StakeVault allows users to stake ERC-20 tokens and earn rewards over time based on a configurable reward emission rate.

The protocol uses a **finite reward pool**, ensuring that rewards cannot exceed the amount of REWARD tokens funded into the staking vault.

The project includes:

* Production-ready Solidity smart contracts
* Comprehensive Foundry test suite
* Deployment scripts
* Ethereum Sepolia testnet deployment
* React/Vite frontend
* Wagmi wallet integration
* Ethers.js contract interaction
* Real-time blockchain data refresh
* Frontend validation for staking and withdrawal operations

---

## Live Sepolia Deployment

StakeVault is deployed on the **Ethereum Sepolia testnet**.

### Live Application

https://defi-staking-lxp59o5zy-wire4.vercel.app/

### Network

* **Network:** Ethereum Sepolia
* **Chain ID:** 11155111
* **Deployment Type:** Testnet
* **Frontend:** Vercel
* **Wallets:** MetaMask, WalletConnect, Coinbase Wallet

---

## Deployed Smart Contracts

| Contract     | Sepolia Address                              |
| ------------ | -------------------------------------------- |
| StakeToken   | `0x6De64f2A0D3C1c93cECB67eF06D4a22ff6e00999` |
| RewardToken  | `0x1D1A21d7468040b306d06E3f1c6c30eeD249F380` |
| StakingVault | `0x9A8a5DdEC15F4B8822BF10E849B5C465D6cf2C1e` |

The frontend is configured with these deployed Sepolia contract addresses and interacts with them using **Wagmi and Ethers.js**.

---

## Application Features

### Staking

Users can:

* View their STAKE balance
* Approve the StakingVault to spend STAKE
* Stake STAKE tokens
* View their current staking position
* Withdraw part of their position
* Withdraw their complete position through `exit()`

The frontend validates the user's STAKE balance before starting the approval and staking flow.

If a user attempts to stake more STAKE than they own, the transaction is prevented instead of sending a transaction that would fail on-chain.

### Rewards

Users can:

* View their REWARD balance
* View accrued rewards
* Claim accrued rewards
* Exit while claiming rewards and withdrawing their entire stake

Rewards are distributed according to the configured emission rate and each user's share of the total staking pool.

### Protocol Statistics

The dashboard displays:

* Total STAKE deposited in the vault
* REWARD emission rate
* Remaining funded reward pool

`Total Staked` represents the **global amount deposited into the vault**, while `Staked Amount` represents the connected user's individual position.

---

## Smart Contracts

### StakeToken

`StakeToken` is the ERC-20 token users deposit into the staking vault.

Configuration:

* **Name:** DeFi Stake Token
* **Symbol:** STAKE
* **Decimals:** 18
* **Initial Supply:** 1,000,000 STAKE
* **Minting:** Fixed supply in V1

The entire initial supply is minted to the deployment wallet.

### RewardToken

`RewardToken` is the ERC-20 token distributed to stakers as rewards.

The token is held by the reward funding account and transferred into the `StakingVault` through `fundRewards()`.

The vault does not mint reward tokens.

### StakingVault

`StakingVault` manages:

* STAKE deposits
* User staking positions
* Reward accounting
* Reward distribution
* Reward claiming
* Withdrawals
* Full exits
* Reward funding
* Reward emission rate configuration
* Emergency pause functionality

The contract uses:

* `ReentrancyGuard`
* `Pausable`
* `SafeERC20`
* Custom errors
* Event-based state tracking
* Cumulative `rewardPerToken` accounting

---

## Reward Mechanism

Rewards are emitted over time according to the configured reward rate.

Conceptually:

```text
reward = elapsedTime × rewardRate
```

Rewards are distributed proportionally according to each user's share of the total staked amount.

The protocol uses cumulative `rewardPerToken` accounting:

```solidity
rewardPerToken =
    rewardPerTokenStored
    + (newRewards * PRECISION / totalStaked);
```

A user's rewards are calculated using:

```solidity
userReward =
    userStake
    * (currentRewardPerToken - userRewardPerTokenPaid)
    / PRECISION;
```

This allows the protocol to support multiple users without iterating over every staker whenever rewards are updated.

---

## Finite Reward Pool

StakeVault does not mint REWARD tokens.

Rewards must first be funded into the vault:

```solidity
fundRewards(uint256 amount);
```

The protocol tracks the remaining reward emission budget through:

```solidity
rewardRemaining
```

The reward system ensures that the vault cannot account for more rewards than have been funded.

When the funded reward pool is exhausted:

```text
Reward pool exhausted
        ↓
Reward emission stops
        ↓
Additional REWARD must be funded
        ↓
Emission can continue
```

This prevents the protocol from creating reward liabilities greater than the funded reward pool.

---

## Protocol Flow

```text
                         ┌─────────────────┐
                         │   StakeToken    │
                         │      ERC-20     │
                         └────────┬────────┘
                                  │
                                  │ approve()
                                  ▼
                         ┌─────────────────┐
                         │  StakingVault   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
              User Position              Reward Accounting
                    │                           │
                    │                     rewardPerToken
                    │                           │
                    ▼                           ▼
                withdraw()                 earned()
                    │                           │
                    │                           │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                           claimRewards()
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   RewardToken   │
                         │      ERC-20     │
                         └─────────────────┘
```

---

## User Lifecycle

```text
User
 │
 │ 1. Connect Wallet
 ▼
Frontend
 │
 │ 2. Check STAKE balance
 ▼
Sufficient Balance?
 │
 ├── No ──► Prevent transaction
 │
 └── Yes
       │
       ▼
3. Check Allowance
       │
       ├── Sufficient ──► Skip approval
       │
       └── Insufficient
              │
              ▼
        4. Approve STAKE
              │
              ▼
        5. Stake STAKE
              │
              ▼
        6. Earn Rewards
              │
              ├──────────────► claimRewards()
              │
              └──────────────► exit()
                                      │
                                      ├── Claim rewards
                                      │
                                      └── Withdraw all STAKE
```

---

## Frontend

The frontend is built with:

* React
* Vite
* Ethers.js
* Wagmi

### Wallet Support

The application supports:

* MetaMask
* WalletConnect
* Coinbase Wallet

The frontend verifies that the connected wallet is using **Ethereum Sepolia** before interacting with the deployed contracts.

### Frontend Features

* Wallet connection
* Wallet address display
* Wallet disconnection
* STAKE balance
* REWARD balance
* User staking position
* Global total staked amount
* Reward emission rate
* Remaining reward pool
* Accrued rewards
* Token approval
* Staking
* Withdrawal
* Reward claiming
* Full exit
* Automatic blockchain data refresh
* Loading states
* Transaction error handling
* Insufficient balance validation
* Maximum stake shortcut

---

## Frontend Validation

The frontend performs validation before sending transactions.

For staking:

```text
User enters amount
        ↓
Check wallet STAKE balance
        ↓
amount > balance?
   │             │
  YES            NO
   │             │
   ▼             ▼
Stop          Check allowance
                 │
                 ▼
              approve()
                 │
                 ▼
               stake()
```

This prevents users from attempting to stake tokens they do not own.

Approval and staking are separate blockchain operations:

```solidity
approve()
```

only gives the `StakingVault` permission to spend STAKE.

It does **not** transfer or provide STAKE to the user.

The user must already hold sufficient STAKE tokens.

---

## Project Structure

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
│   │   ├── utils/
│   │   └── App.jsx
│   │
│   ├── .env.example
│   └── package.json
│
├── foundry.toml
└── README.md
```

---

## Smart Contract Testing

The protocol is tested using **Foundry**.

The current test suite contains **80 passing tests** covering the STAKE token, REWARD token, and `StakingVault`.

Run the test suite:

```bash
forge test
```

For detailed traces:

```bash
forge test -vvv
```

### Test Coverage

#### StakeToken

Tests cover:

* Initial supply
* Token ownership
* Token metadata
* Decimals
* Transfers
* Approvals
* `transferFrom`
* Total supply invariants
* Balance checks

#### RewardToken

Tests cover:

* Initial supply
* Token ownership
* Token metadata
* Decimals
* Transfers
* Approvals
* `transferFrom`
* Total supply invariants
* Balance checks

#### StakingVault

Tests cover:

* Staking
* Multiple staking operations
* Withdrawals
* Full withdrawals
* Reward accrual
* Proportional reward distribution
* Multiple-user reward calculations
* Reward claiming
* Exit functionality
* Reward funding
* Reward rate updates
* Pause/unpause
* Event emission

#### Security and Edge Cases

The test suite also covers:

* Zero-amount staking
* Zero-amount withdrawals
* Withdrawals above deposited balance
* Claiming when no rewards exist
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

---

## Local Development

### Prerequisites

Install:

* Foundry
* Node.js
* npm
* MetaMask or another supported browser wallet

### Clone the Repository

```bash
git clone <your-repository-url>
```

Navigate into the project:

```bash
cd defi-staking
```

Install Foundry dependencies:

```bash
forge install
```

Build the contracts:

```bash
forge build
```

Run tests:

```bash
forge test
```

---

## Running a Local Blockchain

Start Anvil:

```bash
anvil
```

Default RPC:

```text
http://127.0.0.1:8545
```

Local chain ID:

```text
31337
```

---

## Deployment

### Sepolia Testnet

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
```

Deploy:

```bash
forge script script/DeployStaking.s.sol:DeployStaking \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast
```

The deployment creates:

1. `StakeToken`
2. `RewardToken`
3. `StakingVault`

The deployment process also:

* Funds the reward pool
* Configures the reward emission rate

The deployed addresses are configured in:

```text
frontend/src/contracts/config.js
```

Current configuration:

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

> **Security:** Never commit `.env` files or private keys to the repository. The deployment private key is not required by the frontend.

---

## Local Deployment

Start Anvil:

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

Configure the frontend with the locally deployed addresses:

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

## Frontend Development

Navigate into the frontend:

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

The frontend can be configured for either:

* Ethereum Sepolia
* Local Anvil

Before interacting with the protocol, make sure:

1. The selected network matches the configured network.
2. The contracts are deployed.
3. The contract addresses are correct.
4. The wallet is connected to the correct network.

---

## Wallet Network Configuration

### Ethereum Sepolia

```text
Network Name: Ethereum Sepolia
Chain ID: 11155111
Currency Symbol: ETH
```

### Foundry Local

```text
Network Name: Foundry Local
RPC URL: http://127.0.0.1:8545
Chain ID: 31337
Currency Symbol: ETH
```

---

## Available Smart Contract Functions

### User Functions

#### `stake`

```solidity
stake(uint256 amount)
```

Deposits STAKE tokens into the vault.

#### `withdraw`

```solidity
withdraw(uint256 amount)
```

Withdraws a specified amount of the user's staked STAKE.

#### `claimRewards`

```solidity
claimRewards()
```

Claims all currently accrued REWARD tokens.

#### `exit`

```solidity
exit()
```

Claims accrued rewards and withdraws the user's entire staking position.

### Admin Functions

#### `fundRewards`

```solidity
fundRewards(uint256 amount)
```

Funds the vault with REWARD tokens.

#### `setRewardRate`

```solidity
setRewardRate(uint256 newRate)
```

Updates the REWARD emission rate.

#### `pause`

```solidity
pause()
```

Pauses staking, withdrawals, and reward claims.

#### `unpause`

```solidity
unpause()
```

Resumes normal staking operations.

---

## Security Considerations

StakeVault includes several security mechanisms:

* `ReentrancyGuard`
* `SafeERC20`
* Owner-controlled administrative functions
* Input validation
* Zero-address validation
* Custom errors
* Emergency pause functionality
* Finite reward pool accounting
* Reward emission caps
* Accounting invariants
* Comprehensive Foundry tests

The frontend does not require or expose the deployment wallet's private key.

The deployment wallet and frontend are intentionally separated:

```text
Deployment Wallet
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
Contract Addresses
   │
   ▼
Ethereum Sepolia
```

---

## Technology Stack

### Smart Contracts

* Solidity
* Foundry
* OpenZeppelin
* Anvil
* Ethereum Sepolia

### Frontend

* React
* Vite
* Ethers.js
* Wagmi
* WalletConnect
* MetaMask
* Coinbase Wallet
* Vercel

---

## Future Improvements

Potential future improvements include:

* Multiple staking pools
* Multiple reward tokens
* Reward lockup periods
* Early withdrawal penalties
* Governance-controlled reward parameters
* Mainnet deployment
* Subgraph/indexing support
* Historical staking analytics
* APY calculations
* Transaction history
* Mobile UI improvements

---

## License

MIT
