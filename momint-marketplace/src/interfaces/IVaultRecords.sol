//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IVaultRecords {
    function addVault(address vault_, bytes32 vaultId_) external;

    function removeVault(address vault_, bytes32 vaultId_) external;

    function getAllVaults() external view returns (address[] memory);

    function getVaultsByImplId(
        bytes32 id_
    ) external view returns (address[] memory);

    function getVaultsByToken(
        address asset
    ) external view returns (address[] memory);
}
