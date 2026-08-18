// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakeToken
 * @author Maxwell wire
 * @notice ERC-20 token used as the underlying staking asset in the DeFi
 *         staking protocol.
 *
 * @dev
 * The token is intentionally independent from the staking system.
 * StakeToken does not know about the StakingVault and contains no staking
 * or reward logic.
 *
 * Token configuration:
 * - Name: DeFi Stake Token
 * - Symbol: STAKE
 * - Decimals: 18
 * - Initial supply: 1,000,000 STAKE
 * - Additional minting: Not supported in V1
 *
 * The entire initial supply is minted to the deployer during construction.
 *
 * Architecture:
 *
 *      User
 *        │
 *        │ owns STAKE
 *        ▼
 *   StakeToken
 *        │
 *        │ approve()
 *        ▼
 *   StakingVault
 *        │
 *        │ stake()
 *        ▼
 *   User's staking position
 */
contract StakeToken is ERC20, Ownable {
    /// @notice Total amount of STAKE created at deployment.
    /// @dev 1,000,000 STAKE with 18 decimals.
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    /**
     * @notice Deploys the StakeToken and mints the entire initial supply.
     * @dev
     * The complete supply is minted to `msg.sender`.
     *
     * No additional minting mechanism exists in V1, making the token supply
     * fixed after deployment.
     */
    constructor() ERC20("DeFi Stake Token", "STAKE") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

