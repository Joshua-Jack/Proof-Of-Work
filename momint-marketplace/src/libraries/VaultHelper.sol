//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IModule} from "../interfaces/IModule.sol";
import {Module, VaultFees} from "../interfaces/IMomintVault.sol";
import {MAX_BASIS_POINTS} from "../utils/Constants.sol";
import {console} from "forge-std/console.sol";

library VaultHelper {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Custom errors
    error InvalidVaultFees();
    error InvalidAssetAddress();
    error InvalidFeeRecipient();
    error VaultAssetMismatch();
    error ERC20ApproveFail();
    error InvalidIndex(uint256 index);
    error AllotmentTotalTooHigh();
    error MultipleProtectStrat();
    error ModuleHasLockedAssets(address module);
    error SingleProjectModuleExists();
    error InvalidModuleAddress();
    error ModuleRemovalFailed();

    // Events
    event ModuleUpdated(
        address indexed module,
        bool replaced,
        uint256 indexed index
    );
    event ModuleRemoved(address indexed module);

    function addOrReplaceModule(
        Module[] storage modules,
        Module memory newModule_,
        bool replace_,
        uint256 index_
    ) public returns (IModule newModule, IModule moduleToBeReplaced) {
        uint256 len = modules.length;

        if (address(newModule_.module) == address(0))
            revert InvalidModuleAddress();

        // Check for existing single project module if new module is single project
        if (newModule_.isSingleProject) {
            for (uint256 i = 0; i < len; ) {
                if (modules[i].isSingleProject && modules[i].active) {
                    revert SingleProjectModuleExists();
                }
                unchecked {
                    i++;
                }
            }
        }

        // Adding or replacing module based on replace_ flag
        if (replace_) {
            if (index_ >= len) revert InvalidIndex(index_);

            // Replace the module at index_
            moduleToBeReplaced = modules[index_].module;
            bool success = removeModule(moduleToBeReplaced);
            if (!success) revert ModuleRemovalFailed();

            modules[index_] = newModule_;
            modules[index_].active = true;
        } else {
            // Add the new module
            newModule_.active = true;
            modules.push(newModule_);
        }

        newModule = newModule_.module;
        emit ModuleUpdated(address(newModule), replace_, uint8(index_));
    }

    function removeModule(IModule moduleToBeRemoved_) public returns (bool) {
        if (address(moduleToBeRemoved_) == address(0))
            revert InvalidModuleAddress();

        // Check if module has any locked assets

        emit ModuleRemoved(address(moduleToBeRemoved_));
        return true;
    }

    event ModuleAssetsReturned(address indexed module, uint256 amount);

    function validateVaultParameters(
        IERC20 baseAsset_,
        uint8 decimalOffset,
        VaultFees memory fees_,
        VaultFees storage fees
    ) public returns (uint8 decimals) {
        if (address(baseAsset_) == address(0)) {
            revert InvalidAssetAddress();
        }

        decimals =
            IERC20Metadata(address(baseAsset_)).decimals() +
            decimalOffset;

        validateAndSetFees(fees_, fees);
    }

    /// @notice Validates and assigns fee values from `fees_` to `fees`.
    /// @param fees_ The input VaultFees structure containing fee values to validate and assign.
    /// @param fees The storage VaultFees structure where validated fees will be stored.
    function validateAndSetFees(
        VaultFees memory fees_,
        VaultFees storage fees
    ) internal {
        // Validate basic fee values to ensure they don't exceed MAX_BASIS_POINTS
        if (
            fees_.depositFee >= MAX_BASIS_POINTS ||
            fees_.withdrawalFee >= MAX_BASIS_POINTS ||
            fees_.protocolFee >= MAX_BASIS_POINTS
        ) {
            revert InvalidVaultFees();
        }

        // Assign validated fee values
        fees.depositFee = fees_.depositFee;
        fees.withdrawalFee = fees_.withdrawalFee;
        fees.protocolFee = fees_.protocolFee;
    }
}
