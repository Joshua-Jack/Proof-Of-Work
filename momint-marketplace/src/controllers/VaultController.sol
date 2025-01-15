//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ImplData, IImplRecords} from "../interfaces/IImpl.sol";
import {IVaultRecords} from "../interfaces/IVaultRecords.sol";
import {IVaultDepolymentController} from "../interfaces/IVaultDepolymentController.sol";

/// @title VaultManager
/// @author Momint
/// @notice Controller contract for managing vault lifecycle and configurations
/// @dev Implements OpenZeppelin's AccessControl for role-based permissions
///      Manages vault deployments, implementations, and operational controls
contract VaultManager is AccessControl {
    /// @notice Role identifier for vault controller permissions
    /// @dev Calculated as keccak256("VAULT_CONTROLLER")
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    /// @notice Interface for tracking vault registrations
    IVaultRecords public vaultRecords;
    /// @notice Interface for controlling vault deployments
    IVaultDepolymentController public deploymentController;

    /// @notice Emitted when all vaults are paused simultaneously
    event AllVaultsPaused();
    /// @notice Emitted when all vaults are unpaused simultaneously
    event AllVaultsUnpaused();

    /// @notice Initializes the contract with an admin address
    /// @dev Grants both DEFAULT_ADMIN_ROLE and VAULT_CONTROLLER_ROLE to admin
    /// @param admin Address to be granted admin privileges
    /// @custom:throws "Invalid admin address" if admin is zero address
    constructor(address admin) {
        require(admin != address(0), "Invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CONTROLLER_ROLE, admin);
    }

    /// @notice Configures the contract with necessary interface connections
    /// @dev Can only be called by admin role
    /// @param vaultRecords_ Address of the vault records contract
    /// @param deploymentController_ Address of the deployment controller contract
    function setup(
        IVaultRecords vaultRecords_,
        IVaultDepolymentController deploymentController_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultRecords = vaultRecords_;
        deploymentController = deploymentController_;
    }

    /// @notice Pauses operations for a specific vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the vault to pause
    function pauseVault(
        address vault_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {}

    /// @notice Unpauses operations for a specific vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the vault to unpause
    function unpauseVault(
        address vault_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {}

    /// @notice Pauses all registered vaults simultaneously
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    function pauseAllVaults() external onlyRole(VAULT_CONTROLLER_ROLE) {
        address[] memory vaults = vaultRecords.getAllVaults();
        emit AllVaultsPaused();
        uint256 vaultsLength = vaults.length;
        // todo go through all vaults and pause them
    }

    /// @notice Unpauses all registered vaults simultaneously
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    function unpauseAllVaults() external onlyRole(VAULT_CONTROLLER_ROLE) {
        emit AllVaultsUnpaused();
        address[] memory vaults = vaultRecords.getAllVaults();
        uint256 vaultsLength = vaults.length;
        // todo go through all vaults and unpause them
    }

    /// @notice Deploys a new vault using specified implementation
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param id_ Implementation identifier
    /// @param data_ Initialization data for the new vault
    /// @return newVaultAddress Address of the newly deployed vault
    function deployNewVault(
        bytes32 id_,
        bytes calldata data_
    )
        external
        onlyRole(VAULT_CONTROLLER_ROLE)
        returns (address newVaultAddress)
    {
        newVaultAddress = deploymentController.deployNewVault(id_, data_);
        vaultRecords.addVault(newVaultAddress, id_);
    }

    /// @notice Registers a new vault implementation
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param id_ Unique identifier for the implementation
    /// @param implementation_ Implementation data including address and initialization requirements
    function registerNewImpl(
        bytes32 id_,
        ImplData memory implementation_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        deploymentController.addImplementation(id_, implementation_);
    }

    /// @notice Removes a vault implementation from the registry
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param id_ Identifier of the implementation to remove
    function removeImplementation(
        bytes32 id_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        deploymentController.removeImplementation(id_);
    }

    /// @notice Removes a vault from the registry
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the vault to remove
    /// @param vaultId_ Implementation identifier of the vault
    function removeVault(
        address vault_,
        bytes32 vaultId_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        deploymentController.removeVault(vault_, vaultId_);
    }

    /// @notice Updates the fee configuration for a specific vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the target vault
    /// @param fees_ Encoded fee configuration data
    function setVaultFees(
        address vault_,
        bytes calldata fees_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        // todo set vault fees
    }

    /// @notice Updates the fee recipient for a specific vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the target vault
    /// @param newRecipient_ Address of the new fee recipient
    function setFeeRecipient(
        address vault_,
        address newRecipient_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        // todo set fee recipient
    }

    /// @notice Toggles the still state of a vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the vault to toggle
    function toggleStillVault(
        address vault_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        // todo toggle vault still
    }

    /// @notice Adds or updates a module in a vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the target vault
    /// @param index_ Position of the module in the vault's module array
    /// @param replace_ Whether to replace an existing module or add a new one
    /// @param newModule_ Encoded module configuration data
    function addUpdateModule(
        address vault_,
        uint256 index_,
        bool replace_,
        bytes calldata newModule_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        // todo add/update module
    }

    /// @notice Removes a module from a vault
    /// @dev Only callable by accounts with VAULT_CONTROLLER_ROLE
    /// @param vault_ Address of the target vault
    /// @param index_ Position of the module to remove
    function removeModule(
        address vault_,
        uint256 index_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        // todo remove module
    }
}
