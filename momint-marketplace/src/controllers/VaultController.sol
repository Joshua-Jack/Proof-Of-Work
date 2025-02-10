//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {VaultStorage} from "../storage/VaultStorage.sol";
import {ModuleStorage} from "../storage/ModuleStorage.sol";
import {ContractStorage} from "../storage/ContractStorage.sol";
import {MomintFactory} from "../factories/MomintFactory.sol";
import {IMomintVault, Module, VaultFees} from "../interfaces/IMomintVault.sol";
import {IModule} from "../interfaces/IModule.sol";
import {SPModule} from "../modules/SPModule.sol";
import {ContractData} from "../interfaces/IContractStorage.sol";
import {MomintVault} from "../vault/MomintVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VaultController is AccessControl, ReentrancyGuard {
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    VaultStorage public vaultStorage;
    ModuleStorage public moduleStorage;
    ContractStorage public contractStorage;
    MomintFactory public factory;

    event VaultDeployed(
        address indexed vault,
        string name,
        address asset,
        bool isClone
    );
    event ModuleDeployed(
        address indexed module,
        address indexed vault,
        string name,
        bool isClone
    );
    event RegistriesSet(
        address vaultStorage,
        address moduleStorage,
        address contractStorage,
        address factory
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

    constructor(address admin) {
        if (admin == address(0)) revert UnauthorizedCaller();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_CONTROLLER_ROLE, admin);
    }

    function setRegistries(
        address vaultStorage_,
        address moduleStorage_,
        address contractStorage_,
        address factory_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            vaultStorage_ == address(0) ||
            moduleStorage_ == address(0) ||
            contractStorage_ == address(0) ||
            factory_ == address(0)
        ) revert InvalidAddress();

        vaultStorage = VaultStorage(vaultStorage_);
        moduleStorage = ModuleStorage(moduleStorage_);
        contractStorage = ContractStorage(contractStorage_);
        factory = MomintFactory(factory_);

        emit RegistriesSet(
            vaultStorage_,
            moduleStorage_,
            contractStorage_,
            factory_
        );
    }

    function deployNewVault(
        bytes32 implementationId,
        string memory name,
        address asset,
        address admin,
        address feeRecipient,
        VaultFees memory fees,
        bool useClone
    )
        external
        nonReentrant
        onlyRole(VAULT_CONTROLLER_ROLE)
        returns (address newVault)
    {
        if (asset == address(0)) revert InvalidAddress();
        if (feeRecipient == address(0)) revert InvalidAddress();
        if (admin == address(0)) revert InvalidAddress();
        if (
            fees.depositFee > 10000 || // Max 100%
            fees.withdrawalFee > 10000 || // Max 100%
            fees.protocolFee > 10000 // Max 100%
        ) revert InvalidFeeValue();
        ContractData memory implData = contractStorage.getContract(
            implementationId
        );
        if (implData.contractAddress == address(0)) revert ContractNotFound();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            MomintVault.initialize.selector,
            asset,
            string(abi.encodePacked("mv", name)),
            name,
            admin,
            feeRecipient,
            fees
        );

        // Generate deterministic salt
        bytes32 salt = keccak256(abi.encodePacked(name, block.timestamp));

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: implData.contractAddress,
            initData: initData,
            salt: salt,
            deployType: useClone
                ? MomintFactory.DeploymentType.CLONE
                : MomintFactory.DeploymentType.DIRECT,
            creationCode: useClone ? bytes("") : type(MomintVault).creationCode
        });

        try factory.deploy(config) returns (address vault) {
            newVault = vault;
        } catch {
            revert DeploymentFailed();
        }

        // Store vault information
        vaultStorage.storeVault(newVault, name, asset);

        // Store contract information
        bytes32 vaultId = keccak256(abi.encodePacked("VAULT", newVault));
        contractStorage.addContract(
            vaultId,
            ContractData({contractAddress: newVault, initDataRequired: true})
        );

        emit VaultDeployed(newVault, name, asset, useClone);
        return newVault;
    }

    // Create a struct to hold deployment parameters
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

    function deployAndAddModule(
        address vault,
        address owner,
        string memory name,
        uint256 pricePerShare,
        uint256 totalShares,
        string memory uri,
        bool isClone,
        bytes32 salt,
        bytes32 moduleImplementationId
    ) external onlyRole(VAULT_CONTROLLER_ROLE) returns (address) {
        if (vault == address(0)) revert InvalidAddress();
        if (owner == address(0)) revert InvalidAddress();
        if (pricePerShare == 0) revert InvalidPricePerShare();
        if (totalShares == 0) revert InvalidTotalShares();
        if (bytes(uri).length == 0) revert InvalidURI();

        ModuleDeploymentParams memory params = ModuleDeploymentParams({
            vault: vault,
            owner: owner,
            name: name,
            pricePerShare: pricePerShare,
            totalShares: totalShares,
            uri: uri,
            isClone: isClone,
            salt: salt,
            moduleImplementationId: moduleImplementationId
        });

        return _deployAndAddModule(params);
    }

    function getVaultInfo(
        address vault
    ) public view returns (VaultStorage.VaultInfo memory) {
        return vaultStorage.getVault(vault);
    }

    function getModuleInfo(
        address module
    ) external view returns (ModuleStorage.ModuleInfo memory) {
        return moduleStorage.getModule(module);
    }

    function getContractInfo(
        bytes32 id
    ) public view returns (ContractData memory) {
        return contractStorage.getContract(id);
    }

    function _deployAndAddModule(
        ModuleDeploymentParams memory params
    ) internal returns (address) {
        VaultStorage.VaultInfo memory vaultInfo = getVaultInfo(params.vault);
        if (vaultInfo.vaultAddress == address(0)) {
            revert ContractNotFound();
        }
        ContractData memory moduleImpl = getContractInfo(
            params.moduleImplementationId
        );
        if (moduleImpl.contractAddress == address(0)) {
            revert InvalidImplementation();
        }
        bytes memory constructorArgs = abi.encode(
            params.vault,
            params.owner,
            params.name,
            params.pricePerShare,
            params.totalShares,
            params.uri,
            params.owner
        );
        MomintFactory.DeployConfig memory config;
        address module;
        if (params.isClone) {
            config = MomintFactory.DeployConfig({
                implementation: moduleImpl.contractAddress,
                initData: constructorArgs,
                salt: params.salt,
                deployType: MomintFactory.DeploymentType.CLONE,
                creationCode: ""
            });
        } else {
            config = MomintFactory.DeployConfig({
                implementation: moduleImpl.contractAddress,
                initData: constructorArgs,
                salt: params.salt,
                deployType: MomintFactory.DeploymentType.DIRECT,
                creationCode: type(SPModule).creationCode
            });
        }
        module = factory.deploy(config);
        if (module == address(0)) {
            revert DeploymentFailed();
        }
        moduleStorage.storeModule(module, params.name,params.vault);
        emit ModuleDeployed(module, params.vault, params.name, params.isClone);
        return module;
    } 
}
