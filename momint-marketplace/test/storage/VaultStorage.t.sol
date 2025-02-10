// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {VaultStorage} from "../../src/storage/VaultStorage.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract VaultStorageTest is Test {
    VaultStorage public vaultStorage;
    address public admin = address(0x1);
    address public user = address(0x2);
    address public vault = address(0x3);
    address public asset;

    event VaultStored(address indexed vault, string name, address asset);
    event VaultRemoved(address indexed vault);

    function setUp() public {
        vaultStorage = new VaultStorage(admin);
        asset = address(new MockERC20("Test Token", "TEST", 18));
    }

    function test_StoreVault() public {
        vm.startPrank(admin);

        string memory name = "Test Vault";

        vm.expectEmit(true, false, false, true);
        emit VaultStored(vault, name, asset);

        vaultStorage.storeVault(vault, name, asset);

        VaultStorage.VaultInfo memory info = vaultStorage.getVault(vault);
        assertEq(info.vaultAddress, vault);
        assertEq(info.name, name);
        assertEq(info.asset, asset);
        assertTrue(info.active);
        assertTrue(info.deployedAt > 0);

        vm.stopPrank();
    }

    function test_RemoveVault() public {
        vm.startPrank(admin);

        vaultStorage.storeVault(vault, "Test Vault", asset);

        vm.expectEmit(true, false, false, true);
        emit VaultRemoved(vault);

        vaultStorage.removeVault(vault);

        VaultStorage.VaultInfo memory info = vaultStorage.getVault(vault);
        assertFalse(info.active);
        assertEq(info.vaultAddress, vault); // Address should remain
        assertEq(info.asset, asset); // Asset should remain

        vm.stopPrank();
    }

    function test_GetAllVaults() public {
        vm.startPrank(admin);

        // Test empty list first
        VaultStorage.VaultInfo[] memory emptyVaults = vaultStorage
            .getAllVaults();
        assertEq(emptyVaults.length, 0);

        // Store multiple vaults
        address vault2 = address(0x4);
        vaultStorage.storeVault(vault, "Test Vault 1", asset);
        vaultStorage.storeVault(vault2, "Test Vault 2", asset);

        // Test active vaults
        VaultStorage.VaultInfo[] memory activeVaults = vaultStorage
            .getAllVaults();
        assertEq(activeVaults.length, 2);
        assertEq(activeVaults[0].vaultAddress, vault);
        assertEq(activeVaults[1].vaultAddress, vault2);
        assertTrue(activeVaults[0].active);
        assertTrue(activeVaults[1].active);

        // Remove one vault and verify list still contains both but one is inactive
        vaultStorage.removeVault(vault);
        VaultStorage.VaultInfo[] memory mixedVaults = vaultStorage
            .getAllVaults();
        assertEq(mixedVaults.length, 2);
        assertFalse(mixedVaults[0].active);
        assertTrue(mixedVaults[1].active);

        vm.stopPrank();
    }

    function test_VaultExists() public {
        vm.startPrank(admin);

        // Test zero address
        assertFalse(vaultStorage.vaultExists(address(0)));

        // Test non-existent vault
        assertFalse(vaultStorage.vaultExists(vault));

        // Store and test active vault
        vaultStorage.storeVault(vault, "Test Vault", asset);
        assertTrue(vaultStorage.vaultExists(vault));

        // Remove and test inactive vault
        vaultStorage.removeVault(vault);
        assertFalse(vaultStorage.vaultExists(vault));

        vm.stopPrank();
    }

    function test_RevertUnauthorizedStore() public {
        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vaultStorage.storeVault(vault, "Test Vault", asset);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedRemove() public {
        vm.startPrank(admin);
        vaultStorage.storeVault(vault, "Test Vault", asset);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vaultStorage.removeVault(vault);
        vm.stopPrank();
    }

    function test_RevertDuplicateVault() public {
        vm.startPrank(admin);

        vaultStorage.storeVault(vault, "Test Vault", asset);

        vm.expectRevert(VaultStorage.VaultAlreadyStored.selector);
        vaultStorage.storeVault(vault, "Duplicate Vault", asset);

        vm.stopPrank();
    }

    function test_RevertRemoveNonExistentVault() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultStorage.VaultNotStored.selector);
        vaultStorage.removeVault(address(0x123));

        vm.stopPrank();
    }

    function test_GetNonExistentVault() public {
        // Test zero address
        VaultStorage.VaultInfo memory zeroInfo = vaultStorage.getVault(
            address(0)
        );
        assertEq(zeroInfo.vaultAddress, address(0));
        assertFalse(zeroInfo.active);
        assertEq(zeroInfo.name, "");
        assertEq(zeroInfo.asset, address(0));
        assertEq(zeroInfo.deployedAt, 0);

        // Test random address
        VaultStorage.VaultInfo memory randomInfo = vaultStorage.getVault(
            address(0x123)
        );
        assertEq(randomInfo.vaultAddress, address(0));
        assertFalse(randomInfo.active);
        assertEq(randomInfo.name, "");
        assertEq(randomInfo.asset, address(0));
        assertEq(randomInfo.deployedAt, 0);
    }
}
