// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";

library ModuleMath {
    error InvalidCalculation();

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
