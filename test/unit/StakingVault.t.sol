// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {StakeToken} from "../../src/tokens/StakeToken.sol";
import {RewardToken} from "../../src/tokens/RewardToken.sol";
import {StakingVault} from "../../src/staking/StakingVault.sol";

contract StakingVaultTest is Test {
    StakeToken public stakeToken;
    RewardToken public rewardToken;
    StakingVault public vault;

    address public alice;
    address public bob;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    uint256 public constant STAKE_AMOUNT = 100 ether;
    uint256 public constant REWARD_FUND = 10_000 ether;
    uint256 public constant REWARD_RATE = 1 ether;

    // ---------------------------------------------------------------
    //                           SETUP
    // ---------------------------------------------------------------

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        stakeToken = new StakeToken();
        rewardToken = new RewardToken();

        vault = new StakingVault(address(stakeToken), address(rewardToken));

        // Give Alice and Bob STAKE.
        stakeToken.transfer(alice, 10_000 ether);
        stakeToken.transfer(bob, 10_000 ether);

        // Approve the vault to spend their STAKE.
        vm.prank(alice);
        stakeToken.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        stakeToken.approve(address(vault), type(uint256).max);

        // Fund the vault with REWARD.
        rewardToken.approve(address(vault), type(uint256).max);

        vault.fundRewards(REWARD_FUND);

        // Configure the reward emission rate.
        vault.setRewardRate(REWARD_RATE);
    }

    // ---------------------------------------------------------------
    //                         DEPLOYMENT
    // ---------------------------------------------------------------

    function test_StakeTokenAddress() public view {
        assertEq(address(vault.stakeToken()), address(stakeToken));
    }

    function test_RewardTokenAddress() public view {
        assertEq(address(vault.rewardToken()), address(rewardToken));
    }

    function test_Owner() public view {
        assertEq(vault.owner(), address(this));
    }

    function test_InitialTotalStakedIsZero() public view {
        assertEq(vault.totalStaked(), 0);
    }

    function test_InitialRewardRate() public view {
        assertEq(vault.rewardRate(), REWARD_RATE);
    }

    function test_InitialRewardRemaining() public view {
        assertEq(vault.rewardRemaining(), REWARD_FUND);
    }

    // ---------------------------------------------------------------
    //                         STAKE TESTS
    // ---------------------------------------------------------------

    function test_Stake() public {
        vm.prank(alice);

        vault.stake(STAKE_AMOUNT);

        assertEq(vault.totalStaked(), STAKE_AMOUNT);

        (uint256 amount,,) = vault.getUserInfo(alice);

        assertEq(amount, STAKE_AMOUNT);

        assertEq(stakeToken.balanceOf(address(vault)), STAKE_AMOUNT);
    }

    function test_StakeEmitsEvent() public {
        vm.expectEmit(true, false, false, true);

        emit StakingVault.Staked(alice, STAKE_AMOUNT);

        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);
    }

    function test_StakeUpdatesUserBalance() public {
        vm.prank(alice);

        vault.stake(STAKE_AMOUNT);

        assertEq(stakeToken.balanceOf(alice), 10_000 ether - STAKE_AMOUNT);
    }

    function test_StakeMultipleTimes() public {
        vm.startPrank(alice);

        vault.stake(100 ether);
        vault.stake(200 ether);

        vm.stopPrank();

        (uint256 amount,,) = vault.getUserInfo(alice);

        assertEq(amount, 300 ether);

        assertEq(vault.totalStaked(), 300 ether);
    }

    function test_RevertStakeZero() public {
        vm.prank(alice);

        vm.expectRevert(StakingVault.ZeroAmount.selector);

        vault.stake(0);
    }

    // ---------------------------------------------------------------
    //                       WITHDRAW TESTS
    // ---------------------------------------------------------------

    function test_Withdraw() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.prank(alice);
        vault.withdraw(40 ether);

        (uint256 amount,,) = vault.getUserInfo(alice);

        assertEq(amount, 60 ether);

        assertEq(vault.totalStaked(), 60 ether);

        assertEq(stakeToken.balanceOf(alice), 10_000 ether - 60 ether);
    }

    function test_WithdrawEmitsEvent() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.expectEmit(true, false, false, true);

        emit StakingVault.Withdrawn(alice, 50 ether);

        vm.prank(alice);
        vault.withdraw(50 ether);
    }

    function test_WithdrawEntireStake() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.prank(alice);
        vault.withdraw(STAKE_AMOUNT);

        (uint256 amount,,) = vault.getUserInfo(alice);

        assertEq(amount, 0);

        assertEq(vault.totalStaked(), 0);
    }

    function test_RevertWithdrawZero() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.prank(alice);

        vm.expectRevert(StakingVault.ZeroAmount.selector);

        vault.withdraw(0);
    }

    function test_RevertWithdrawMoreThanStaked() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.prank(alice);

        vm.expectRevert(StakingVault.InsufficientStake.selector);

        vault.withdraw(STAKE_AMOUNT + 1);
    }

    // ---------------------------------------------------------------
    //                      REWARD FUNDING
    // ---------------------------------------------------------------

    function test_FundRewards() public {
        uint256 additionalRewards = 5_000 ether;

        rewardToken.approve(address(vault), additionalRewards);

        vault.fundRewards(additionalRewards);

        assertEq(vault.rewardRemaining(), REWARD_FUND + additionalRewards);

        assertEq(rewardToken.balanceOf(address(vault)), REWARD_FUND + additionalRewards);
    }

    function test_FundRewardsEmitsEvent() public {
        uint256 amount = 1_000 ether;

        vm.expectEmit(true, false, false, true);

        emit StakingVault.RewardsFunded(address(this), amount);

        vault.fundRewards(amount);
    }

    function test_RevertFundRewardsZero() public {
        vm.expectRevert(StakingVault.ZeroAmount.selector);

        vault.fundRewards(0);
    }

    function test_OnlyOwnerCanFundRewards() public {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));

        vault.fundRewards(100 ether);
    }

    // ---------------------------------------------------------------
    //                      REWARD RATE
    // ---------------------------------------------------------------

    function test_SetRewardRate() public {
        uint256 newRate = 5 ether;

        vault.setRewardRate(newRate);

        assertEq(vault.rewardRate(), newRate);
    }

    function test_SetRewardRateEmitsEvent() public {
        uint256 newRate = 5 ether;

        vm.expectEmit(false, false, false, true);

        emit StakingVault.RewardRateUpdated(REWARD_RATE, newRate);

        vault.setRewardRate(newRate);
    }

    function test_OnlyOwnerCanSetRewardRate() public {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));

        vault.setRewardRate(5 ether);
    }

    // ---------------------------------------------------------------
    //                   REWARD PER TOKEN TESTS
    // ---------------------------------------------------------------

    function test_RewardPerTokenDoesNotIncreaseWithoutStake() public {
        uint256 before = vault.rewardPerToken();

        vm.warp(block.timestamp + 100);

        uint256 afterValue = vault.rewardPerToken();

        assertEq(before, afterValue);
    }

    function test_RewardPerTokenIncreasesOverTime() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        uint256 before = vault.rewardPerToken();

        vm.warp(block.timestamp + 10);

        uint256 afterValue = vault.rewardPerToken();

        assertGt(afterValue, before);
    }

    function test_RewardPerTokenCalculation() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.warp(block.timestamp + 10);

        uint256 rewardPerToken = vault.rewardPerToken();

        // 10 REWARD emitted over 100 STAKE.
        // = 0.1 REWARD per STAKE.
        assertEq(rewardPerToken, 0.1 ether);
    }

    // ---------------------------------------------------------------
    //                         EARNED TESTS
    // ---------------------------------------------------------------

    function test_EarnedInitiallyZero() public view {
        assertEq(vault.earned(alice), 0);
    }

    function test_EarnedAfterTime() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.warp(block.timestamp + 10);

        // 1 REWARD/sec × 10 sec = 10 REWARD.
        assertEq(vault.earned(alice), 10 ether);
    }

    function test_EarnedIsProportionalToStake() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.prank(bob);
        vault.stake(100 ether);

        vm.warp(block.timestamp + 10);

        // Total = 200 STAKE.
        // 10 REWARD generated.
        // Each user owns 50%.
        // Each receives 5 REWARD.
        assertEq(vault.earned(alice), 5 ether);

        assertEq(vault.earned(bob), 5 ether);
    }

    function test_LargerStakeEarnsMoreRewards() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.prank(bob);
        vault.stake(300 ether);

        vm.warp(block.timestamp + 10);

        // Total = 400 STAKE.
        // 10 REWARD generated.
        //
        // Alice = 25% = 2.5 REWARD.
        // Bob   = 75% = 7.5 REWARD.

        assertEq(vault.earned(alice), 2.5 ether);

        assertEq(vault.earned(bob), 7.5 ether);
    }

    // ---------------------------------------------------------------
    //                    CLAIM REWARD TESTS
    // ---------------------------------------------------------------

    function test_ClaimRewards() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        uint256 balanceBefore = rewardToken.balanceOf(alice);

        vm.prank(alice);
        vault.claimRewards();

        uint256 balanceAfter = rewardToken.balanceOf(alice);

        assertEq(balanceAfter - balanceBefore, 10 ether);

        assertEq(vault.earned(alice), 0);
    }

    function test_ClaimRewardsEmitsEvent() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        vm.expectEmit(true, false, false, true);

        emit StakingVault.RewardClaimed(alice, 10 ether);

        vm.prank(alice);
        vault.claimRewards();
    }

    function test_ClaimRewardsDoesNotWithdrawStake() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        vm.prank(alice);
        vault.claimRewards();

        (uint256 amount,,) = vault.getUserInfo(alice);

        assertEq(amount, STAKE_AMOUNT);
    }

    function test_RevertClaimRewardsWithNoRewards() public {
        vm.prank(alice);

        vm.expectRevert(StakingVault.NoRewards.selector);

        vault.claimRewards();
    }

    // ---------------------------------------------------------------
    //                          EXIT TESTS
    // ---------------------------------------------------------------

    function test_Exit() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        uint256 stakeBalanceBefore = stakeToken.balanceOf(alice);

        uint256 rewardBalanceBefore = rewardToken.balanceOf(alice);

        vm.prank(alice);
        vault.exit();

        uint256 stakeBalanceAfter = stakeToken.balanceOf(alice);

        uint256 rewardBalanceAfter = rewardToken.balanceOf(alice);

        assertEq(stakeBalanceAfter - stakeBalanceBefore, STAKE_AMOUNT);

        assertEq(rewardBalanceAfter - rewardBalanceBefore, 10 ether);

        (uint256 amount,, uint256 rewards) = vault.getUserInfo(alice);

        assertEq(amount, 0);
        assertEq(rewards, 0);

        assertEq(vault.totalStaked(), 0);
    }

    function test_ExitWithNoRewards() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        uint256 balanceBefore = stakeToken.balanceOf(alice);

        vm.prank(alice);
        vault.exit();

        uint256 balanceAfter = stakeToken.balanceOf(alice);

        assertEq(balanceAfter - balanceBefore, STAKE_AMOUNT);

        assertEq(vault.totalStaked(), 0);
    }

    function test_ExitEmitsRewardEvent() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        vm.expectEmit(true, false, false, true);

        emit StakingVault.RewardClaimed(alice, 10 ether);

        vm.prank(alice);
        vault.exit();
    }

    function test_ExitEmitsWithdrawEvent() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.expectEmit(true, false, false, true);

        emit StakingVault.Withdrawn(alice, STAKE_AMOUNT);

        vm.prank(alice);
        vault.exit();
    }

    // ---------------------------------------------------------------
    //                 MULTIPLE USER REWARD TESTS
    // ---------------------------------------------------------------

    function test_MultipleUsersReceiveCorrectRewards() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.prank(bob);
        vault.stake(300 ether);

        vm.warp(block.timestamp + 100);

        uint256 aliceReward = vault.earned(alice);
        uint256 bobReward = vault.earned(bob);

        // 100 REWARD generated.
        //
        // Alice owns 25%.
        // Bob owns 75%.
        //
        // Alice = 25 REWARD.
        // Bob   = 75 REWARD.

        assertEq(aliceReward, 25 ether);

        assertEq(bobReward, 75 ether);
    }

    // ---------------------------------------------------------------
    //                   REWARD EXHAUSTION TESTS
    // ---------------------------------------------------------------
    function test_RewardsCannotExceedFundedAmount() public {
        vm.prank(alice);
        vault.stake(100 ether);

        // 10,000 REWARD funded.
        // 1 REWARD/sec.
        // After 10,000 seconds, the entire reward pool is exhausted.
        vm.warp(block.timestamp + 10_000);

        // earned() is a view calculation.
        // It can see that Alice has earned the full reward pool.
        assertEq(vault.earned(alice), REWARD_FUND);

        // Actually update the accounting.
        vm.prank(alice);
        vault.claimRewards();

        // The reward pool should now be exhausted.
        assertEq(vault.rewardRemaining(), 0);

        // Alice received exactly the funded amount.
        assertEq(rewardToken.balanceOf(alice), REWARD_FUND);
    }

    function test_RewardsStopWhenPoolIsExhausted() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.warp(block.timestamp + 10_000);

        uint256 rewardAtExhaustion = vault.earned(alice);

        assertEq(rewardAtExhaustion, REWARD_FUND);

        vm.warp(block.timestamp + 1_000);

        uint256 rewardAfterExhaustion = vault.earned(alice);

        assertEq(rewardAfterExhaustion, REWARD_FUND);
    }

    // ---------------------------------------------------------------
    //                    REWARD RATE UPDATE TESTS
    // ---------------------------------------------------------------

    function test_ChangingRewardRateDoesNotApplyRetroactively() public {
        vm.prank(alice);
        vault.stake(100 ether);

        // Old rate = 1 REWARD/sec.
        vm.warp(block.timestamp + 10);

        // Change rate to 5 REWARD/sec.
        vault.setRewardRate(5 ether);

        // The first 10 seconds should have used the old rate.
        assertEq(vault.earned(alice), 10 ether);

        // Now another 10 seconds passes at the new rate.
        vm.warp(block.timestamp + 10);

        // 10 old + 50 new = 60 REWARD.
        assertEq(vault.earned(alice), 60 ether);
    }

    // ---------------------------------------------------------------
    //                       PAUSE TESTS
    // ---------------------------------------------------------------

    function test_Pause() public {
        vault.pause();

        assertTrue(vault.paused());
    }

    function test_Unpause() public {
        vault.pause();

        vault.unpause();

        assertFalse(vault.paused());
    }

    function test_PausedPreventsStake() public {
        vault.pause();

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));

        vault.stake(STAKE_AMOUNT);
    }

    function test_PausedPreventsWithdraw() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vault.pause();

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));

        vault.withdraw(10 ether);
    }

    function test_PausedPreventsClaim() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + 10);

        vault.pause();

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));

        vault.claimRewards();
    }

    function test_PausedPreventsExit() public {
        vm.prank(alice);
        vault.stake(STAKE_AMOUNT);

        vault.pause();

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));

        vault.exit();
    }

    function test_PauseDoesNotPreventFunding() public {
        vault.pause();

        uint256 before = vault.rewardRemaining();

        vault.fundRewards(100 ether);

        assertEq(vault.rewardRemaining(), before + 100 ether);
    }

    // ---------------------------------------------------------------
    //                       INVARIANT TESTS
    // ---------------------------------------------------------------

    function test_TotalStakedMatchesTokenBalance() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.prank(bob);
        vault.stake(300 ether);

        assertEq(vault.totalStaked(), stakeToken.balanceOf(address(vault)));
    }

    function test_WithdrawMaintainsTotalStakedInvariant() public {
        vm.prank(alice);
        vault.stake(100 ether);

        vm.prank(bob);
        vault.stake(300 ether);

        vm.prank(alice);
        vault.withdraw(40 ether);

        assertEq(vault.totalStaked(), stakeToken.balanceOf(address(vault)));
    }

    // ---------------------------------------------------------------
    //                    CONSTRUCTOR TESTS
    // ---------------------------------------------------------------

    function test_RevertZeroStakeTokenAddress() public {
        vm.expectRevert(StakingVault.ZeroAddress.selector);

        new StakingVault(address(0), address(rewardToken));
    }

    function test_RevertZeroRewardTokenAddress() public {
        vm.expectRevert(StakingVault.ZeroAddress.selector);

        new StakingVault(address(stakeToken), address(0));
    }

    // ---------------------------------------------------------------
    //                        EVENT DECLARATIONS
    // ---------------------------------------------------------------

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardClaimed(address indexed user, uint256 amount);

    event RewardsFunded(address indexed funder, uint256 amount);

    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
}

