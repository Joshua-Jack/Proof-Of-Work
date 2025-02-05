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

contract VaultController is AccessControl {
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
    ) external onlyRole(VAULT_CONTROLLER_ROLE) returns (address newVault) {
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

    function deployAndAddModule(
        address vault,
        address admin,
        string calldata projectName,
        uint256 pricePerShare,
        uint256 totalShares,
        string calldata uri,
        bool useClone,
        bytes32 moduleImplementationId // Add implementation ID parameter
    ) external onlyRole(VAULT_CONTROLLER_ROLE) returns (address moduleAddress) {
        ContractData memory moduleImpl = contractStorage.getContract(
            moduleImplementationId
        );
        if (moduleImpl.contractAddress == address(0))
            revert InvalidImplementation();

        uint256 nextProjectId = moduleStorage.currentProjectId() + 1;

        bytes memory constructorArgs = abi.encode(
            nextProjectId,
            admin,
            vault,
            projectName,
            pricePerShare,
            totalShares,
            uri
        );

        bytes32 salt = keccak256(
            abi.encodePacked(projectName, block.timestamp, nextProjectId)
        );

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: moduleImpl.contractAddress,
            initData: constructorArgs,
            salt: salt,
            deployType: useClone
                ? MomintFactory.DeploymentType.CLONE
                : MomintFactory.DeploymentType.DIRECT,
            creationCode: useClone ? bytes("") : type(SPModule).creationCode
        });

        try factory.deploy(config) returns (address module) {
            moduleAddress = module;
        } catch {
            revert DeploymentFailed();
        }

        // Store module information
        moduleStorage.storeModule(moduleAddress, projectName, vault);

        // Store contract information
        bytes32 moduleId = keccak256(abi.encodePacked("MODULE", moduleAddress));
        contractStorage.addContract(
            moduleId,
            ContractData({
                contractAddress: moduleAddress,
                initDataRequired: false
            })
        );

        // Add module to vault
        Module memory newModule = Module({
            module: IModule(moduleAddress),
            isSingleProject: true,
            active: true
        });
        IMomintVault(vault).addModule(newModule, false, 0);

        emit ModuleDeployed(moduleAddress, vault, projectName, useClone);
        return moduleAddress;
    }

    function getVaultInfo(
        address vault
    ) external view returns (VaultStorage.VaultInfo memory) {
        return vaultStorage.getVault(vault);
    }

    function getModuleInfo(
        address module
    ) external view returns (ModuleStorage.ModuleInfo memory) {
        return moduleStorage.getModule(module);
    }

    function getContractInfo(
        bytes32 id
    ) external view returns (ContractData memory) {
        return contractStorage.getContract(id);
    }
}
