// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ModuleStorage} from "../../src/storage/ModuleStorage.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract ModuleStorageTest is Test {
    ModuleStorage public moduleStorage;
    address public admin = address(0x1);
    address public user = address(0x2);
    address public module = address(0x3);
    address public vault = address(0x4);

    event ModuleStored(
        address indexed module,
        uint256 projectId,
        string name,
        address vault
    );
    event ModuleRemoved(address indexed module);

    function setUp() public {
        moduleStorage = new ModuleStorage(admin);
    }

    function test_StoreModule() public {
        vm.startPrank(admin);

        string memory name = "Test Module";

        vm.expectEmit(true, true, true, true);
        emit ModuleStored(module, 1, name, vault);

        moduleStorage.storeModule(module, name, vault);

        ModuleStorage.ModuleInfo memory info = moduleStorage.getModule(module);
        assertEq(info.moduleAddress, module);
        assertEq(info.projectId, 1);
        assertEq(info.name, name);
        assertEq(info.vault, vault);
        assertTrue(info.active);
        assertTrue(info.deployedAt > 0);

        vm.stopPrank();
    }

    function test_RemoveModule() public {
        vm.startPrank(admin);

        moduleStorage.storeModule(module, "Test Module", vault);

        vm.expectEmit(true, false, false, false);
        emit ModuleRemoved(module);

        moduleStorage.removeModule(module);

        ModuleStorage.ModuleInfo memory info = moduleStorage.getModule(module);
        assertFalse(info.active);
        assertEq(info.moduleAddress, module);
        assertEq(info.vault, vault);

        vm.stopPrank();
    }

    function test_GetAllModules() public {
        vm.startPrank(admin);

        // Test empty list first
        ModuleStorage.ModuleInfo[] memory emptyModules = moduleStorage
            .getAllModules();
        assertEq(emptyModules.length, 0);

        // Store multiple modules
        address module2 = address(0x5);
        moduleStorage.storeModule(module, "Test Module 1", vault);
        moduleStorage.storeModule(module2, "Test Module 2", vault);

        // Test active modules
        ModuleStorage.ModuleInfo[] memory activeModules = moduleStorage
            .getAllModules();
        assertEq(activeModules.length, 2);
        assertEq(activeModules[0].moduleAddress, module);
        assertEq(activeModules[1].moduleAddress, module2);
        assertTrue(activeModules[0].active);
        assertTrue(activeModules[1].active);

        // Remove one module and verify list still contains both but one is inactive
        moduleStorage.removeModule(module);
        ModuleStorage.ModuleInfo[] memory mixedModules = moduleStorage
            .getAllModules();
        assertEq(mixedModules.length, 2);
        assertFalse(mixedModules[0].active);
        assertTrue(mixedModules[1].active);

        vm.stopPrank();
    }

    function test_GetVaultModules() public {
        vm.startPrank(admin);

        // Test empty list
        ModuleStorage.ModuleInfo[] memory emptyModules = moduleStorage
            .getVaultModules(vault);
        assertEq(emptyModules.length, 0);

        // Store modules for different vaults
        address vault2 = address(0x6);
        moduleStorage.storeModule(module, "Test Module 1", vault);
        moduleStorage.storeModule(address(0x5), "Test Module 2", vault2);

        // Test modules for specific vault
        ModuleStorage.ModuleInfo[] memory vaultModules = moduleStorage
            .getVaultModules(vault);
        assertEq(vaultModules.length, 1);
        assertEq(vaultModules[0].moduleAddress, module);
        assertEq(vaultModules[0].vault, vault);

        vm.stopPrank();
    }

    function test_ProjectIdIncrement() public {
        vm.startPrank(admin);

        assertEq(moduleStorage.currentProjectId(), 0);

        moduleStorage.storeModule(module, "Test Module 1", vault);
        assertEq(moduleStorage.currentProjectId(), 1);

        moduleStorage.storeModule(address(0x5), "Test Module 2", vault);
        assertEq(moduleStorage.currentProjectId(), 2);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedStore() public {
        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        moduleStorage.storeModule(module, "Test Module", vault);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedRemove() public {
        vm.startPrank(admin);
        moduleStorage.storeModule(module, "Test Module", vault);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        moduleStorage.removeModule(module);
        vm.stopPrank();
    }

    function test_RevertDuplicateModule() public {
        vm.startPrank(admin);

        moduleStorage.storeModule(module, "Test Module", vault);

        vm.expectRevert(ModuleStorage.ModuleAlreadyStored.selector);
        moduleStorage.storeModule(module, "Duplicate Module", vault);

        vm.stopPrank();
    }

    function test_RevertRemoveNonExistentModule() public {
        vm.startPrank(admin);

        vm.expectRevert(ModuleStorage.ModuleNotStored.selector);
        moduleStorage.removeModule(address(0x123));

        vm.stopPrank();
    }
}
