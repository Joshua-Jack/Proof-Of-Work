//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

contract VaultStorage is Ownable, IVaultStorage {
    uint256 public maxVaults = 1000;

    mapping(address => bool) public vaultExists;
    mapping(bytes32 => address) public vault;
    address[] public vaultList;

    event VaultStored(address indexed vault, bytes32 vaultId);
    event VaultRemoved(address indexed vault);

    error VaultAlreadyStored();
    error VaultNotStored();
    error InvalidAddress();
    error MaxVaultsReached(uint256 maxVaults);
    error VaultDoesNotExist(bytes32 vaultId);

    constructor(address owner_) Ownable(owner_) {}

    // slither-disable-next-line timestamp
    function storeVault(address vault_, bytes32 vaultId_) external onlyOwner {
        if (vault_ == address(0)) revert InvalidAddress();
        if (vaultExists[vault_]) revert VaultAlreadyStored();
        emit VaultStored(vault_, vaultId_);

        vaultExists[vault_] = true;
        vault[vaultId_] = vault_;
        vaultList.push(vault_);
        if (vaultList.length > maxVaults)
            revert MaxVaultsReached(vaultList.length);
    }

    // slither-disable-next-line timestamp
    function removeVault(address vault_, bytes32 vaultId_) external onlyOwner {
        if (vaultExists[vault_] == false) revert VaultNotStored();
        if (vault[vaultId_] == address(0)) revert InvalidAddress();
        delete vaultExists[vault_];
        delete vault[vaultId_];
        emit VaultRemoved(vault_);
    }

    function getAllVaults() external view returns (address[] memory) {
        return vaultList;
    }

    function getVault(bytes32 vaultId_) external view returns (address) {
        if (vault[vaultId_] == address(0)) revert VaultDoesNotExist(vaultId_);
        return vault[vaultId_];
    }
}
