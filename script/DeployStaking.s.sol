// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {StakeToken} from "../src/tokens/StakeToken.sol";
import {RewardToken} from "../src/tokens/RewardToken.sol";
import {StakingVault} from "../src/staking/StakingVault.sol";

/**
 * @title DeployStaking
 * @notice Deploys and configures the complete V1 DeFi staking protocol.
 *
 * @dev
 * Deployment order:
 *
 * 1. Deploy StakeToken.
 * 2. Deploy RewardToken.
 * 3. Deploy StakingVault using both token addresses.
 * 4. Approve the vault to pull the initial REWARD allocation.
 * 5. Fund the vault with the approved REWARD tokens.
 * 6. Configure the reward emission rate.
 *
 * The deployer becomes the owner of all three contracts.
 *
 * Initial deployment configuration:
 *
 *      Reward Fund:  100,000 REWARD
 *      Reward Rate:  1 REWARD per second
 *
 * Token and vault relationship:
 *
 *      StakeToken
 *          │
 *          │ STAKE
 *          ▼
 *      StakingVault
 *          │
 *          │ REWARD
 *          ▼
 *      RewardToken
 *
 * Reward funding flow:
 *
 *      Deployer
 *          │
 *          │ approve(REWARD_FUND)
 *          ▼
 *      StakingVault
 *          │
 *          │ fundRewards(REWARD_FUND)
 *          ▼
 *      Funded Reward Pool
 *
 * The vault does not mint REWARD tokens.
 *
 * The deployment script uses an ERC-20 allowance so that the vault
 * can pull the configured REWARD allocation from the deployer's
 * balance through `fundRewards()`.
 *
 * The reward rate determines how quickly the funded reward pool
 * can be distributed to eligible stakers.
 */
contract DeployStaking is Script {
    /**
     * @notice Initial amount of REWARD tokens allocated to the vault.
     * @dev 100,000 REWARD assuming 18 decimals.
     */
    uint256 private constant REWARD_FUND = 100_000 ether;

    /**
     * @notice Reward emission rate configured for the vault.
     * @dev 1 REWARD token per second.
     */
    uint256 private constant REWARD_RATE = 1 ether;

    /**
     * @notice Deploys and configures all staking protocol contracts.
     *
     * @return stakeToken The deployed STAKE token.
     * @return rewardToken The deployed REWARD token.
     * @return stakingVault The deployed staking vault.
     */
    function run() external returns (StakeToken stakeToken, RewardToken rewardToken, StakingVault stakingVault) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // ---------------------------------------------------------
        // 1. Deploy STAKE token
        // ---------------------------------------------------------

        stakeToken = new StakeToken();

        // ---------------------------------------------------------
        // 2. Deploy REWARD token
        // ---------------------------------------------------------

        rewardToken = new RewardToken();

        // ---------------------------------------------------------
        // 3. Deploy staking vault
        // ---------------------------------------------------------

        stakingVault = new StakingVault(address(stakeToken), address(rewardToken));

        // ---------------------------------------------------------
        // 4. Approve vault to pull REWARD
        // ---------------------------------------------------------

        /**
         * @dev
         * `fundRewards()` pulls REWARD tokens from the caller.
         *
         * The deployer therefore grants the staking vault permission
         * to transfer the configured reward allocation.
         */
        rewardToken.approve(address(stakingVault), REWARD_FUND);

        // ---------------------------------------------------------
        // 5. Fund vault
        // ---------------------------------------------------------

        /**
         * @dev
         * Transfers the approved REWARD allocation into the vault
         * and registers the amount as funded rewards.
         */
        stakingVault.fundRewards(REWARD_FUND);

        // ---------------------------------------------------------
        // 6. Configure emission rate
        // ---------------------------------------------------------

        /**
         * @dev
         * Sets the amount of REWARD that can be emitted per second.
         */
        stakingVault.setRewardRate(REWARD_RATE);

        // ---------------------------------------------------------
        // Deployment logs
        // ---------------------------------------------------------

        console2.log("========================================");
        console2.log("DeFi Staking Deployment");
        console2.log("========================================");
        console2.log("StakeToken:   ", address(stakeToken));
        console2.log("RewardToken:  ", address(rewardToken));
        console2.log("StakingVault: ", address(stakingVault));
        console2.log("Reward Fund:  ", REWARD_FUND);
        console2.log("Reward Rate:  ", REWARD_RATE);
        console2.log("========================================");

        vm.stopBroadcast();
    }
}
