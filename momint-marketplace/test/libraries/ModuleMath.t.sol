// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ModuleMath} from "../../src/libraries/ModuleMath.sol";

contract ModuleMathTest is Test {
    function test_CalculateNewRevenuePerShare() public {
        // Test basic calculation
        uint256 amount = 1000e18;
        uint256 allocatedShares = 100e18;
        uint256 expectedRevenuePerShare = 10e18; // (1000e18 * 1e18) / 100e18 = 10e18

        uint256 revenuePerShare = ModuleMath.calculateNewRevenuePerShare(
            amount,
            allocatedShares
        );
        assertEq(
            revenuePerShare,
            expectedRevenuePerShare,
            "Basic revenue per share calculation failed"
        );
    }

    function test_CalculateNewRevenuePerShare_SmallNumbers() public view {
        // Test with small numbers
        uint256 amount = 1e18;
        uint256 allocatedShares = 2e18;
        uint256 expectedRevenuePerShare = 0.5e18; // (1e18 * 1e18) / 2e18 = 0.5e18

        uint256 revenuePerShare = ModuleMath.calculateNewRevenuePerShare(
            amount,
            allocatedShares
        );
        assertEq(
            revenuePerShare,
            expectedRevenuePerShare,
            "Small numbers revenue calculation failed"
        );
    }

    function test_RevertWhen_ZeroShares() public {
        // Test revert on zero shares
        uint256 amount = 1000e18;
        uint256 allocatedShares = 0;

        vm.expectRevert(ModuleMath.InvalidCalculation.selector);
        ModuleMath.calculateNewRevenuePerShare(amount, allocatedShares);
    }

    function test_CalculateRewardDebt() public view {
        // Test basic reward debt calculation
        uint256 shares = 100e18;
        uint256 revenuePerShare = 10e18;
        uint256 expectedRewardDebt = 1000e18; // (100e18 * 10e18) / 1e18 = 1000e18

        uint256 rewardDebt = ModuleMath.calculateRewardDebt(
            shares,
            revenuePerShare
        );
        assertEq(
            rewardDebt,
            expectedRewardDebt,
            "Basic reward debt calculation failed"
        );
    }

    function test_CalculateRewardDebt_SmallNumbers() public view {
        // Test with small numbers
        uint256 shares = 1e18;
        uint256 revenuePerShare = 0.5e18;
        uint256 expectedRewardDebt = 0.5e18; // (1e18 * 0.5e18) / 1e18 = 0.5e18

        uint256 rewardDebt = ModuleMath.calculateRewardDebt(
            shares,
            revenuePerShare
        );
        assertEq(
            rewardDebt,
            expectedRewardDebt,
            "Small numbers reward debt calculation failed"
        );
    }

    function test_CalculateRewardDebt_ZeroValues() public view {
        // Test with zero values (should not revert)
        uint256 shares = 0;
        uint256 revenuePerShare = 10e18;
        uint256 expectedRewardDebt = 0;

        uint256 rewardDebt = ModuleMath.calculateRewardDebt(
            shares,
            revenuePerShare
        );
        assertEq(
            rewardDebt,
            expectedRewardDebt,
            "Zero shares reward debt calculation failed"
        );

        shares = 100e18;
        revenuePerShare = 0;
        expectedRewardDebt = 0;

        rewardDebt = ModuleMath.calculateRewardDebt(shares, revenuePerShare);
        assertEq(
            rewardDebt,
            expectedRewardDebt,
            "Zero revenue per share calculation failed"
        );
    }

    function test_Precision() public view {
        // Test precision with large numbers
        uint256 shares = 1_000_000e18;
        uint256 revenuePerShare = 2.5e18;
        uint256 expectedRewardDebt = 2_500_000e18;

        uint256 rewardDebt = ModuleMath.calculateRewardDebt(
            shares,
            revenuePerShare
        );
        assertEq(rewardDebt, expectedRewardDebt, "Precision test failed");
    }

    function test_NoOverflow() public pure {
        // Test that calculations don't overflow with large numbers
        uint256 amount = type(uint256).max / 1e18; // Divide by 1e18 first to prevent overflow
        uint256 allocatedShares = 1e18;

        // This should not revert
        uint256 revenuePerShare = ModuleMath.calculateNewRevenuePerShare(
            amount,
            allocatedShares
        );
        assert(revenuePerShare > 0); // Use assert instead of assertTrue in pure function

        // Test reward debt with large numbers
        uint256 shares = type(uint256).max / 1e19; // Divide by more than 1e18 to prevent overflow
        revenuePerShare = 1e18;

        // This should not revert
        uint256 rewardDebt = ModuleMath.calculateRewardDebt(
            shares,
            revenuePerShare
        );
        assert(rewardDebt > 0); // Use assert instead of assertTrue in pure function
    }
}
