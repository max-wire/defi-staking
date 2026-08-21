# StakeVault Frontend

React-based frontend for the **StakeVault DeFi staking protocol**.

The application provides a Web3 interface for interacting with the StakeVault smart contracts, allowing users to connect their wallets, stake **STAKE** tokens, earn **REWARD** tokens, withdraw their stake, and claim accumulated rewards.

## Features

* 🔗 **Multi-wallet Web3 connection**

  * MetaMask
  * WalletConnect-compatible wallets
  * Coinbase Wallet
*  **STAKE token balance tracking**
*  **Approve and stake STAKE tokens**
*  **Withdraw staked tokens**
*  **Real-time REWARD accrual**
*  **Claim staking rewards**
*  **Unstake and exit**
*  **Live staking statistics**

  * Total staked
  * Reward emission rate
  * Remaining reward pool
*  **Automatic blockchain state refresh**
*  **Foundry/Anvil local network support**
*  **React + Vite frontend**
*  **Ethers.js Web3 integration**

## Architecture

The frontend acts as the user-facing layer for the StakeVault protocol.

```text
┌──────────────────────┐
│   StakeVault UI      │
│   React + Vite       │
└──────────┬───────────┘
           │
           │ Ethers.js
           ▼
┌──────────────────────┐
│    Web3 Wallet       │
│ MetaMask / Wallets   │
└──────────┬───────────┘
           │
           │ Transactions
           ▼
┌──────────────────────┐
│   StakeVault.sol     │
│                      │
│ stake()              │
│ withdraw()           │
│ claimRewards()       │
│ exit()               │
└───────┬───────┬──────┘
        │       │
        ▼       ▼
   STAKE Token  REWARD Token
```

## Smart Contract Integration

The frontend interacts with the StakeVault protocol through the deployed contract interfaces.

### User operations

| Operation            | Contract interaction          |
| -------------------- | ----------------------------- |
| Check STAKE balance  | `StakeToken`                  |
| Approve STAKE        | `StakeToken.approve()`        |
| Stake                | `StakingVault.stake()`        |
| Check staked amount  | `StakingVault`                |
| Withdraw             | `StakingVault.withdraw()`     |
| Check earned rewards | `StakingVault.earned()`       |
| Claim rewards        | `StakingVault.claimRewards()` |
| Exit                 | `StakingVault.exit()`         |

### Protocol statistics

The dashboard can expose protocol-level information such as:

* Total value staked
* Reward emission rate
* Remaining reward pool
* Current reward accrual
* User staking position
* User claimable rewards

## Local Development

The frontend is designed to work with a local **Foundry/Anvil** development environment.

Start Anvil:

```bash
anvil
```

Deploy the StakeVault contracts from the backend/contracts project:

```bash
forge script script/Deploy.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Then start the frontend development server:

```bash
npm install
npm run dev
```

The Vite development server will normally be available at:

```text
http://localhost:5173
```

## Environment Variables

Create a `.env` file in the frontend directory.

```env
VITE_STAKING_VAULT_ADDRESS=your_staking_vault_address
VITE_STAKE_TOKEN_ADDRESS=your_stake_token_address
VITE_REWARD_TOKEN_ADDRESS=your_reward_token_address
VITE_CHAIN_ID=31337
```

> Never expose private keys or wallet seed phrases in frontend environment variables.

`VITE_` variables are bundled into the client application, so they should only contain public configuration such as contract addresses and network IDs.

## Wallet Setup

For local development:

1. Start Anvil.
2. Import an Anvil test account into MetaMask.
3. Configure MetaMask for the local Anvil network.
4. Ensure the frontend is configured with the deployed contract addresses.
5. Connect the wallet through the StakeVault frontend.

The frontend should automatically refresh blockchain state after relevant transactions are confirmed.

## User Flow

```text
Connect Wallet
      │
      ▼
View STAKE Balance
      │
      ▼
Approve STAKE
      │
      ▼
Stake STAKE Tokens
      │
      ▼
Earn REWARD Tokens
      │
      ├───────────────┐
      ▼               ▼
   Withdraw        Claim Rewards
      │               │
      └───────┬───────┘
              ▼
             Exit
```

## Technology Stack

* **React**
* **Vite**
* **Ethers.js**
* **JavaScript**
* **Solidity**
* **Foundry**
* **Anvil**
* **OpenZeppelin**

## Project Structure

```text
frontend/
├── public/
├── src/
│   ├── components/
│   ├── contracts/
│   ├── hooks/
│   ├── utils/
│   ├── App.jsx
│   └── main.jsx
├── .env
├── package.json
├── vite.config.js
└── README.md
```

The exact structure may evolve as additional frontend functionality is implemented.

## Development Goals

The frontend is intended to provide a clean interface for testing and demonstrating the StakeVault protocol while keeping blockchain interactions transparent.

Future improvements may include:

* 📈 Reward and staking history charts
* 🔔 Transaction status notifications
* 🌐 Network switching
* 🌓 Dark/light theme
* 📱 Mobile-responsive dashboard
* 🧾 Transaction history
* ⏱️ Reward countdowns and emission information
* 🛡️ Improved transaction/error handling
* 🔐 Additional wallet connection options

## Related Contracts

The frontend is designed to work with the StakeVault smart-contract system, including:

* `StakingVault.sol`
* `StakeToken.sol`
* `RewardToken.sol`

The smart contracts contain the protocol's core staking and reward logic. The frontend is responsible for presenting that functionality and submitting user-authorized transactions.

## License

This project is intended for development and educational purposes.
