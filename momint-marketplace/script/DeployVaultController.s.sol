// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {VaultController} from "../src/controllers/VaultController.sol";
import {VaultStorage} from "../src/storage/VaultStorage.sol";
import {ModuleStorage} from "../src/storage/ModuleStorage.sol";
import {ContractStorage} from "../src/storage/ContractStorage.sol";
import {MomintFactory} from "../src/factories/MomintFactory.sol";
import {MomintVault} from "../src/vault/MomintVault.sol";
import {SPModule} from "../src/modules/SPModule.sol";
import {ContractData} from "../src/interfaces/IContractStorage.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract DeployVaultController is Script {
    bytes32 public constant VAULT_IMPLEMENTATION_ID =
        keccak256("VAULT_IMPL_V1");
    bytes32 public constant MODULE_IMPLEMENTATION_ID =
        keccak256("MODULE_IMPL_V1");
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying with address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy storage contracts
        VaultStorage vaultStorage = new VaultStorage(deployer);
        ModuleStorage moduleStorage = new ModuleStorage(deployer);
        ContractStorage contractStorage = new ContractStorage(deployer);
        MomintFactory factory = new MomintFactory(deployer);

        // Deploy vault implementation
        address vaultImplementation = address(new MomintVault());

        // Deploy module implementation
        SPModule moduleImpl = new SPModule();
        address moduleImplementation = address(moduleImpl);

        // Deploy controller
        VaultController controller = new VaultController(
            deployer,
            address(factory),
            address(moduleStorage),
            address(contractStorage),
            address(vaultStorage)
        );

        // Transfer ownerships
        vaultStorage.transferOwnership(address(controller));
        moduleStorage.transferOwnership(address(controller));
        contractStorage.transferOwnership(address(controller));
        factory.transferOwnership(address(controller));

        // Register vault implementation
        controller.addNewContract(
            VAULT_IMPLEMENTATION_ID,
            ContractData({
                contractAddress: vaultImplementation,
                initDataRequired: true
            })
        );

        // Register module implementation
        controller.addNewContract(
            MODULE_IMPLEMENTATION_ID,
            ContractData({
                contractAddress: moduleImplementation,
                initDataRequired: true
            })
        );

        console2.log("Deployment Addresses:");
        console2.log("VaultStorage:", address(vaultStorage));
        console2.log("ModuleStorage:", address(moduleStorage));
        console2.log("ContractStorage:", address(contractStorage));
        console2.log("Factory:", address(factory));
        console2.log("VaultImplementation:", vaultImplementation);
        console2.log("ModuleImplementation:", moduleImplementation);
        console2.log("VaultController:", address(controller));

        vm.stopBroadcast();
    }
}
