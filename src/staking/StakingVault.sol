// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title StakingVault
 * @notice Core staking contract for the DeFi staking protocol.
 *
 * @dev
 * StakingVault manages the complete staking lifecycle:
 *
 * 1. Users deposit STAKE.
 * 2. The vault tracks each user's staking position.
 * 3. REWARD tokens are emitted over time according to `rewardRate`.
 * 4. Users accumulate rewards proportional to their share of the pool.
 * 5. Users can claim rewards.
 * 6. Users can withdraw their STAKE.
 * 7. Users can exit by claiming rewards and withdrawing their entire stake.
 *
 * The vault does not mint REWARD tokens.
 * Rewards must first be funded through `fundRewards()`.
 *
 * Reward accounting uses the standard cumulative `rewardPerToken` model.
 * This allows rewards to be calculated efficiently without iterating over
 * every staker.
 *
 * Reward funding is finite:
 *
 *      Treasury
 *          │
 *          │ REWARD
 *          ▼
 *    StakingVault
 *          │
 *          │ emission
 *          ▼
 *       Stakers
 *
 * When the funded reward balance is exhausted, reward emission stops until
 * additional REWARD tokens are funded.
 */
contract StakingVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // =============================================================
    //                       TYPES
    // =============================================================

    /**
     * @notice Stores the staking and reward information for a user.
     *
     * @dev
     * `amount` is the user's current STAKE position.
     *
     * `rewardPerTokenPaid` stores the global reward-per-token value that
     * was accounted for the last time the user's position was updated.
     *
     * `rewards` stores rewards already accrued by the user but not yet
     * claimed.
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
    }

    // =============================================================
    //                       CONSTANTS
    // =============================================================

    /// @notice Precision used for reward-per-token calculations.
    uint256 private constant PRECISION = 1e18;

    // =============================================================
    //                    IMMUTABLE ASSETS
    // =============================================================

    /// @notice Token users deposit into the vault.
    IERC20 public immutable stakeToken;

    /// @notice Token distributed as staking rewards.
    IERC20 public immutable rewardToken;

    // =============================================================
    //                     POOL ACCOUNTING
    // =============================================================

    /// @notice Total amount of STAKE currently deposited in the vault.
    uint256 private _totalStaked;

    /// @notice REWARD tokens emitted per second.
    uint256 private _rewardRate;

    /// @notice Cumulative rewards earned per unit of STAKE.
    uint256 private _rewardPerTokenStored;

    /// @notice Timestamp when global reward accounting was last updated.
    uint256 private _lastUpdateTime;

    /**
     * @notice REWARD tokens that have been funded but not yet emitted.
     *
     * @dev
     * This value ensures the reward schedule cannot emit more REWARD than
     * has actually been funded.
     */
    uint256 private _rewardRemaining;

    // =============================================================
    //                       USER ACCOUNTING
    // =============================================================

    /// @notice Stores staking and reward information for every user.
    mapping(address => UserInfo) private _users;

    // =============================================================
    //                         EVENTS
    // =============================================================

    /**
     * @notice Emitted when a user deposits STAKE.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user withdraws STAKE.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user claims REWARD tokens.
     */
    event RewardClaimed(address indexed user, uint256 amount);

    /**
     * @notice Emitted when REWARD tokens are funded into the vault.
     */
    event RewardsFunded(address indexed funder, uint256 amount);

    /**
     * @notice Emitted when the reward emission rate changes.
     */
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);

    // =============================================================
    //                         ERRORS
    // =============================================================

    /// @notice Thrown when an address argument is zero.
    error ZeroAddress();

    /// @notice Thrown when a staking amount is zero.
    error ZeroAmount();

    /// @notice Thrown when a user attempts to withdraw more than they staked.
    error InsufficientStake();

    /// @notice Thrown when a user has no rewards to claim.
    error NoRewards();

    /// @notice Thrown when the vault cannot satisfy a reward payment.
    error InsufficientRewardBalance();

    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================

    /**
     * @notice Creates the staking vault.
     *
     * @param stakeToken_ Address of the STAKE token.
     * @param rewardToken_ Address of the REWARD token.
     *
     * @dev
     * The deployer becomes the initial owner and can configure the reward
     * emission rate, fund rewards, and pause or unpause the vault.
     */
    constructor(address stakeToken_, address rewardToken_) Ownable(msg.sender) {
        if (stakeToken_ == address(0)) {
            revert ZeroAddress();
        }

        if (rewardToken_ == address(0)) {
            revert ZeroAddress();
        }

        stakeToken = IERC20(stakeToken_);
        rewardToken = IERC20(rewardToken_);

        _lastUpdateTime = block.timestamp;
    }

    // =============================================================
    //                     USER FUNCTIONS
    // =============================================================

    /**
     * @notice Deposits STAKE into the vault.
     *
     * @param amount Amount of STAKE to deposit.
     *
     * @dev
     * The caller must first approve the vault to spend the specified
     * amount of STAKE.
     *
     * The user's pending rewards are updated before their staking
     * position changes.
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) {
            revert ZeroAmount();
        }

        _updateReward(msg.sender);

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        _users[msg.sender].amount += amount;
        _totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Withdraws STAKE from the vault.
     *
     * @param amount Amount of STAKE to withdraw.
     *
     * @dev
     * The user's pending rewards are updated before their staking
     * position changes.
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) {
            revert ZeroAmount();
        }

        UserInfo storage user = _users[msg.sender];

        if (amount > user.amount) {
            revert InsufficientStake();
        }

        _updateReward(msg.sender);

        user.amount -= amount;
        _totalStaked -= amount;

        stakeToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Claims all currently accrued REWARD tokens.
     *
     * @dev
     * The user's reward accounting is updated before the reward is
     * transferred.
     */
    function claimRewards() external nonReentrant whenNotPaused {
        _updateReward(msg.sender);

        uint256 reward = _users[msg.sender].rewards;

        if (reward == 0) {
            revert NoRewards();
        }

        _users[msg.sender].rewards = 0;

        if (rewardToken.balanceOf(address(this)) < reward) {
            revert InsufficientRewardBalance();
        }

        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @notice Claims all accrued rewards and withdraws the user's entire
     *         staking position.
     *
     * @dev
     * This is a convenience function that combines reward claiming and
     * full withdrawal into a single transaction.
     *
     * The function intentionally does not revert when the user has no
     * rewards. This allows a user to exit even if their pending reward
     * amount is zero.
     */
    function exit() external nonReentrant whenNotPaused {
        _updateReward(msg.sender);

        UserInfo storage user = _users[msg.sender];

        uint256 reward = user.rewards;
        uint256 amount = user.amount;

        user.rewards = 0;
        user.amount = 0;

        _totalStaked -= amount;

        if (reward > 0) {
            if (rewardToken.balanceOf(address(this)) < reward) {
                revert InsufficientRewardBalance();
            }

            rewardToken.safeTransfer(msg.sender, reward);

            emit RewardClaimed(msg.sender, reward);
        }

        if (amount > 0) {
            stakeToken.safeTransfer(msg.sender, amount);

            emit Withdrawn(msg.sender, amount);
        }
    }

    // =============================================================
    //                     ADMIN FUNCTIONS
    // =============================================================

    /**
     * @notice Funds the vault with REWARD tokens.
     *
     * @param amount Amount of REWARD tokens to fund.
     *
     * @dev
     * The caller must approve the vault to spend the specified amount
     * of REWARD.
     *
     * Funding rewards increases the finite reward pool available for
     * future emissions.
     */
    function fundRewards(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) {
            revert ZeroAmount();
        }

        _updateReward(address(0));

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        _rewardRemaining += amount;

        emit RewardsFunded(msg.sender, amount);
    }

    /**
     * @notice Updates the REWARD emission rate.
     *
     * @param newRate New amount of REWARD emitted per second.
     *
     * @dev
     * Global reward accounting is updated before the new rate is applied.
     * This prevents the new rate from being applied retroactively to the
     * period before this function was called.
     */
    function setRewardRate(uint256 newRate) external onlyOwner {
        _updateReward(address(0));

        uint256 oldRate = _rewardRate;

        _rewardRate = newRate;

        emit RewardRateUpdated(oldRate, newRate);
    }

    /**
     * @notice Pauses staking, withdrawals, and reward claims.
     *
     * @dev
     * Reward funding and administrative configuration remain available
     * while the protocol is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the staking vault.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Returns the total amount of STAKE deposited in the vault.
     */
    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    /**
     * @notice Returns the current REWARD emission rate.
     *
     * @return The amount of REWARD emitted per second.
     */
    function rewardRate() external view returns (uint256) {
        return _rewardRate;
    }

    /**
     * @notice Returns the current cumulative reward per STAKE token.
     *
     * @dev
     * The returned value includes rewards that have accrued since the
     * last global accounting update.
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalStaked == 0) {
            return _rewardPerTokenStored;
        }

        uint256 elapsed = block.timestamp - _lastUpdateTime;

        if (elapsed == 0 || _rewardRate == 0) {
            return _rewardPerTokenStored;
        }

        uint256 potentialReward = elapsed * _rewardRate;

        uint256 emittedReward = potentialReward;

        if (emittedReward > _rewardRemaining) {
            emittedReward = _rewardRemaining;
        }

        if (emittedReward == 0) {
            return _rewardPerTokenStored;
        }

        return _rewardPerTokenStored + (emittedReward * PRECISION) / _totalStaked;
    }

    /**
     * @notice Returns the amount of REWARD currently earned by a user.
     *
     * @param account Address of the staker.
     *
     * @return The user's total claimable REWARD.
     */
    function earned(address account) public view returns (uint256) {
        UserInfo memory user = _users[account];

        uint256 currentRewardPerToken = rewardPerToken();

        uint256 pending = (user.amount * (currentRewardPerToken - user.rewardPerTokenPaid)) / PRECISION;

        return user.rewards + pending;
    }

    /**
     * @notice Returns a user's complete staking information.
     *
     * @param account Address of the staker.
     *
     * @return amount Current STAKE deposited by the user.
     * @return rewardPerTokenPaid Reward-per-token value last accounted for
     *         the user.
     * @return rewards Previously accrued but unclaimed REWARD.
     */
    function getUserInfo(address account)
        external
        view
        returns (uint256 amount, uint256 rewardPerTokenPaid, uint256 rewards)
    {
        UserInfo memory user = _users[account];

        return (user.amount, user.rewardPerTokenPaid, user.rewards);
    }

    /**
     * @notice Returns the amount of funded REWARD that has not yet been
     *         emitted.
     *
     * @return The remaining reward emission budget.
     */
    function rewardRemaining() external view returns (uint256) {
        return _rewardRemaining;
    }

    // =============================================================
    //                   INTERNAL ACCOUNTING
    // =============================================================

    /**
     * @notice Updates global reward accounting and optionally a user's
     *         reward accounting.
     *
     * @param account Address whose rewards should be updated.
     *
     * @dev
     * Passing address(0) updates only global accounting.
     *
     * The function always updates `lastUpdateTime`. This is important when
     * the reward pool becomes exhausted because newly funded rewards must
     * not be emitted retroactively.
     */
    function _updateReward(address account) internal {
        uint256 currentTime = block.timestamp;

        if (_totalStaked > 0 && currentTime > _lastUpdateTime) {
            uint256 elapsed = currentTime - _lastUpdateTime;

            if (_rewardRate > 0 && _rewardRemaining > 0) {
                uint256 potentialReward = elapsed * _rewardRate;

                uint256 emittedReward = potentialReward;

                if (emittedReward > _rewardRemaining) {
                    emittedReward = _rewardRemaining;
                }

                if (emittedReward > 0) {
                    _rewardPerTokenStored += (emittedReward * PRECISION) / _totalStaked;

                    _rewardRemaining -= emittedReward;
                }
            }
        }

        _lastUpdateTime = currentTime;

        if (account != address(0)) {
            UserInfo storage user = _users[account];

            user.rewards = earned(account);
            user.rewardPerTokenPaid = _rewardPerTokenStored;
        }
    }
}
