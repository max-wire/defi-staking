// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {StakeToken} from "../../src/tokens/StakeToken.sol";

contract StakeTokenTest is Test {
    StakeToken public stakeToken;

    address public deployer;
    address public user;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        deployer = address(this);
        user = makeAddr("user");

        stakeToken = new StakeToken();
    }

    // ---------------------------------------------------------------
    // Deployment Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the token name is correctly configured.
     */
    function test_Name() public view {
        assertEq(stakeToken.name(), "DeFi Stake Token");
    }

    /**
     * @notice Verifies that the token symbol is correctly configured.
     */
    function test_Symbol() public view {
        assertEq(stakeToken.symbol(), "STAKE");
    }

    /**
     * @notice Verifies that the token uses 18 decimals.
     */
    function test_Decimals() public view {
        assertEq(stakeToken.decimals(), 18);
    }

    /**
     * @notice Verifies that the initial supply constant is correct.
     */
    function test_InitialSupplyConstant() public view {
        assertEq(stakeToken.INITIAL_SUPPLY(), INITIAL_SUPPLY);
    }

    /**
     * @notice Verifies that the entire initial supply is minted to the
     *         deployer.
     */
    function test_InitialSupplyMintedToDeployer() public view {
        assertEq(stakeToken.balanceOf(deployer), INITIAL_SUPPLY);
    }

    /**
     * @notice Verifies that the total token supply equals the initial supply.
     */
    function test_TotalSupply() public view {
        assertEq(stakeToken.totalSupply(), INITIAL_SUPPLY);
    }

    // ---------------------------------------------------------------
    // ERC-20 Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that STAKE can be transferred between accounts.
     */
    function test_Transfer() public {
        uint256 amount = 100 ether;

        stakeToken.transfer(user, amount);

        assertEq(stakeToken.balanceOf(user), amount);
        assertEq(stakeToken.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    /**
     * @notice Verifies that a user can approve another account to spend
     *         STAKE on their behalf.
     */
    function test_Approve() public {
        uint256 amount = 500 ether;

        stakeToken.approve(user, amount);

        assertEq(stakeToken.allowance(deployer, user), amount);
    }

    /**
     * @notice Verifies that an approved spender can transfer STAKE using
     *         transferFrom().
     */
    function test_TransferFrom() public {
        uint256 amount = 250 ether;

        stakeToken.approve(user, amount);

        vm.prank(user);
        stakeToken.transferFrom(deployer, user, amount);

        assertEq(stakeToken.balanceOf(user), amount);
        assertEq(stakeToken.balanceOf(deployer), INITIAL_SUPPLY - amount);

        assertEq(stakeToken.allowance(deployer, user), 0);
    }

    // ---------------------------------------------------------------
    // Ownership Tests
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the deployer becomes the token owner.
     */
    function test_Owner() public view {
        assertEq(stakeToken.owner(), deployer);
    }

    // ---------------------------------------------------------------
    // Supply Invariant
    // ---------------------------------------------------------------

    /**
     * @notice Verifies that the total supply remains fixed after transfers.
     * @dev
     * Transfers move existing tokens and must not change total supply.
     */
    function test_TransferDoesNotChangeTotalSupply() public {
        uint256 amount = 1_000 ether;

        uint256 supplyBefore = stakeToken.totalSupply();

        stakeToken.transfer(user, amount);

        uint256 supplyAfter = stakeToken.totalSupply();

        assertEq(supplyBefore, supplyAfter);
        assertEq(supplyAfter, INITIAL_SUPPLY);
    }
}
