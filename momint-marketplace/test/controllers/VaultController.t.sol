// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {VaultController} from "../../src/controllers/VaultController.sol";
import {VaultStorage} from "../../src/storage/VaultStorage.sol";
import {ModuleStorage} from "../../src/storage/ModuleStorage.sol";
import {ContractStorage} from "../../src/storage/ContractStorage.sol";
import {MomintFactory} from "../../src/factories/MomintFactory.sol";
import {MomintVault} from "../../src/vault/MomintVault.sol";
import {SPModule} from "../../src/modules/SPModule.sol";
import {VaultFees} from "../../src/interfaces/IMomintVault.sol";
import {ContractData} from "../../src/interfaces/IContractStorage.sol";
import {MockERC20} from "../../test/mocks/MockERC20.sol";

contract VaultControllerTest is Test {
    VaultController public controller;
    VaultStorage public vaultStorage;
    ModuleStorage public moduleStorage;
    ContractStorage public contractStorage;
    MomintFactory public factory;
    MockERC20 public asset;

    address public admin = address(0x1);
    address public user = address(0x2);
    address public user2 = address(0x3);
    address public feeRecipient = address(0x3);

    bytes32 public constant VAULT_IMPLEMENTATION_ID =
        keccak256("VAULT_IMPL_V1");
    bytes32 public constant MODULE_IMPLEMENTATION_ID =
        keccak256("MODULE_IMPL_V1");

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

    function setUp() public {
        console2.log("Setting up test environment...");
        console2.log("Admin address:", admin);

        // Deploy mock asset
        asset = new MockERC20("Test Token", "TEST", 18);
        console2.log("Deployed mock asset at:", address(asset));

        // Deploy core contracts
        controller = new VaultController(admin);
        vaultStorage = new VaultStorage(address(controller));
        moduleStorage = new ModuleStorage(address(controller));
        contractStorage = new ContractStorage(address(controller));
        factory = new MomintFactory(address(controller)); // Initially owned by admin

        console2.log("Deployed core contracts:");
        console2.log("- VaultStorage:", address(vaultStorage));
        console2.log("- ModuleStorage:", address(moduleStorage));
        console2.log("- ContractStorage:", address(contractStorage));
        console2.log("- Factory:", address(factory));
        console2.log("- Controller:", address(controller));

        // Deploy implementations
        address vaultImpl = address(new MomintVault());
        address moduleImpl = address(
            new SPModule(
                1,
                admin,
                address(vaultImpl),
                "Test Project",
                5e6,
                100,
                "ipfs://metadata",
                user2
            )
        );

        console2.log("Deployed implementations:");
        console2.log("- Vault implementation:", vaultImpl);
        console2.log("- Module implementation:", moduleImpl);

        // Register implementations and set up permissions
        vm.startPrank(address(controller));

        contractStorage.addContract(
            VAULT_IMPLEMENTATION_ID,
            ContractData({contractAddress: vaultImpl, initDataRequired: true})
        );

        contractStorage.addContract(
            MODULE_IMPLEMENTATION_ID,
            ContractData({contractAddress: moduleImpl, initDataRequired: false})
        );

        // Transfer factory ownership to controller
        // factory.transferOwnership(address(controller));
        // contractStorage.transferOwnership(address(controller));
        // vaultStorage.transferOwnership(address(controller));
        // moduleStorage.transferOwnership(address(controller));
        // Set up controller
        controller.setRegistries(
            address(vaultStorage),
            address(moduleStorage),
            address(contractStorage),
            address(factory)
        );

        vm.stopPrank();
        console2.log("Setup complete!");
    }

    // function test_deployVault_Clone() public {
    //     console2.log("\nTesting vault deployment (clone)...");
    //     _testDeployVault(true);
    // }

    // function test_deployVault_Direct() public {
    //     console2.log("\nTesting vault deployment (direct)...");
    //     _testDeployVault(false);
    // }

    // function _testDeployVault(bool useClone) internal {
    //     string memory vaultName = "Test Vault";
    //     VaultFees memory fees = VaultFees({
    //         depositFee: 0,
    //         withdrawalFee: 0,
    //         protocolFee: 0
    //     });

    //     vm.startPrank(admin);

    //     console2.log("Deploying vault with name:", vaultName);
    //     console2.log("Deployment type:", useClone ? "Clone" : "Direct");

    //     address newVault = controller.deployNewVault(
    //         VAULT_IMPLEMENTATION_ID,
    //         vaultName,
    //         address(asset),
    //         admin,
    //         feeRecipient,
    //         fees,
    //         useClone
    //     );

    //     console2.log("Vault deployed at:", newVault);

    //     // Verify vault was stored
    //     VaultStorage.VaultInfo memory vaultInfo = controller.getVaultInfo(
    //         newVault
    //     );
    //     console2.log("Vault storage verification:");
    //     console2.log("- Name:", vaultInfo.name);
    //     console2.log("- Asset:", vaultInfo.asset);
    //     console2.log("- Active:", vaultInfo.active);

    //     assertTrue(newVault != address(0), "Vault not deployed");
    //     assertEq(vaultInfo.name, vaultName, "Wrong vault name");
    //     assertEq(vaultInfo.asset, address(asset), "Wrong asset");
    //     assertTrue(vaultInfo.active, "Vault not active");

    //     vm.stopPrank();
    // }

    // function _testDeployAndAddModule(bool useClone) internal {
    //     // First deploy a vault
    //     address vault = _deployTestVault();
    //     console2.log("Test vault deployed at:", vault);

    //     string memory projectName = "Test Project";
    //     vm.startPrank(admin);

    //     console2.log("Deploying module with name:", projectName);
    //     console2.log("Deployment type:", useClone ? "Clone" : "Direct");

    //     address module = controller.deployAndAddModule(
    //         vault,
    //         admin,
    //         projectName,
    //         1e18, // pricePerShare
    //         100e18, // totalShares
    //         "ipfs://test",
    //         useClone,
    //         MODULE_IMPLEMENTATION_ID
    //     );

    //     console2.log("Module deployed at:", module);

    //     // Verify module was stored
    //     ModuleStorage.ModuleInfo memory moduleInfo = controller.getModuleInfo(
    //         module
    //     );
    //     console2.log("Module storage verification:");
    //     console2.log("- Name:", moduleInfo.name);
    //     console2.log("- Vault:", moduleInfo.vault);
    //     console2.log("- Project ID:", moduleInfo.projectId);
    //     console2.log("- Active:", moduleInfo.active);

    //     assertTrue(module != address(0), "Module not deployed");
    //     assertEq(moduleInfo.name, projectName, "Wrong module name");
    //     assertEq(moduleInfo.vault, vault, "Wrong vault");
    //     assertTrue(moduleInfo.active, "Module not active");

    //     vm.stopPrank();
    // }

    function test_deployAndAddModule_Direct() public {
        // First, deploy a test vault.
        address vault = _deployTestVault();

        // Define project/module parameters.
        string memory projectName = "Test Project Direct";
        vm.startPrank(admin);

        // Deploy and add the module (useClone set to false)
        address moduleAddress = controller.deployAndAddModule(
            vault,
            admin,
            projectName,
            1e18, // pricePerShare
            100e18, // totalShares
            "ipfs://test",
            false, // useClone set to false for direct deployment
            MODULE_IMPLEMENTATION_ID
        );

        // Verify that the module was stored in ModuleStorage correctly.
        ModuleStorage.ModuleInfo memory moduleInfo = controller.getModuleInfo(
            moduleAddress
        );
        console2.log("\nModule storage verification:");
        console2.log("- Name:", moduleInfo.name);
        console2.log("- Vault:", moduleInfo.vault);
        console2.log("- Project ID:", moduleInfo.projectId);
        console2.log("- Active:", moduleInfo.active);

        assertTrue(moduleAddress != address(0), "Module not deployed");
        assertEq(moduleInfo.name, projectName, "Module name mismatch");
        assertEq(moduleInfo.vault, vault, "Vault address mismatch");
        assertTrue(moduleInfo.active, "Module is not active");

        vm.stopPrank();
    }

    // function test_RevertCases() public {
    //     console2.log("\nTesting revert cases...");

    //     // Test invalid implementation ID
    //     vm.startPrank(admin);
    //     bytes32 invalidId = keccak256("INVALID_ID");
    //     console2.log(
    //         "Testing invalid implementation ID:",
    //         vm.toString(invalidId)
    //     );

    //     vm.expectRevert(VaultController.ContractNotFound.selector);
    //     controller.deployNewVault(
    //         invalidId,
    //         "Test",
    //         address(asset),
    //         admin,
    //         feeRecipient,
    //         VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0}),
    //         true
    //     );
    //     console2.log("Invalid implementation revert test passed");

    //     // Test unauthorized caller
    //     vm.stopPrank();
    //     vm.startPrank(user);
    //     console2.log("Testing unauthorized caller:", user);

    //     vm.expectRevert();
    //     controller.deployNewVault(
    //         VAULT_IMPLEMENTATION_ID,
    //         "Test",
    //         address(asset),
    //         admin,
    //         feeRecipient,
    //         VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0}),
    //         true
    //     );
    //     console2.log("Unauthorized caller revert test passed");

    //     vm.stopPrank();
    // }

    function _deployTestVault() internal returns (address) {
        vm.startPrank(admin);
        address vault = controller.deployNewVault(
            VAULT_IMPLEMENTATION_ID,
            "Test Vault",
            address(asset),
            admin,
            feeRecipient,
            VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0}),
            true
        );
        vm.stopPrank();
        return vault;
    }

    // function test_setRegistriesWithZeroAddress() external {
    //     vm.startPrank(admin);
    //     // Try to set a zero address for one of the registries
    //     vm.expectRevert(VaultController.InvalidAddress.selector);
    //     controller.setRegistries(
    //         address(0),
    //         address(moduleStorage),
    //         address(contractStorage),
    //         address(factory)
    //     );
    //     vm.stopPrank();
    // }

    // function test_setRegistriesUnauthorized() external {
    //     // The admin has DEFAULT_ADMIN_ROLE so another user without the role should be rejected.
    //     vm.startPrank(user);
    //     vm.expectRevert(); // You can also check for the proper revert reason (e.g. AccessControl error)
    //     controller.setRegistries(
    //         address(vaultStorage),
    //         address(moduleStorage),
    //         address(contractStorage),
    //         address(factory)
    //     );
    //     vm.stopPrank();
    // }

    // function test_deployVaultUnauthorized() external {
    //     vm.startPrank(user);
    //     vm.expectRevert(); // Expect a revert due to missing role.
    //     controller.deployNewVault(
    //         VAULT_IMPLEMENTATION_ID,
    //         "Unauthorized Vault",
    //         address(asset),
    //         admin,
    //         feeRecipient,
    //         VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0}),
    //         true
    //     );
    //     vm.stopPrank();
    // }

    // function test_deployModuleUnauthorized() external {
    //     // First deploy a vault as admin
    //     address vault = _deployTestVault();
    //     vm.startPrank(user);
    //     vm.expectRevert(); // Expect a revert due to unauthorized caller.
    //     controller.deployAndAddModule(
    //         vault,
    //         user,
    //         "Unauthorized Module",
    //         1e18,
    //         100e18,
    //         "ipfs://test",
    //         true,
    //         MODULE_IMPLEMENTATION_ID
    //     );
    //     vm.stopPrank();
    // }

    // function test_getContractInfoAfterVaultDeploy() external {
    //     vm.startPrank(admin);
    //     address vault = controller.deployNewVault(
    //         VAULT_IMPLEMENTATION_ID,
    //         "Info Test Vault",
    //         address(asset),
    //         admin,
    //         feeRecipient,
    //         VaultFees({depositFee: 0, withdrawalFee: 0, protocolFee: 0}),
    //         true
    //     );
    //     // Generate the contract id exactly as in the controller
    //     bytes32 vaultId = keccak256(abi.encodePacked("VAULT", vault));
    //     ContractData memory data = controller.getContractInfo(vaultId);
    //     assertEq(
    //         data.contractAddress,
    //         vault,
    //         "Vault contract not registered correctly"
    //     );
    //     vm.stopPrank();
    // }

    // function test_deployModuleInvalidImplementation() external {
    //     // First deploy a vault so we have a valid vault address
    //     address vault = _deployTestVault();
    //     vm.startPrank(admin);

    //     bytes32 invalidModuleId = keccak256("INVALID_MODULE");
    //     vm.expectRevert(VaultController.InvalidImplementation.selector);
    //     controller.deployAndAddModule(
    //         vault,
    //         admin,
    //         "Test Project",
    //         1e18, // pricePerShare
    //         100e18, // totalShares
    //         "ipfs://test",
    //         true,
    //         invalidModuleId
    //     );
    //     vm.stopPrank();
    // }
}
