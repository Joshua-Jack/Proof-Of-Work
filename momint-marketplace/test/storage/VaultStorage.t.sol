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
    bytes32 public vaultId = keccak256("TEST_VAULT");

    event VaultStored(address indexed vault, bytes32 vaultId);
    event VaultRemoved(address indexed vault);

    function setUp() public {
        vaultStorage = new VaultStorage(admin);
    }

    function test_StoreVault() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, true, true);
        emit VaultStored(vault, vaultId);

        vaultStorage.storeVault(vault, vaultId);

        assertTrue(vaultStorage.vaultExists(vault));
        assertEq(vaultStorage.vault(vaultId), vault);
        assertEq(vaultStorage.getAllVaults()[0], vault);

        vm.stopPrank();
    }

    function test_RemoveVault() public {
        vm.startPrank(admin);

        vaultStorage.storeVault(vault, vaultId);

        vm.expectEmit(true, false, false, false);
        emit VaultRemoved(vault);

        vaultStorage.removeVault(vault, vaultId);

        assertFalse(vaultStorage.vaultExists(vault));
        assertEq(vaultStorage.vault(vaultId), address(0));

        vm.stopPrank();
    }

    function test_GetAllVaults() public {
        vm.startPrank(admin);

        // Test empty list first
        address[] memory emptyVaults = vaultStorage.getAllVaults();
        assertEq(emptyVaults.length, 0);

        // Store multiple vaults
        address vault2 = address(0x4);
        bytes32 vaultId2 = keccak256("TEST_VAULT_2");
        vaultStorage.storeVault(vault, vaultId);
        vaultStorage.storeVault(vault2, vaultId2);

        // Test stored vaults
        address[] memory vaults = vaultStorage.getAllVaults();
        assertEq(vaults.length, 2);
        assertEq(vaults[0], vault);
        assertEq(vaults[1], vault2);

        vm.stopPrank();
    }

    function test_GetVault() public {
        vm.startPrank(admin);

        vaultStorage.storeVault(vault, vaultId);

        address retrievedVault = vaultStorage.getVault(vaultId);
        assertEq(retrievedVault, vault);

        vm.stopPrank();
    }

    function test_MaxVaults() public {
        vm.startPrank(admin);

        // Store up to max vaults
        for (uint256 i = 0; i < vaultStorage.maxVaults(); i++) {
            address newVault = address(uint160(i + 1));
            bytes32 newVaultId = keccak256(abi.encodePacked(i));
            vaultStorage.storeVault(newVault, newVaultId);
        }

        // Try to store one more
        vm.expectRevert(
            abi.encodeWithSelector(VaultStorage.MaxVaultsReached.selector, 1001)
        );
        vaultStorage.storeVault(address(0x999), keccak256("OVERFLOW"));

        vm.stopPrank();
    }

    function test_RevertUnauthorizedStore() public {
        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vaultStorage.storeVault(vault, vaultId);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedRemove() public {
        vm.startPrank(admin);
        vaultStorage.storeVault(vault, vaultId);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vaultStorage.removeVault(vault, vaultId);
        vm.stopPrank();
    }

    function test_RevertDuplicateVault() public {
        vm.startPrank(admin);

        vaultStorage.storeVault(vault, vaultId);

        vm.expectRevert(VaultStorage.VaultAlreadyStored.selector);
        vaultStorage.storeVault(vault, vaultId);

        vm.stopPrank();
    }

    function test_RevertRemoveNonExistentVault() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultStorage.VaultNotStored.selector);
        vaultStorage.removeVault(address(0x123), vaultId);

        vm.stopPrank();
    }

    function test_RevertInvalidAddress() public {
        vm.startPrank(admin);

        vm.expectRevert(VaultStorage.InvalidAddress.selector);
        vaultStorage.storeVault(address(0), vaultId);

        vm.stopPrank();
    }

    function test_RevertVaultDoesNotExist() public {
        vm.startPrank(admin);

        bytes32 nonExistentId = keccak256("NON_EXISTENT");
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultStorage.VaultDoesNotExist.selector,
                nonExistentId
            )
        );
        vaultStorage.getVault(nonExistentId);

        vm.stopPrank();
    }
}
