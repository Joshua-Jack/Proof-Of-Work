//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultStorage is Ownable {
    struct VaultInfo {
        address vaultAddress;
        string name;
        address asset;
        bool active;
        uint256 deployedAt;
    }

    mapping(address => VaultInfo) public vaults;
    address[] public vaultList;

    event VaultStored(address indexed vault, string name, address asset);
    event VaultRemoved(address indexed vault);

    error VaultAlreadyStored();
    error VaultNotStored();

    constructor(address owner_) Ownable(owner_) {}

    function storeVault(
        address vault,
        string memory name,
        address asset
    ) external {
        if (vaults[vault].vaultAddress != address(0))
            revert VaultAlreadyStored();

        vaults[vault] = VaultInfo({
            vaultAddress: vault,
            name: name,
            asset: asset,
            active: true,
            deployedAt: block.timestamp
        });
        vaultList.push(vault);

        emit VaultStored(vault, name, asset);
    }

    function removeVault(address vault) external {
        if (vaults[vault].vaultAddress == address(0)) revert VaultNotStored();
        vaults[vault].active = false;
        emit VaultRemoved(vault);
    }

    function getAllVaults() external view returns (VaultInfo[] memory) {
        VaultInfo[] memory allVaults = new VaultInfo[](vaultList.length);
        for (uint i = 0; i < vaultList.length; i++) {
            allVaults[i] = vaults[vaultList[i]];
        }
        return allVaults;
    }

    function getActiveVaults() external view returns (VaultInfo[] memory) {
        uint256 activeCount = 0;
        for (uint i = 0; i < vaultList.length; i++) {
            if (vaults[vaultList[i]].active) activeCount++;
        }

        VaultInfo[] memory activeVaults = new VaultInfo[](activeCount);
        uint256 index = 0;
        for (uint i = 0; i < vaultList.length; i++) {
            if (vaults[vaultList[i]].active) {
                activeVaults[index] = vaults[vaultList[i]];
                index++;
            }
        }
        return activeVaults;
    }

    function getVault(address vault) external view returns (VaultInfo memory) {
        return vaults[vault];
    }
}
