//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface IModule is IERC4626 {
    function getAvailableAssetsForWithdrawal() external view returns (uint256);

    function claim(bytes memory) external returns (uint256);
}
