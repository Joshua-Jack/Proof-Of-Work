// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library ModuleMath {
    error InvalidCalculation();

    function calculateInvestment(
        uint256 amount,
        uint256 pricePerShare
    ) internal pure returns (uint256 shares, uint256 cost, uint256 refund) {
        shares = amount / pricePerShare;
        cost = shares * pricePerShare;
        refund = amount - cost;
    }

    function calculateRewards(
        uint256 shares,
        uint256 revenuePerShare,
        uint256 rewardDebt
    ) internal pure returns (uint256) {
        uint256 accumulatedRewards = (shares * revenuePerShare) / 1e18;
        return
            accumulatedRewards > rewardDebt
                ? accumulatedRewards - rewardDebt
                : 0;
    }

    function calculateNewRevenuePerShare(
        uint256 amount,
        uint256 allocatedShares
    ) internal pure returns (uint256) {
        if (allocatedShares == 0) revert InvalidCalculation();
        return (amount * 1e18) / allocatedShares;
    }

    function calculateRewardDebt(
        uint256 shares,
        uint256 revenuePerShare
    ) internal pure returns (uint256) {
        return (shares * revenuePerShare) / 1e18;
    }
}
