# Smart Contract Development — DeFi Staking Platform

## 1. Overview

The DeFi Staking Platform is built around three Solidity smart contracts:

```text
src/
├── staking/
│   └── StakingVault.sol
└── tokens/
    ├── StakeToken.sol
    └── RewardToken.sol
```

The contracts implement a decentralized staking system where users deposit `STAKE` tokens into a vault and earn `REWARD` tokens over time.

The protocol uses a finite reward pool. Rewards must first be funded into the vault before they can be distributed to users.

---

## 2. StakeToken

### Contract

```text
src/tokens/StakeToken.sol
```

### Purpose

`StakeToken` is the ERC-20 token used by users as the staking asset.

Users must hold `STAKE` tokens and approve the `StakingVault` before depositing tokens into the protocol.

### Core ERC-20 Functionality

The token supports standard ERC-20 operations, including:

* `transfer`
* `approve`
* `transferFrom`
* Balance tracking
* Total supply tracking

The `StakingVault` uses `transferFrom()` to move approved `STAKE` tokens from users into the vault.

---

## 3. RewardToken

### Contract

```text
src/tokens/RewardToken.sol
```

### Purpose

`RewardToken` is the ERC-20 token distributed to users as staking rewards.

The `StakingVault` does not mint new reward tokens. Instead, the protocol owner funds the vault with existing `REWARD` tokens.

This separates token issuance from staking reward distribution.

---

## 4. StakingVault

### Contract

```text
src/staking/StakingVault.sol
```

`StakingVault` is the core protocol contract.

It manages:

* User staking positions
* Total staked assets
* Reward accumulation
* Reward claims
* Withdrawals
* Full exits
* Reward funding
* Reward emission rates
* Administrative controls
* Emergency pause functionality

---

# 5. User Staking Functions

## `stake(uint256 amount)`

Allows a user to deposit `STAKE` tokens into the vault.

### Process

1. Validates that the amount is greater than zero.
2. Updates the user's pending reward accounting.
3. Transfers `STAKE` from the user into the vault.
4. Increases the user's staking balance.
5. Increases the total amount staked.
6. Emits a `Staked` event.

Users must approve the vault before calling this function.

---

## `withdraw(uint256 amount)`

Allows a user to withdraw part or all of their staked tokens.

### Process

1. Validates that the amount is greater than zero.
2. Verifies that the user has sufficient stake.
3. Updates reward accounting before changing the staking position.
4. Reduces the user's staking balance.
5. Reduces total staked.
6. Transfers `STAKE` back to the user.
7. Emits a `Withdrawn` event.

---

## `claimRewards()`

Allows users to claim their accumulated `REWARD` tokens.

### Process

1. Updates reward accounting.
2. Calculates the user's accrued rewards.
3. Reverts if no rewards are available.
4. Clears the user's stored reward balance.
5. Verifies the vault can satisfy the payment.
6. Transfers `REWARD` to the user.
7. Emits a `RewardClaimed` event.

Claiming rewards does not affect the user's staking position.

---

## `exit()`

Allows a user to leave the staking protocol in a single transaction.

The function combines:

* Reward claiming
* Full withdrawal

### Process

1. Updates reward accounting.
2. Retrieves the user's rewards and staking amount.
3. Clears the user's reward balance.
4. Clears the user's staking position.
5. Reduces total staked.
6. Transfers `REWARD` if rewards are available.
7. Transfers the user's `STAKE` back.
8. Emits the relevant events.

A user can exit even if they have no accumulated rewards.

---

# 6. Reward Accounting

The protocol uses a cumulative `rewardPerToken` model.

The main accounting variables are:

```solidity
_totalStaked
_rewardRate
_rewardPerTokenStored
_lastUpdateTime
_rewardRemaining
```

### `_totalStaked`

Tracks the total `STAKE` deposited in the vault.

### `_rewardRate`

Defines the number of `REWARD` tokens emitted per second.

### `_rewardPerTokenStored`

Stores the cumulative reward earned per unit of `STAKE`.

### `_lastUpdateTime`

Tracks when reward accounting was last updated.

### `_rewardRemaining`

Tracks the amount of funded `REWARD` that has not yet been emitted.

---

## Reward Calculation

Conceptually:

```text
Elapsed Time
      ×
Reward Rate
      ↓
Potential Reward
      ↓
min(Potential Reward, Reward Remaining)
      ↓
Emitted Reward
      ↓
Reward Per Token Increase
      ↓
User Reward Calculation
```

The contract uses:

```solidity
uint256 private constant PRECISION = 1e18;
```

to maintain precision in reward calculations.

---

# 7. Finite Reward Pool

The protocol does not allow unlimited reward emission.

Before rewards can be distributed, the protocol owner must call:

```solidity
fundRewards(uint256 amount)
```

This transfers `REWARD` tokens into the vault and increases:

```solidity
_rewardRemaining
```

Reward emission is capped by the remaining funded balance.

Conceptually:

```text
emittedReward <= rewardRemaining
```

If the reward pool becomes exhausted, no additional rewards are emitted until more `REWARD` tokens are funded.

This prevents the reward accounting system from intentionally distributing more rewards than the configured funded reward budget.

---

# 8. Administrative Functions

## `fundRewards(uint256 amount)`

Allows the protocol owner to transfer `REWARD` tokens into the vault.

The owner must approve the vault before funding rewards.

The function:

1. Validates the funding amount.
2. Updates global reward accounting.
3. Transfers `REWARD` into the vault.
4. Increases `_rewardRemaining`.
5. Emits `RewardsFunded`.

---

## `setRewardRate(uint256 newRate)`

Allows the owner to configure the number of `REWARD` tokens emitted per second.

Before applying the new rate, the contract updates existing reward accounting.

This ensures that a new reward rate is not applied retroactively.

---

## `pause()`

Allows the owner to pause critical user operations.

---

## `unpause()`

Allows the owner to resume normal protocol operations.

---

# 9. Security Implementation

The `StakingVault` uses OpenZeppelin security components.

## Ownable

Restricts administrative functions to the protocol owner.

Owner-only functions include:

* `fundRewards()`
* `setRewardRate()`
* `pause()`
* `unpause()`

---

## ReentrancyGuard

Functions involving token transfers and state updates use the `nonReentrant` modifier.

Protected functions include:

* `stake()`
* `withdraw()`
* `claimRewards()`
* `exit()`
* `fundRewards()`

---

## Pausable

Allows the protocol owner to pause the following user operations:

* Staking
* Withdrawals
* Reward claims
* Exit

This provides an emergency control mechanism.

---

## SafeERC20

The vault uses OpenZeppelin `SafeERC20` for token transfers.

This provides safer interaction with ERC-20 token contracts.

---

# 10. Error Handling

The staking vault implements custom errors for invalid operations.

Examples include:

```solidity
ZeroAddress
ZeroAmount
InsufficientStake
NoRewards
InsufficientRewardBalance
```

These errors handle invalid contract deployment parameters and invalid user actions.

---

# 11. Events

The protocol emits events for important actions.

### `Staked`

Emitted when a user deposits `STAKE`.

### `Withdrawn`

Emitted when a user withdraws `STAKE`.

### `RewardClaimed`

Emitted when a user receives `REWARD` tokens.

### `RewardsFunded`

Emitted when the reward pool is funded.

### `RewardRateUpdated`

Emitted when the reward emission rate changes.

These events provide transparent on-chain records of important protocol activity.

---

# 12. Deployment

A Foundry deployment script is included:

```text
script/
└── DeployStaking.s.sol
```

The deployment process is designed to deploy and configure the staking system.

The current project also contains local deployment broadcast records for development and testing.

Production deployment to the required SCAI mainnet is a later project phase and is not yet marked as completed.

---

# 13. Development Status

## Completed

* [x] `StakeToken.sol`
* [x] `RewardToken.sol`
* [x] `StakingVault.sol`
* [x] ERC-20 staking flow
* [x] ERC-20 reward distribution
* [x] Multiple deposits
* [x] Partial withdrawals
* [x] Full withdrawals
* [x] Reward accumulation
* [x] Reward claiming
* [x] One-transaction exit
* [x] Finite reward pool
* [x] Reward funding
* [x] Reward emission rate configuration
* [x] Owner access control
* [x] Emergency pause functionality
* [x] Reentrancy protection
* [x] Safe ERC-20 transfers
* [x] Custom errors
* [x] Protocol events
* [x] Foundry deployment script

## Next Development Steps

The following tasks belong to later phases:

* [ ] React frontend integration
* [ ] Smart contract ABI integration
* [ ] Wallet connection
* [ ] Blockchain network integration
* [ ] SCAI mainnet deployment
* [ ] Vercel frontend deployment
* [ ] Final demo video

---

# 14. Conclusion

The core smart contract layer of the DeFi Staking Platform has been implemented using Solidity, OpenZeppelin Contracts, and Foundry.

The protocol supports the complete staking lifecycle, from depositing `STAKE` tokens to accumulating and claiming `REWARD` tokens, withdrawing funds, or exiting the vault entirely.

The reward system uses cumulative reward-per-token accounting and a finite funded reward pool to efficiently distribute rewards without iterating over all stakers.
