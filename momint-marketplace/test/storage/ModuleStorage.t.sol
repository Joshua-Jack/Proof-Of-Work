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
    bytes32 public moduleId = keccak256("TEST_MODULE");

    event ModuleStored(address indexed module, bytes32 indexed moduleId);
    event ModuleRemoved(address indexed module);

    function setUp() public {
        moduleStorage = new ModuleStorage(admin);
    }

    function test_StoreModule() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, true);
        emit ModuleStored(module, moduleId);

        moduleStorage.storeModule(module, moduleId);

        assertTrue(moduleStorage.moduleExists(module));
        assertEq(moduleStorage.module(moduleId), module);
        assertEq(moduleStorage.getAllModules()[0], module);

        vm.stopPrank();
    }

    function test_RemoveModule() public {
        vm.startPrank(admin);

        moduleStorage.storeModule(module, moduleId);

        vm.expectEmit(true, false, false, false);
        emit ModuleRemoved(module);

        moduleStorage.removeModule(module, moduleId);

        assertFalse(moduleStorage.moduleExists(module));
        assertEq(moduleStorage.module(moduleId), address(0));

        vm.stopPrank();
    }

    function test_GetAllModules() public {
        vm.startPrank(admin);

        // Test empty list first
        address[] memory emptyModules = moduleStorage.getAllModules();
        assertEq(emptyModules.length, 0);

        // Store multiple modules
        address module2 = address(0x5);
        bytes32 moduleId2 = keccak256("TEST_MODULE_2");
        moduleStorage.storeModule(module, moduleId);
        moduleStorage.storeModule(module2, moduleId2);

        // Test stored modules
        address[] memory modules = moduleStorage.getAllModules();
        assertEq(modules.length, 2);
        assertEq(modules[0], module);
        assertEq(modules[1], module2);

        vm.stopPrank();
    }

    function test_GetModule() public {
        vm.startPrank(admin);

        moduleStorage.storeModule(module, moduleId);

        address retrievedModule = moduleStorage.getModule(moduleId);
        assertEq(retrievedModule, module);

        vm.stopPrank();
    }

    function test_MaxModules() public {
        vm.startPrank(admin);

        // Store up to max modules
        for (uint256 i = 0; i < moduleStorage.maxModules(); i++) {
            address newModule = address(uint160(i + 1));
            bytes32 newModuleId = keccak256(abi.encodePacked(i));
            moduleStorage.storeModule(newModule, newModuleId);
        }

        // Try to store one more
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleStorage.MaxModulesReached.selector,
                1001
            )
        );
        moduleStorage.storeModule(address(0x999), keccak256("OVERFLOW"));

        vm.stopPrank();
    }

    function test_RevertUnauthorizedStore() public {
        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        moduleStorage.storeModule(module, moduleId);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedRemove() public {
        vm.startPrank(admin);
        moduleStorage.storeModule(module, moduleId);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        moduleStorage.removeModule(module, moduleId);
        vm.stopPrank();
    }

    function test_RevertDuplicateModule() public {
        vm.startPrank(admin);

        moduleStorage.storeModule(module, moduleId);

        vm.expectRevert(ModuleStorage.ModuleAlreadyStored.selector);
        moduleStorage.storeModule(module, moduleId);

        vm.stopPrank();
    }

    function test_RevertRemoveNonExistentModule() public {
        vm.startPrank(admin);

        vm.expectRevert(ModuleStorage.ModuleNotStored.selector);
        moduleStorage.removeModule(address(0x123), moduleId);

        vm.stopPrank();
    }

    function test_RevertInvalidAddress() public {
        vm.startPrank(admin);

        vm.expectRevert(ModuleStorage.InvalidAddress.selector);
        moduleStorage.storeModule(address(0), moduleId);

        vm.stopPrank();
    }

    function test_RevertModuleDoesNotExist() public {
        vm.startPrank(admin);

        bytes32 nonExistentId = keccak256("NON_EXISTENT");
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleStorage.ModuleDoesNotExist.selector,
                nonExistentId
            )
        );
        moduleStorage.getModule(nonExistentId);

        vm.stopPrank();
    }
}
