//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IModule} from "../interfaces/IModule.sol";

library VaultHelper {
    using Math for uint256;
    using SafeERC20 for IERC20;

    error InvalidAssetAddress();
    error InvalidFeeDestination();
    error ERC20ApproveFail();

    function validateVaultParams() public returns (uint8 decimals) {}
}
