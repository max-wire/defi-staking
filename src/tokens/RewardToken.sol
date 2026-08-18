// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RewardToken
 * @notice ERC-20 token used as the reward asset in the DeFi staking protocol.
 *
 * @dev
 * RewardToken is intentionally independent from the staking system.
 * It contains no staking logic, reward calculations, or vault logic.
 *
 * Token configuration:
 * - Name: DeFi Reward Token
 * - Symbol: REWARD
 * - Decimals: 18
 * - Initial supply: 1,000,000 REWARD
 *
 * The entire initial supply is minted to the deployer during deployment.
 *
 * V1 does not provide any external minting mechanism. Therefore, the
 * initial token supply is fixed after deployment.
 *
 * Architecture:
 *
 *      RewardToken
 *          │
 *          │ REWARD
 *          ▼
 *     StakingVault
 *          │
 *          │ distributes rewards
 *          ▼
 *        Users
 *
 * RewardToken does not know that StakingVault exists.
 */
contract RewardToken is ERC20, Ownable {
    /// @notice The initial supply of REWARD tokens.
    /// @dev 1,000,000 REWARD with 18 decimals.
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    /**
     * @notice Deploys the RewardToken contract.
     *
     * @dev
     * The complete initial supply is minted to the deployer.
     *
     * No additional minting mechanism is provided in V1.
     */
    constructor() ERC20("DeFi Reward Token", "REWARD") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

