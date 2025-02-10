// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultStorage {
    struct VaultInfo {
        address vaultAddress;
        string name;
        address asset;
        bool active;
        uint256 deployedAt;
    }

    function storeVault(address vault_, bytes32 vaultId_) external;

    function removeVault(address vault_, bytes32 vaultId_) external;

    function getAllVaults() external view returns (address[] memory);

    function getVault(bytes32 vaultId_) external view returns (address);
}
