// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {StakeToken} from "../src/tokens/StakeToken.sol";
import {RewardToken} from "../src/tokens/RewardToken.sol";
import {StakingVault} from "../src/staking/StakingVault.sol";

/**
 * @title DeployStaking
 * @notice Deploys the complete V1 DeFi staking protocol.
 *
 * @dev
 * Deployment order:
 *
 * 1. Deploy StakeToken.
 * 2. Deploy RewardToken.
 * 3. Deploy StakingVault using both token addresses.
 *
 * The deployer becomes the owner of all three contracts.
 *
 * After deployment:
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
 * The vault does not mint REWARD tokens.
 * Rewards must be transferred into the vault and funded through
 * `fundRewards()`.
 */
contract DeployStaking is Script {
    /**
     * @notice Deploys all staking protocol contracts.
     *
     * @return stakeToken The deployed STAKE token.
     * @return rewardToken The deployed REWARD token.
     * @return stakingVault The deployed staking vault.
     */
    function run() external returns (StakeToken stakeToken, RewardToken rewardToken, StakingVault stakingVault) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // ---------------------------------------------------------
        // Deploy STAKE token
        // ---------------------------------------------------------

        stakeToken = new StakeToken();

        // ---------------------------------------------------------
        // Deploy REWARD token
        // ---------------------------------------------------------

        rewardToken = new RewardToken();

        // ---------------------------------------------------------
        // Deploy staking vault
        // ---------------------------------------------------------

        stakingVault = new StakingVault(address(stakeToken), address(rewardToken));

        // ---------------------------------------------------------
        // Log deployed addresses
        // ---------------------------------------------------------

        console2.log("StakeToken:", address(stakeToken));
        console2.log("RewardToken:", address(rewardToken));
        console2.log("StakingVault:", address(stakingVault));

        vm.stopBroadcast();
    }
}
