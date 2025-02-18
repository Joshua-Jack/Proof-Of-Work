//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {VaultStorage} from "../storage/VaultStorage.sol";
import {ModuleStorage} from "../storage/ModuleStorage.sol";
import {ContractStorage} from "../storage/ContractStorage.sol";
import {MomintFactory} from "../factories/MomintFactory.sol";
import {IMomintVault, Module, VaultFees, VaultInfo} from "../interfaces/IMomintVault.sol";
import {IModule} from "../interfaces/IModule.sol";
import {SPModule} from "../modules/SPModule.sol";
import {ContractData} from "../interfaces/IContractStorage.sol";
import {MomintVault} from "../vault/MomintVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IContractStorage} from "../interfaces/IContractStorage.sol";
import {IVaultStorage} from "../interfaces/IVaultStorage.sol";
import {IModuleStorage} from "../interfaces/IModuleStorage.sol";
import {IMomintFactory} from "../interfaces/IMomintFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultController is AccessControl, ReentrancyGuard {
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    IMomintFactory immutable factory;
    IModuleStorage immutable moduleStorage;
    IContractStorage immutable contractStorage;
    IVaultStorage immutable vaultStorage;
    IMomintVault immutable momintVault;

    struct ModuleDeploymentParams {
        address vault;
        address owner;
        string name;
        uint256 pricePerShare;
        uint256 totalShares;
        string uri;
        bool isClone;
        bytes32 salt;
        bytes32 moduleImplementationId;
    }

    event VaultDeployed(address indexed vault, bytes32 indexed vaultId);
    event ModuleDeployed(address indexed module, bytes32 indexed moduleId);
    event PausingAllVaults();
    event UnpausingAllVaults();
    event RegistriesSet(
        address vaultStorage,
        address moduleStorage,
        address contractStorage,
        address factory
    );
    event VaultPaused(address indexed vault);
    event VaultUnpaused(address indexed vault);
    event AddingNewContract(bytes32 indexed id, ContractData);
    event RemovingContract(bytes32 indexed id);
    event EmergencyWithdrawal(
        address indexed vault,
        address indexed recipient,
        uint256 amount
    );

    error UnauthorizedCaller();
    error InvalidAddress();
    error DeploymentFailed();
    error InvalidImplementation();
    error ContractNotFound();
    error InvalidFees();
    error InvalidPricePerShare();
    error InvalidTotalShares();
    error InvalidURI();
    error InvalidFeeValue();
    error VaultNotStored();
    error InvalidModuleId();
    error InvalidIndex();
    error InsufficientLiquidity();
    error TransferFailed();

    constructor(
        address admin,
        address factory_,
        address moduleStorage_,
        address contractStorage_,
        address vaultStorage_
    ) {
        if (admin == address(0)) revert UnauthorizedCaller();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CONTROLLER_ROLE, admin);
        factory = IMomintFactory(factory_);
        moduleStorage = IModuleStorage(moduleStorage_);
        contractStorage = IContractStorage(contractStorage_);
        vaultStorage = IVaultStorage(vaultStorage_);
    }

    // Deployment Functions
    function deployModule(
        bytes32 id_,
        bytes calldata data_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (id_ == bytes32(0)) revert InvalidAddress();
        if (data_.length == 0) revert InvalidAddress();
        _moduleDeploymentHandler(id_, data_);
    }

    function _moduleDeploymentHandler(
        bytes32 id_,
        bytes calldata data_
    ) internal {
        if (id_ == bytes32(0)) revert InvalidAddress();
        if (data_.length == 0) revert InvalidAddress();
        ContractData memory contractData = contractStorage.getContract(id_);

        if (contractData.contractAddress == address(0))
            revert ContractNotFound();
        uint256 totalModules = moduleStorage.getAllModules().length;
        uint256 newProjectId = moduleStorage.getAllModules().length + 1;

        bytes32 salt = keccak256(
            abi.encode(
                address(this),
                contractData.contractAddress,
                totalModules,
                newProjectId,
                block.timestamp
            )
        );
        address newModule = factory.deployContract(contractData, data_, salt);
        moduleStorage.storeModule(newModule, id_);
        emit ModuleDeployed(newModule, id_);
    }

    function deployVault(
        bytes32 id_,
        bytes calldata data_
    )
        external
        onlyRole(VAULT_CONTROLLER_ROLE)
        returns (address newVaultAddress)
    {
        if (id_ == bytes32(0)) revert InvalidAddress();
        if (data_.length == 0) revert InvalidAddress();
        newVaultAddress = _vaultDeploymentHandler(id_, data_);
    }

    function _vaultDeploymentHandler(
        bytes32 id_,
        bytes calldata data_
    ) internal returns (address newVaultAddress) {
        if (id_ == bytes32(0)) revert InvalidAddress();
        if (data_.length == 0) revert InvalidAddress();
        ContractData memory contractData = contractStorage.getContract(id_);

        if (contractData.contractAddress == address(0))
            revert ContractNotFound();

        uint256 totalVaults = vaultStorage.getAllVaults().length;
        uint256 newVaultId = vaultStorage.getAllVaults().length + 1;

        bytes32 salt = keccak256(
            abi.encode(
                address(this),
                contractData.contractAddress,
                totalVaults,
                newVaultId,
                block.timestamp
            )
        );
        address newVault = factory.deployContract(contractData, data_, salt);
        vaultStorage.storeVault(newVault, id_);
        emit VaultDeployed(newVault, id_);
        return newVault;
    }

    // Emergency Functions
    function pauseVault(
        address vault
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (vault == address(0)) revert InvalidAddress();
        IMomintVault(vault).pause();
    }

    function unpauseVault(
        address vault
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (vault == address(0)) revert InvalidAddress();
        IMomintVault(vault).unpause();
    }

    function pauseAllVaults() external onlyRole(VAULT_CONTROLLER_ROLE) {
        emit PausingAllVaults();
        address[] memory vaults = vaultStorage.getAllVaults();
        for (uint256 i = 0; i < vaults.length; i++) {
            IMomintVault(vaults[i]).pause();
        }
    }

    function unpauseAllVaults() external onlyRole(VAULT_CONTROLLER_ROLE) {
        emit UnpausingAllVaults();
        address[] memory vaults = vaultStorage.getAllVaults();
        for (uint256 i = 0; i < vaults.length; i++) {
            IMomintVault(vaults[i]).unpause();
        }
    }

    // Utility Functions

    function addNewContract(
        bytes32 id_,
        ContractData calldata data
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (id_ == bytes32(0)) revert InvalidAddress();
        if (data.contractAddress == address(0)) revert InvalidAddress();
        emit AddingNewContract(id_, data);
        contractStorage.addContract(id_, data);
    }

    function removeContract(
        bytes32 id_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (id_ == bytes32(0)) revert InvalidAddress();
        emit RemovingContract(id_);
        contractStorage.removeContract(id_);
    }

    // // Accounting Functions

    function setMomintVaultFees(
        address vault,
        VaultFees calldata fees
    ) external {
        if (vault == address(0)) revert InvalidAddress();
        IMomintVault(vault).setVaultFees(fees);
    }

    function setFeeReceiver(address vault, address receiver) external {
        if (vault == address(0)) revert InvalidAddress();
        if (receiver == address(0)) revert InvalidAddress();
        IMomintVault(vault).setFeeRecipient(receiver);
    }

    // // Module Functions
    function addModule(
        address vault_,
        uint256 index_,
        Module memory moduleData
    ) external {
        if (vault_ == address(0)) revert InvalidAddress();
        if (index_ == 0) revert InvalidIndex();
        IMomintVault(vault_).addModule(moduleData, true, index_);
    }

    function removeModule(address vault_, uint256 index_) external {
        if (vault_ == address(0)) revert InvalidAddress();
        if (index_ == 0) revert InvalidIndex();
        IMomintVault(vault_).removeModule(index_);
    }

    function emergencyWithdrawVault(
        address vault_,
        address recipient_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (vault_ == address(0)) revert InvalidAddress();
        if (recipient_ == address(0)) revert InvalidAddress();
        VaultInfo memory vaultInfo = IMomintVault(vault_).getVaultInfo();
        // Get vault's base asset
        IERC20 baseAsset = vaultInfo.baseAsset;
        uint256 vaultBalance = baseAsset.balanceOf(vault_);

        if (vaultBalance == 0) revert InsufficientLiquidity();

        // Pause the vault first
        IMomintVault(vault_).pause();

        // Transfer all funds to recipient
        bool success = baseAsset.transferFrom(vault_, recipient_, vaultBalance);
        if (!success) revert TransferFailed();

        emit EmergencyWithdrawal(vault_, recipient_, vaultBalance);
    }

    function emergencyWithdrawAllVaults(
        address recipient_
    ) external onlyRole(VAULT_CONTROLLER_ROLE) {
        if (recipient_ == address(0)) revert InvalidAddress();

        address[] memory vaults = vaultStorage.getAllVaults();
        uint256 totalWithdrawn = 0;

        for (uint256 i = 0; i < vaults.length; i++) {
            address vault = vaults[i];
            VaultInfo memory vaultInfo = IMomintVault(vault).getVaultInfo();
            IERC20 baseAsset = vaultInfo.baseAsset;
            uint256 vaultBalance = baseAsset.balanceOf(vault);

            if (vaultBalance > 0) {
                // Pause the vault
                IMomintVault(vault).pause();

                // Transfer funds
                bool success = baseAsset.transferFrom(
                    vault,
                    recipient_,
                    vaultBalance
                );
                if (success) {
                    totalWithdrawn += vaultBalance;
                    emit EmergencyWithdrawal(vault, recipient_, vaultBalance);
                }
            }
        }

        if (totalWithdrawn == 0) revert InsufficientLiquidity();
    }
}
