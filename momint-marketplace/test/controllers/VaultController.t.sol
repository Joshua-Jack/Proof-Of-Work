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
import {InitParams} from "../../src/vault/MomintVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Module} from "../../src/interfaces/IMomintVault.sol";
import {IModule} from "../../src/interfaces/IModule.sol";
import {MomintVault} from "../../src/vault/MomintVault.sol";
import {InitParams} from "../../src/interfaces/IMomintVault.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract VaultControllerTest is Test {
    VaultController public controller;
    VaultStorage public vaultStorage;
    ModuleStorage public moduleStorage;
    ContractStorage public contractStorage;
    MomintFactory public factory;
    MockERC20 public asset;
    SPModule public moduleImpl;
    MomintVault public vault;
    IERC20 public USDT = IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);

    address public admin = address(0x1);
    address public user = address(0x2);
    address public user2 = address(0x3);
    address public feeRecipient = address(0x3);
    address public vaultImplementation;
    address public moduleImplementation;

    bytes32 public constant VAULT_IMPLEMENTATION_ID =
        keccak256("VAULT_IMPL_V1");
    bytes32 public constant MODULE_IMPLEMENTATION_ID =
        keccak256("MODULE_IMPL_V1");
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    event VaultDeployed(address indexed vault, bytes32 indexed vaultId);
    event ModuleDeployed(address indexed module, bytes32 indexed moduleId);
    event PausingAllVaults();
    event UnpausingAllVaults();
    event VaultPaused(address indexed vault);
    event VaultUnpaused(address indexed vault);
    event AddingNewContract(bytes32 indexed id, ContractData data);
    event RemovingContract(bytes32 indexed id);

    string constant LISK_RPC_URL = "https://rpc.api.lisk.com";
    uint256 constant FORK_BLOCK_NUMBER = 11774326;

    function setUp() public {
        console2.log("Setting up test environment...");
        console2.log("Admin address:", admin);

        uint256 lisk = vm.createFork(LISK_RPC_URL, FORK_BLOCK_NUMBER);
        vm.selectFork(lisk);
        // Deploy mock asset
        asset = new MockERC20("Test Token", "TEST", 18);
        console2.log("Deployed mock asset at:", address(asset));

        vm.startPrank(admin);

        // Deploy storage contracts

        vaultStorage = new VaultStorage(admin);
        moduleStorage = new ModuleStorage(admin);
        contractStorage = new ContractStorage(admin);
        factory = new MomintFactory(admin);
        controller = new VaultController(
            admin,
            address(factory),
            address(moduleStorage),
            address(contractStorage),
            address(vaultStorage)
        );

        vaultStorage.transferOwnership(address(controller));
        moduleStorage.transferOwnership(address(controller));
        contractStorage.transferOwnership(address(controller));
        factory.transferOwnership(address(controller));

        // Deploy and initialize vault implementation
        vaultImplementation = Clones.clone(address(new MomintVault()));
        vault = MomintVault(vaultImplementation);
        InitParams memory params = InitParams({
            baseAsset: USDT,
            symbol: "MV",
            shareName: "Momint Vault",
            owner: address(controller),
            feeRecipient: admin,
            fees: VaultFees({
                depositFee: 500,
                withdrawalFee: 100,
                protocolFee: 300
            }),
            liquidityHoldBP: 3000, // 30%
            maxOwnerShareBP: 7000 // 70%
        });
        vault.initialize(params);

        // Deploy module implementation
        moduleImpl = new SPModule();
        moduleImpl.initialize(
            admin,
            address(vaultImplementation),
            "Test Module",
            5e6,
            100,
            "ipfs://metadata",
            user2
        );
        moduleImplementation = address(moduleImpl);

        // Register implementations in contract storage
        controller.addNewContract(
            VAULT_IMPLEMENTATION_ID,
            ContractData({
                contractAddress: vaultImplementation,
                initDataRequired: true
            })
        );

        controller.addNewContract(
            MODULE_IMPLEMENTATION_ID,
            ContractData({
                contractAddress: moduleImplementation,
                initDataRequired: true
            })
        );

        // Grant roles
        controller.grantRole(VAULT_CONTROLLER_ROLE, admin);

        vm.stopPrank();

        console2.log("Setup complete!");
    }

    function test_RevertWhen_NonAdminCallsRestrictedFunction() public {
        vm.startPrank(admin);
        // First register the vault implementation
        bytes32 vaultId = keccak256("TEST_VAULT_V1");
        ContractData memory vaultData = ContractData({
            contractAddress: vaultImplementation,
            initDataRequired: true
        });

        controller.addNewContract(vaultId, vaultData);
        vm.stopPrank();

        vm.startPrank(user);
        // Then attempt deployment
        bytes memory initData = _createVaultInitData();

        vm.expectRevert();
        address deployedVault = controller.deployVault(vaultId, initData);

        vm.stopPrank();
    }

    function test_deployVault() public {
        vm.startPrank(admin);

        // First register the vault implementation
        bytes32 vaultId = keccak256("TEST_VAULT_V1");
        ContractData memory vaultData = ContractData({
            contractAddress: vaultImplementation,
            initDataRequired: true
        });

        controller.addNewContract(vaultId, vaultData);

        // Then attempt deployment
        bytes memory initData = _createVaultInitData();

        address deployedVault = controller.deployVault(vaultId, initData);

        assertTrue(deployedVault != address(0), "Vault not deployed");
        assertTrue(vaultStorage.vaultExists(deployedVault), "Vault not stored");

        vm.stopPrank();
    }

    function test_RevertWhen_InvalidVaultAddress() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.pauseVault(address(0));

        vm.stopPrank();
    }

    function test_RevertWhen_InvalidModuleId() public {
        vm.startPrank(admin);

        bytes memory moduleInitData = _createModuleInitData(address(0x1));
        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.deployModule(bytes32(0), moduleInitData);

        vm.stopPrank();
    }

    // function test_deployModule() public {
    //     vm.startPrank(admin);

    //     address vault = _deployTestVault();
    //     bytes memory moduleInitData = _createModuleInitData(vault);

    //     address expectedModule = factory.predictDeployedAddress(
    //         moduleImplementation,
    //         moduleInitData,
    //         keccak256(
    //             abi.encode(
    //                 address(controller),
    //                 moduleImplementation,
    //                 moduleStorage.getAllModules().length,
    //                 moduleStorage.getAllModules().length + 1,
    //                 block.timestamp
    //             )
    //         )
    //     );

    //     vm.expectEmit(true, true, false, false);
    //     emit ModuleDeployed(expectedModule, MODULE_IMPLEMENTATION_ID);

    //     address moduleAddress = controller.deployModule(
    //         MODULE_IMPLEMENTATION_ID,
    //         moduleInitData
    //     );

    //     assertTrue(moduleAddress != address(0), "Module not deployed");
    //     assertTrue(
    //         moduleStorage.moduleExists(moduleAddress),
    //         "Module not stored"
    //     );
    //     assertEq(moduleAddress, expectedModule, "Unexpected module address");

    //     vm.stopPrank();
    // }

    function test_pauseAndUnpauseVault() public {
        vm.startPrank(admin);
        address vault = _deployTestVault();

        controller.pauseVault(vault);
        assertTrue(MomintVault(vault).paused(), "Vault should be paused");

        controller.unpauseVault(vault);
        assertFalse(MomintVault(vault).paused(), "Vault should be unpaused");

        vm.stopPrank();
    }

    function test_pauseAndUnpauseAllVaults() public {
        vm.startPrank(admin);

        // Deploy multiple vaults
        address vault1 = _deployTestVault();
        address vault2 = _deployTestVault();

        vm.expectEmit(true, true, false, false);
        emit PausingAllVaults();
        controller.pauseAllVaults();

        assertTrue(MomintVault(vault1).paused(), "Vault 1 should be paused");
        assertTrue(MomintVault(vault2).paused(), "Vault 2 should be paused");

        vm.expectEmit(true, true, false, false);
        emit UnpausingAllVaults();
        controller.unpauseAllVaults();

        assertFalse(MomintVault(vault1).paused(), "Vault 1 should be unpaused");
        assertFalse(MomintVault(vault2).paused(), "Vault 2 should be unpaused");

        vm.stopPrank();
    }

    function test_addAndRemoveContract() public {
        vm.startPrank(admin);

        bytes32 newId = keccak256("NEW_CONTRACT");
        ContractData memory data = ContractData({
            contractAddress: address(0x123),
            initDataRequired: true
        });

        controller.addNewContract(newId, data);
        assertTrue(
            contractStorage.contractExists(newId),
            "Contract should be added"
        );

        controller.removeContract(newId);
        assertFalse(
            contractStorage.contractExists(newId),
            "Contract should be removed"
        );

        vm.stopPrank();
    }

    function test_RevertWhen_DeployModuleWithEmptyData() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.deployModule(MODULE_IMPLEMENTATION_ID, "");

        vm.stopPrank();
    }

    function test_RevertWhen_DeployVaultWithEmptyData() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.deployVault(VAULT_IMPLEMENTATION_ID, "");

        vm.stopPrank();
    }

    function test_RevertWhen_ContractNotFound() public {
        vm.startPrank(admin);

        bytes memory initData = _createVaultInitData();
        bytes32 nonExistentId = keccak256("NON_EXISTENT");

        vm.expectRevert(VaultController.ContractNotFound.selector);
        controller.deployVault(nonExistentId, initData);

        vm.stopPrank();
    }

    // function test_setVaultFees() public {
    //     vm.startPrank(admin);

    //     address vault = _deployTestVault();
    //     VaultFees memory newFees = VaultFees({
    //         depositFee: 300,
    //         withdrawalFee: 200,
    //         protocolFee: 400
    //     });

    //     controller.setMomintVaultFees(vault, newFees);

    //     (
    //         uint256 depositFee,
    //         uint256 withdrawalFee,
    //         uint256 protocolFee
    //     ) = MomintVault(vault).fees();
    //     assertEq(depositFee, 300, "Deposit fee not set correctly");
    //     assertEq(withdrawalFee, 200, "Withdrawal fee not set correctly");
    //     assertEq(protocolFee, 400, "Protocol fee not set correctly");

    //     vm.stopPrank();
    // }

    function test_RevertWhen_SetFeesWithInvalidVault() public {
        vm.startPrank(admin);

        VaultFees memory newFees = VaultFees({
            depositFee: 300,
            withdrawalFee: 200,
            protocolFee: 400
        });

        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.setMomintVaultFees(address(0), newFees);

        vm.stopPrank();
    }

    function test_setFeeReceiver() public {
        vm.startPrank(admin);

        address vault = _deployTestVault();
        address newReceiver = address(0x123);

        controller.setFeeReceiver(vault, newReceiver);

        assertEq(
            MomintVault(vault).feeRecipient(),
            newReceiver,
            "Fee receiver not set correctly"
        );

        vm.stopPrank();
    }

    function test_RevertWhen_SetFeeReceiverWithInvalidAddress() public {
        vm.startPrank(admin);

        address vault = _deployTestVault();

        vm.expectRevert(VaultController.InvalidAddress.selector);
        controller.setFeeReceiver(vault, address(0));

        vm.stopPrank();
    }

    // function test_moduleManagement() public {
    //     vm.startPrank(admin);

    //     address vault = _deployTestVault();
    //     address moduleAddr = controller.deployModule(
    //         MODULE_IMPLEMENTATION_ID,
    //         _createModuleInitData(vault)
    //     );

    //     // Test adding module
    //     Module memory moduleData = Module({
    //         module: IModule(moduleAddr),
    //         isSingleProject: true,
    //         active: true
    //     });

    //     controller.addModule(vault, 1, moduleData);

    //     // Verify module was added
    //     (IModule module, bool isSingleProject, bool active) = MomintVault(vault)
    //         .modules(1);
    //     assertEq(address(module), moduleAddr, "Module not added correctly");
    //     assertTrue(isSingleProject, "Module type not set correctly");
    //     assertTrue(active, "Module not active");

    //     // Test removing module
    //     controller.removeModule(vault, 1);

    //     // Verify module was removed
    //     (, , active) = MomintVault(vault).modules(1);
    //     assertFalse(active, "Module not removed");

    //     vm.stopPrank();
    // }

    function test_RevertWhen_AddModuleWithInvalidIndex() public {
        vm.startPrank(admin);

        address vault = _deployTestVault();
        Module memory moduleData = Module({
            module: IModule(address(0x123)),
            isSingleProject: true,
            active: true
        });

        vm.expectRevert(VaultController.InvalidIndex.selector);
        controller.addModule(vault, 0, moduleData);

        vm.stopPrank();
    }

    // Helper functions

    function _deployTestVault() internal returns (address) {
        bytes memory initData = _createVaultInitData();
        return controller.deployVault(VAULT_IMPLEMENTATION_ID, initData);
    }

    function _createVaultInitData() internal view returns (bytes memory) {
        return
            abi.encodeWithSelector(
                MomintVault.initialize.selector,
                InitParams({
                    baseAsset: IERC20(address(asset)),
                    symbol: "MV",
                    shareName: "Test Vault",
                    owner: address(controller),
                    feeRecipient: admin,
                    fees: VaultFees({
                        depositFee: 0,
                        withdrawalFee: 0,
                        protocolFee: 0
                    }),
                    liquidityHoldBP: 3000,
                    maxOwnerShareBP: 7000
                })
            );
    }

    function _createModuleInitData(
        address vault
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                SPModule.initialize.selector,
                1,
                address(0x1),
                vault,
                "Test Project",
                5e6,
                100,
                "ipfs://metadata",
                address(0x2)
            );
    }
}
