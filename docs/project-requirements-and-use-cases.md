# DeFi Staking Platform — Project Requirements & Use Cases

## 1. Project Overview

The DeFi Staking Platform is a decentralized staking protocol built with Solidity and Foundry.

The platform allows users to deposit an ERC-20 staking token (`STAKE`) into a staking vault and earn rewards in a separate ERC-20 reward token (`REWARD`) over time.

The protocol uses a finite reward pool. Reward tokens must first be funded into the `StakingVault` by the protocol owner before they can be distributed to stakers.

### Core Components

The protocol consists of three core smart contracts:

* `StakeToken.sol` — ERC-20 token used for staking.
* `RewardToken.sol` — ERC-20 token used for staking rewards.
* `StakingVault.sol` — Core contract responsible for staking, withdrawals, reward accounting, reward distribution, and administration.

The frontend application is planned as the application layer and will interact with the deployed smart contracts through a Web3 library.

---

## 2. Problem Statement

Traditional staking systems often require centralized infrastructure for tracking deposits, calculating rewards, and distributing returns.

This project demonstrates how these functions can be implemented transparently and programmatically using smart contracts.

The platform is designed to provide:

* Transparent on-chain staking accounting.
* Automated reward calculation.
* Proportional reward distribution.
* Non-custodial user staking.
* Controlled reward funding.
* Protection against distributing more rewards than have been funded.

---

## 3. Project Objectives

The main objectives are to:

1. Develop a functional Solidity-based staking protocol.
2. Allow users to stake ERC-20 tokens.
3. Calculate rewards based on staking positions and elapsed time.
4. Distribute rewards using a cumulative reward-per-token accounting model.
5. Ensure rewards cannot exceed the funded reward pool.
6. Provide secure withdrawal and reward-claiming mechanisms.
7. Apply common smart-contract security patterns.
8. Thoroughly test the smart contracts using Foundry.
9. Provide a Web3 frontend for interacting with the protocol.
10. Deploy and document the completed application.

---

## 4. Target Users

### 4.1 Stakers

Users who want to deposit `STAKE` tokens and earn `REWARD` tokens.

Stakers can:

* Stake tokens.
* View their staking position.
* View accumulated rewards.
* Claim rewards.
* Withdraw their stake.
* Exit the protocol by claiming rewards and withdrawing their full position.

### 4.2 Protocol Owner / Treasury

The protocol owner is responsible for administrative operations.

The owner can:

* Fund the reward pool.
* Configure the reward emission rate.
* Pause the staking system.
* Unpause the staking system.

The owner cannot directly modify individual user staking balances.

---

# 5. Functional Requirements

## FR-01 — Stake Tokens

The system shall allow a user to deposit `STAKE` tokens into the `StakingVault`.

Before staking, the user must approve the vault to transfer the required amount of `STAKE`.

The vault shall:

1. Validate that the amount is greater than zero.
2. Update the user's pending rewards.
3. Transfer `STAKE` from the user to the vault.
4. Increase the user's staking balance.
5. Increase the total amount staked.
6. Emit a `Staked` event.

---

## FR-02 — Withdraw Stake

The system shall allow users to withdraw previously deposited `STAKE`.

The vault shall:

1. Validate that the withdrawal amount is greater than zero.
2. Verify that the user has sufficient stake.
3. Update reward accounting.
4. Reduce the user's staking position.
5. Reduce total staked amount.
6. Transfer `STAKE` back to the user.
7. Emit a `Withdrawn` event.

---

## FR-03 — Reward Accumulation

Rewards shall accumulate over time based on:

* The user's staking amount.
* Total amount staked.
* Reward emission rate.
* Time elapsed.

The protocol uses cumulative `rewardPerToken` accounting rather than iterating through all stakers.

This allows reward calculations to remain efficient as the number of users increases.

---

## FR-04 — Reward Funding

The protocol owner shall be able to fund the vault with `REWARD` tokens.

The owner must approve the vault before funding.

When rewards are funded:

1. The vault updates global reward accounting.
2. `REWARD` tokens are transferred into the vault.
3. The funded reward balance increases.
4. A `RewardsFunded` event is emitted.

The vault does not mint reward tokens.

---

## FR-05 — Reward Emission

The protocol owner shall be able to configure the reward emission rate.

The reward rate represents the amount of `REWARD` emitted per second.

When the rate changes, previous reward periods are accounted for before the new rate is applied.

This prevents a new reward rate from being applied retroactively.

---

## FR-06 — Finite Reward Pool

The protocol shall prevent reward emissions from exceeding the amount of rewards funded into the vault.

The emitted reward shall never exceed the remaining funded reward balance.

When the reward pool becomes exhausted, reward emission stops until additional rewards are funded.

---

## FR-07 — Claim Rewards

Users shall be able to claim their accumulated `REWARD` tokens.

The system shall:

1. Update the user's reward accounting.
2. Read the user's claimable rewards.
3. Reject the transaction if no rewards are available.
4. Reset the user's accrued reward balance.
5. Transfer `REWARD` to the user.
6. Emit a `RewardClaimed` event.

---

## FR-08 — Exit

Users shall be able to exit the protocol using a single transaction.

The exit operation shall:

1. Update reward accounting.
2. Calculate the user's accrued rewards.
3. Clear the user's reward balance.
4. Clear the user's staking position.
5. Reduce total staked amount.
6. Transfer rewards if available.
7. Transfer the user's entire `STAKE` position.
8. Emit the appropriate events.

The function shall allow a user to exit even when they have no rewards.

---

## FR-09 — Pause and Unpause

The protocol owner shall be able to pause the staking vault during an emergency or maintenance period.

While paused:

* Staking is disabled.
* Withdrawals are disabled.
* Reward claims are disabled.

Administrative reward funding and configuration remain available according to the contract implementation.

The owner shall also be able to unpause the protocol.

---

## FR-10 — Access Control

Administrative functions shall be restricted to the protocol owner.

Owner-only functions include:

* `fundRewards()`
* `setRewardRate()`
* `pause()`
* `unpause()`

Unauthorized users shall not be able to execute these functions.

---

# 6. Non-Functional Requirements

## NFR-01 — Security

The protocol shall use established smart-contract security mechanisms, including:

* OpenZeppelin `Ownable`
* OpenZeppelin `ReentrancyGuard`
* OpenZeppelin `Pausable`
* OpenZeppelin `SafeERC20`

The system shall validate zero addresses and invalid amounts.

---

## NFR-02 — Reward Safety

The protocol shall never intentionally emit more rewards than have been funded.

The reward pool shall be tracked independently through the remaining reward budget.

---

## NFR-03 — Efficient Reward Accounting

The protocol shall use cumulative reward-per-token accounting rather than looping through every staker.

This avoids unbounded iteration over user addresses.

---

## NFR-04 — Transparency

Important protocol actions shall emit events that can be observed on-chain.

Events include:

* `Staked`
* `Withdrawn`
* `RewardClaimed`
* `RewardsFunded`
* `RewardRateUpdated`

---

## NFR-05 — Testability

The smart contracts shall be tested using Foundry.

The current test suite contains:

* 11 `StakeToken` tests.
* 13 `RewardToken` tests.
* 53 `StakingVault` tests.

Current result:

**77 tests passed, 0 failed, 0 skipped.**

---

# 7. Main User Use Cases

## Use Case 1 — User Stakes Tokens

**Actor:** Staker

**Preconditions:**

* User owns `STAKE`.
* User has approved the vault to spend `STAKE`.
* Vault is not paused.

**Flow:**

1. User chooses an amount to stake.
2. User approves the vault.
3. User calls `stake(amount)`.
4. Vault updates reward accounting.
5. Vault transfers `STAKE` from the user.
6. User's staking position increases.
7. Total staked amount increases.
8. `Staked` event is emitted.

**Result:**

The user has an active staking position.

---

## Use Case 2 — User Checks Rewards

**Actor:** Staker

**Flow:**

1. User provides their wallet address.
2. The protocol calculates the current reward-per-token value.
3. The user's pending reward is calculated.
4. The user can view their claimable reward.

**Result:**

The user can determine how much `REWARD` they have earned.

---

## Use Case 3 — User Claims Rewards

**Actor:** Staker

**Preconditions:**

* User has claimable rewards.
* Vault has sufficient reward balance.
* Vault is not paused.

**Flow:**

1. User calls `claimRewards()`.
2. Vault updates reward accounting.
3. Claimable rewards are determined.
4. Reward balance is reset.
5. `REWARD` is transferred to the user.
6. `RewardClaimed` is emitted.

**Result:**

The user receives their accumulated reward tokens.

---

## Use Case 4 — User Withdraws

**Actor:** Staker

**Preconditions:**

* User has sufficient stake.
* Vault is not paused.

**Flow:**

1. User specifies withdrawal amount.
2. Vault updates reward accounting.
3. User's staking balance decreases.
4. Total staked amount decreases.
5. `STAKE` is transferred back to the user.
6. `Withdrawn` is emitted.

**Result:**

The user receives the withdrawn staking tokens.

---

## Use Case 5 — User Exits

**Actor:** Staker

**Flow:**

1. User calls `exit()`.
2. Vault updates reward accounting.
3. Accrued rewards are calculated.
4. User's reward balance is cleared.
5. User's staking balance is cleared.
6. Total staked amount is reduced.
7. Rewards are transferred if available.
8. The entire staking position is returned.
9. Relevant events are emitted.

**Result:**

The user leaves the staking pool and receives their remaining stake and available rewards.

---

## Use Case 6 — Owner Funds Rewards

**Actor:** Protocol Owner

**Preconditions:**

* Owner owns `REWARD`.
* Owner has approved the vault.
* Funding amount is greater than zero.

**Flow:**

1. Owner calls `fundRewards(amount)`.
2. Vault updates global reward accounting.
3. `REWARD` is transferred to the vault.
4. Remaining reward budget increases.
5. `RewardsFunded` is emitted.

**Result:**

The vault has additional rewards available for future emission.

---

## Use Case 7 — Owner Changes Reward Rate

**Actor:** Protocol Owner

**Flow:**

1. Owner calls `setRewardRate(newRate)`.
2. Existing reward accounting is updated.
3. Previous reward rate is recorded.
4. New reward rate is stored.
5. `RewardRateUpdated` is emitted.

**Result:**

Future reward emission uses the new rate.

---

## Use Case 8 — Owner Pauses Protocol

**Actor:** Protocol Owner

**Flow:**

1. Owner calls `pause()`.
2. The vault enters the paused state.
3. Staking, withdrawals, and reward claims are blocked.

**Result:**

User-facing state-changing operations are temporarily disabled.

---

# 8. Security and Edge Cases

The protocol is designed to handle several important edge cases:

* Zero staking amount.
* Zero withdrawal amount.
* Withdrawal greater than user's stake.
* Claiming when no rewards are available.
* Zero token addresses during deployment.
* Unauthorized administrative operations.
* Operations while the vault is paused.
* Reward pool exhaustion.
* Reward balance insufficient for a claim.
* Multiple users staking simultaneously.
* Multiple deposits by the same user.
* Reward rate changes.
* Reward accounting when no users are staking.

The protocol also uses `nonReentrant` protection for state-changing user and reward-funding operations.

---

# 9. Current Implementation Status

### Completed

* Stake token contract.
* Reward token contract.
* Staking vault contract.
* Staking functionality.
* Withdrawal functionality.
* Reward accounting.
* Reward claiming.
* Exit functionality.
* Reward funding.
* Reward rate configuration.
* Pause/unpause functionality.
* Access control.
* Foundry unit and edge-case testing.
* Deployment script.
* GitHub repository publication.

### In Progress / Planned

* React frontend implementation.
* Web3 contract integration.
* Wallet connection.
* Blockchain network integration.
* Additional gas optimization review.
* SCAI network deployment.
* Vercel deployment.
* Final project documentation.
* Demonstration video.

---

# 10. Success Criteria

The project will be considered complete when:

1. The smart contracts are fully tested.
2. Users can stake and withdraw through the DApp.
3. Users can view and claim rewards.
4. Wallet connectivity works correctly.
5. The frontend interacts successfully with the deployed contracts.
6. Reward distribution respects the funded reward pool.
7. The application is deployed to the required blockchain network.
8. The frontend is deployed and accessible.
9. The GitHub repository contains complete documentation.
10. A final demonstration of the working application is available.

---

## 11. Technology Stack

### Smart Contracts

* Solidity `^0.8.30`
* Foundry
* OpenZeppelin Contracts

### Token Standard

* ERC-20

### Security Components

* `Ownable`
* `ReentrancyGuard`
* `Pausable`
* `SafeERC20`

### Planned Application Layer

* React
* ethers.js
* Web3 wallet integration
* Vercel deployment

---

## 12. Project Repository

The source code and tests are maintained in the project's GitHub repository.

The repository contains the smart contracts, tests, deployment scripts, and frontend project structure.
