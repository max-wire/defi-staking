// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {RewardToken} from "../../src/tokens/RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken public rewardToken;

    address public deployer;
    address public user;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        deployer = address(this);
        user = makeAddr("user");

        rewardToken = new RewardToken();
    }

    // ---------------------------------------------------------------
    // Deployment Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the token name is correctly configured.
     */
    function test_Name() public view {
        assertEq(rewardToken.name(), "DeFi Reward Token");
    }

    /**
     * @notice Verifies that the token symbol is correctly configured.
     */
    function test_Symbol() public view {
        assertEq(rewardToken.symbol(), "REWARD");
    }

    /**
     * @notice Verifies that the token uses 18 decimals.
     */
    function test_Decimals() public view {
        assertEq(rewardToken.decimals(), 18);
    }

    /**
     * @notice Verifies that the initial supply constant is correct.
     */
    function test_InitialSupplyConstant() public view {
        assertEq(rewardToken.INITIAL_SUPPLY(), INITIAL_SUPPLY);
    }

    /**
     * @notice Verifies that the total supply is equal to the
     *         configured initial supply.
     */
    function test_TotalSupply() public view {
        assertEq(rewardToken.totalSupply(), INITIAL_SUPPLY);
    }

    // ---------------------------------------------------------------
    // Initial Distribution Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the deployer receives the entire
     *         initial REWARD supply.
     */
    function test_InitialSupplyMintedToDeployer() public view {
        assertEq(rewardToken.balanceOf(deployer), INITIAL_SUPPLY);
    }

    /**
     * @notice Verifies that no REWARD tokens are initially owned
     *         by another user.
     */
    function test_UserStartsWithZeroBalance() public view {
        assertEq(rewardToken.balanceOf(user), 0);
    }

    // ---------------------------------------------------------------
    // ERC-20 Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that REWARD tokens can be transferred
     *         between accounts.
     */
    function test_Transfer() public {
        uint256 amount = 100 ether;

        rewardToken.transfer(user, amount);

        assertEq(rewardToken.balanceOf(user), amount);

        assertEq(rewardToken.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    /**
     * @notice Verifies that an account can approve another account
     *         to spend REWARD tokens.
     */
    function test_Approve() public {
        uint256 amount = 500 ether;

        rewardToken.approve(user, amount);

        assertEq(rewardToken.allowance(deployer, user), amount);
    }

    /**
     * @notice Verifies that an approved spender can transfer
     *         REWARD tokens using transferFrom().
     */
    function test_TransferFrom() public {
        uint256 amount = 250 ether;

        rewardToken.approve(user, amount);

        vm.prank(user);
        rewardToken.transferFrom(deployer, user, amount);

        assertEq(rewardToken.balanceOf(user), amount);

        assertEq(rewardToken.balanceOf(deployer), INITIAL_SUPPLY - amount);

        assertEq(rewardToken.allowance(deployer, user), 0);
    }

    // ---------------------------------------------------------------
    // Ownership Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the deployer becomes the owner.
     */
    function test_Owner() public view {
        assertEq(rewardToken.owner(), deployer);
    }

    // ---------------------------------------------------------------
    // Supply Invariant Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that transferring tokens does not change
     *         the total supply.
     */
    function test_TransferDoesNotChangeTotalSupply() public {
        uint256 amount = 1_000 ether;

        uint256 supplyBefore = rewardToken.totalSupply();

        rewardToken.transfer(user, amount);

        uint256 supplyAfter = rewardToken.totalSupply();

        assertEq(supplyBefore, supplyAfter);

        assertEq(supplyAfter, INITIAL_SUPPLY);
    }

    /**
     * @notice Verifies that the sum of known account balances remains
     *         equal to the total supply after a transfer.
     */
    function test_BalancesEqualTotalSupply() public {
        uint256 amount = 10_000 ether;

        rewardToken.transfer(user, amount);

        uint256 deployerBalance = rewardToken.balanceOf(deployer);
        uint256 userBalance = rewardToken.balanceOf(user);

        assertEq(deployerBalance + userBalance, rewardToken.totalSupply());
    }
}

