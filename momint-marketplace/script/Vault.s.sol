// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultController} from "../src/controllers/VaultController.sol";
import {VaultStorage} from "../src/storage/VaultStorage.sol";
import {ModuleStorage} from "../src/storage/ModuleStorage.sol";
import {ContractStorage} from "../src/storage/ContractStorage.sol";
import {MomintFactory} from "../src/factories/MomintFactory.sol";
import {MomintVault} from "../src/vault/MomintVault.sol";
import {SPModule} from "../src/modules/SPModule.sol";
import {ContractData} from "../src/interfaces/IContractStorage.sol";

contract VaultScript is Script {
    function run() external {
        // Retrieve private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy storage contracts
        VaultStorage vaultStorage = new VaultStorage(msg.sender);
        ModuleStorage moduleStorage = new ModuleStorage(msg.sender);
        ContractStorage contractStorage = new ContractStorage(msg.sender);

        // Deploy factory
        MomintFactory factory = new MomintFactory(msg.sender);

        // Deploy VaultController
        VaultController controller = new VaultController(msg.sender);

        // Set up registries in controller
        controller.setRegistries(
            address(vaultStorage),
            address(moduleStorage),
            address(contractStorage),
            address(factory)
        );

        // Store implementations in ContractStorage
        bytes32 vaultImplementationId = keccak256("VAULT_IMPLEMENTATION_V1");
        bytes32 moduleImplementationId = keccak256("MODULE_IMPLEMENTATION_V1");

        // Deploy implementation contracts
        MomintVault vaultImplementation = new MomintVault();
        SPModule moduleImplementation = new SPModule(
            0, // This will be overridden in actual deployments
            address(0), // This will be overridden in actual deployments
            address(0), // This will be overridden in actual deployments
            "", // This will be overridden in actual deployments
            0, // This will be overridden in actual deployments
            0, // This will be overridden in actual deployments
            "", // This will be overridden in actual deployments
            address(0)
        );

        // Add implementations to contract storage
        contractStorage.addContract(
            vaultImplementationId,
            ContractData({
                contractAddress: address(vaultImplementation),
                initDataRequired: true
            })
        );

        contractStorage.addContract(
            moduleImplementationId,
            ContractData({
                contractAddress: address(moduleImplementation),
                initDataRequired: false
            })
        );

        vm.stopBroadcast();
    }
}
