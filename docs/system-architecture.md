# DeFi Staking Platform — System Architecture Design

## 1. Architecture Overview

The DeFi Staking Platform is designed as a modular smart-contract system consisting of two ERC-20 token contracts and a central staking vault.

The core architecture consists of:

1. `StakeToken` — ERC-20 token deposited by users.
2. `RewardToken` — ERC-20 token distributed as staking rewards.
3. `StakingVault` — Core protocol contract responsible for staking, withdrawals, reward accounting, reward distribution, and administrative controls.

A React/Web3 frontend is planned as the application layer and will interact with the smart contracts through a Web3 library.

### High-Level Architecture

```text
                         ┌──────────────────────┐
                         │         User         │
                         │                      │
                         │  Stake / Withdraw    │
                         │  Claim / Exit        │
                         └──────────┬───────────┘
                                    │
                                    │ Web3 transactions
                                    ▼
                         ┌──────────────────────┐
                         │    React Frontend    │
                         │      [PLANNED]       │
                         └──────────┬───────────┘
                                    │
                                    │ ethers.js
                                    ▼
                  ┌──────────────────────────────────┐
                  │          StakingVault             │
                  │                                  │
                  │  stake()                         │
                  │  withdraw()                      │
                  │  claimRewards()                  │
                  │  exit()                          │
                  │                                  │
                  │  fundRewards()                   │
                  │  setRewardRate()                 │
                  │  pause() / unpause()             │
                  └──────────────┬───────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    │ STAKE                   │ REWARD
                    │                         │
                    ▼                         ▼
             ┌───────────────┐       ┌────────────────┐
             │  StakeToken   │       │  RewardToken   │
             │    ERC-20     │       │     ERC-20     │
             └───────────────┘       └────────────────┘
```

---

# 2. Smart Contract Components

## 2.1 StakeToken

### Responsibility

`StakeToken.sol` is the ERC-20 token used as the staking asset.

Users transfer this token into `StakingVault` when creating or increasing their staking position.

### Responsibilities

* Maintain STAKE token balances.
* Provide ERC-20 transfers.
* Provide ERC-20 approvals.
* Allow the vault to transfer approved tokens from users.

### Interaction

```text
User
  │
  │ approve()
  ▼
StakeToken
  │
  │ transferFrom()
  ▼
StakingVault
```

The token contract does not calculate rewards or maintain staking positions.

---

# 3. RewardToken

## Responsibility

`RewardToken.sol` is the ERC-20 token used to pay staking rewards.

The `StakingVault` does not mint rewards.

Instead, the protocol owner or treasury transfers existing `REWARD` tokens into the vault through `fundRewards()`.

### Reward Funding Flow

```text
Protocol Owner / Treasury
          │
          │ approve()
          ▼
     RewardToken
          │
          │ transferFrom()
          ▼
     StakingVault
          │
          │ reward budget
          ▼
       Stakers
```

This creates a finite reward pool.

---

# 4. StakingVault

`StakingVault.sol` is the core protocol contract.

It coordinates:

* User deposits.
* User withdrawals.
* Reward accounting.
* Reward claims.
* Full exits.
* Reward funding.
* Reward rate configuration.
* Emergency pause controls.

---

# 5. StakingVault State Architecture

The vault maintains global and user-specific accounting.

## Global State

```text
_totalStaked
_rewardRate
_rewardPerTokenStored
_lastUpdateTime
_rewardRemaining
```

### `_totalStaked`

Tracks the total amount of `STAKE` currently deposited into the vault.

### `_rewardRate`

Defines how many `REWARD` tokens are emitted per second.

### `_rewardPerTokenStored`

Stores cumulative reward allocation per unit of staked `STAKE`.

### `_lastUpdateTime`

Stores the timestamp at which global reward accounting was last updated.

### `_rewardRemaining`

Tracks funded rewards that have not yet been emitted.

This prevents the protocol from distributing more rewards than have been funded.

---

# 6. User State Architecture

Each user has a `UserInfo` structure:

```solidity
struct UserInfo {
    uint256 amount;
    uint256 rewardPerTokenPaid;
    uint256 rewards;
}
```

### `amount`

The user's current STAKE position.

### `rewardPerTokenPaid`

The cumulative reward-per-token value that was accounted for during the user's last update.

### `rewards`

Previously accrued rewards that have not yet been claimed.

---

# 7. Reward Accounting Architecture

The protocol uses a cumulative `rewardPerToken` model.

It does not loop through every staker whenever rewards are generated.

### Reward Calculation

Conceptually:

```text
elapsed time
     │
     ▼
elapsed × rewardRate
     │
     ▼
potential reward
     │
     ▼
min(potential reward, rewardRemaining)
     │
     ▼
emitted reward
     │
     ▼
emitted reward / totalStaked
     │
     ▼
rewardPerToken increase
```

The protocol uses `1e18` precision for reward-per-token calculations.

---

# 8. Finite Reward Pool

One of the core design principles is that reward emission is limited by funded rewards.

The relationship is:

```text
emittedReward <= rewardRemaining
```

When rewards are emitted:

```text
rewardRemaining
        │
        │ - emittedReward
        ▼
updated rewardRemaining
```

When the reward pool reaches zero:

```text
rewardRemaining = 0
        │
        ▼
No additional rewards are emitted
```

Additional rewards must then be supplied through `fundRewards()`.

---

# 9. User Staking Workflow

## Stake Flow

```text
User
 │
 │ 1. approve(STAKE)
 ▼
StakeToken
 │
 │ 2. stake(amount)
 ▼
StakingVault
 │
 ├── Validate amount
 │
 ├── Update reward accounting
 │
 ├── transferFrom(user, vault, amount)
 │
 ├── Increase user.amount
 │
 ├── Increase _totalStaked
 │
 └── Emit Staked
```

### Result

The user's STAKE becomes part of the vault's staking pool.

---

# 10. Withdrawal Workflow

```text
User
 │
 │ withdraw(amount)
 ▼
StakingVault
 │
 ├── Validate amount
 │
 ├── Check user balance
 │
 ├── Update reward accounting
 │
 ├── Reduce user.amount
 │
 ├── Reduce _totalStaked
 │
 ├── Transfer STAKE to user
 │
 └── Emit Withdrawn
```

---

# 11. Reward Claim Workflow

```text
User
 │
 │ claimRewards()
 ▼
StakingVault
 │
 ├── Update reward accounting
 │
 ├── Calculate earned reward
 │
 ├── Check reward > 0
 │
 ├── Check vault REWARD balance
 │
 ├── Set user rewards = 0
 │
 ├── Transfer REWARD
 │
 └── Emit RewardClaimed
```

The user's staking position remains unchanged after claiming rewards.

---

# 12. Exit Workflow

The `exit()` function combines reward claiming and full withdrawal.

```text
User
 │
 │ exit()
 ▼
StakingVault
 │
 ├── Update reward accounting
 │
 ├── Read reward
 │
 ├── Read staking amount
 │
 ├── Clear user rewards
 │
 ├── Clear user stake
 │
 ├── Reduce _totalStaked
 │
 ├── Transfer REWARD if available
 │
 ├── Transfer STAKE
 │
 └── Emit events
```

This provides users with a single transaction for leaving the protocol.

---

# 13. Reward Funding Workflow

Reward funding is controlled by the protocol owner.

```text
Owner / Treasury
       │
       │ approve(REWARD)
       ▼
RewardToken
       │
       │ fundRewards(amount)
       ▼
StakingVault
       │
       ├── Update global accounting
       │
       ├── transferFrom(owner, vault, amount)
       │
       ├── Increase _rewardRemaining
       │
       └── Emit RewardsFunded
```

The vault does not mint reward tokens.

---

# 14. Reward Rate Configuration

The protocol owner can update the reward emission rate.

```text
Owner
 │
 │ setRewardRate(newRate)
 ▼
StakingVault
 │
 ├── Update existing reward accounting
 │
 ├── Store old rate
 │
 ├── Set new rate
 │
 └── Emit RewardRateUpdated
```

Updating global accounting before changing the rate prevents the new rate from being applied retroactively.

---

# 15. Pause Architecture

The vault uses OpenZeppelin `Pausable`.

When the vault is paused:

```text
PAUSED
  │
  ├── stake()       BLOCKED
  ├── withdraw()    BLOCKED
  └── claimRewards() BLOCKED
```

Administrative operations such as reward funding and reward-rate configuration remain available according to the contract implementation.

The owner can call:

```text
pause()
unpause()
```

---

# 16. Security Architecture

The protocol uses established OpenZeppelin security components.

## Ownable

Controls administrative operations.

Owner-only operations include:

* `fundRewards()`
* `setRewardRate()`
* `pause()`
* `unpause()`

## ReentrancyGuard

State-changing operations that transfer tokens are protected using `nonReentrant`.

Protected operations include:

* `stake()`
* `withdraw()`
* `claimRewards()`
* `exit()`
* `fundRewards()`

## Pausable

Allows the owner to stop critical user operations during an emergency.

## SafeERC20

Token transfers use OpenZeppelin `SafeERC20` to safely interact with ERC-20 tokens.

---

# 17. Contract Interaction Model

The contracts have deliberately separated responsibilities.

```text
┌────────────────┐
│  StakeToken    │
│                │
│ ERC-20 asset   │
└───────┬────────┘
        │
        │ staking asset
        ▼
┌────────────────┐
│ StakingVault   │
│                │
│ Core protocol  │
│ accounting     │
└───────▲────────┘
        │
        │ reward asset
        │
┌───────┴────────┐
│  RewardToken   │
│                │
│ ERC-20 reward  │
└────────────────┘
```

The token contracts remain responsible for token accounting, while the vault is responsible for staking and reward logic.

---

# 18. Frontend Architecture

The frontend is planned as a React-based Web3 application.

```text
┌─────────────────────────────┐
│        React Frontend       │
│                             │
│ Dashboard                   │
│ Staking Interface           │
│ Rewards Interface           │
│ Transaction Status          │
└──────────────┬──────────────┘
               │
               │ ethers.js
               ▼
┌─────────────────────────────┐
│       Web3 Wallet           │
│       [PLANNED]             │
│                             │
│ MetaMask / compatible       │
│ wallet provider             │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│     Blockchain Network      │
│        [PLANNED]            │
└──────────────┬──────────────┘
               │
               ▼
        StakingVault
        /           \
 StakeToken      RewardToken
```

The frontend is currently in the design/planning stage and has not yet been fully integrated with the smart contracts.

---

# 19. Deployment Architecture

The planned production architecture is:

```text
User Browser
     │
     ▼
Vercel
     │
     │ React Application
     ▼
Web3 Wallet
     │
     │ Transactions
     ▼
SCAI Network
     │
     ├── StakeToken
     ├── RewardToken
     └── StakingVault
```

The SCAI network and Vercel deployment are planned project deliverables and are not yet represented as completed deployment stages.

---

# 20. Testing Architecture

The smart-contract system is tested using Foundry.

Current test distribution:

```text
StakeToken
   └── 11 tests

RewardToken
   └── 13 tests

StakingVault
   └── 53 tests

Total
   └── 77 tests
```

Current result:

```text
77 passed
0 failed
0 skipped
```

The `StakingVault` tests cover:

* Staking.
* Withdrawals.
* Reward calculations.
* Multiple users.
* Multiple deposits.
* Reward claims.
* Exit.
* Reward funding.
* Reward rate changes.
* Reward pool exhaustion.
* Access control.
* Pause behavior.
* Invalid inputs.
* Events.
* Accounting invariants.

---

# 21. Architecture Principles

The project follows several design principles:

### Separation of Responsibilities

Token contracts manage token balances while `StakingVault` manages staking and reward logic.

### No Reward Minting by the Vault

The vault distributes previously funded `REWARD` tokens rather than minting new rewards.

### Finite Reward Emission

Reward emission is bounded by the funded reward pool.

### Efficient Accounting

Cumulative reward-per-token accounting avoids iterating over all stakers.

### Secure Token Transfers

Token transfers use OpenZeppelin `SafeERC20`.

### Administrative Separation

Protocol configuration is restricted to the owner.

### Emergency Control

The owner can pause critical user operations.

---

# 22. Current Architecture Status

## Implemented

* `StakeToken.sol`
* `RewardToken.sol`
* `StakingVault.sol`
* Reward accounting system
* Finite reward pool
* User staking lifecycle
* Owner administration
* Pause controls
* Security protections
* Foundry testing
* Deployment script

## In Progress / Planned

* React frontend
* Wallet integration
* ethers.js contract integration
* Blockchain network integration
* Gas optimization review
* SCAI deployment
* Vercel deployment
* Final documentation
* Demo video

---

# 23. Conclusion

The current smart-contract architecture provides a modular foundation for a decentralized staking protocol.

`StakeToken` represents the asset being staked, `RewardToken` represents the reward asset, and `StakingVault` acts as the central protocol layer responsible for staking positions and reward distribution.

The architecture is designed to keep token functionality separate from protocol accounting while using established OpenZeppelin security components.

The next development phase is the integration of the React frontend and Web3 wallet functionality with the deployed smart contracts.
