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

    // slither-disable-next-line timestamp
    function storeVault(
        address vault,
        string memory name,
        address asset
    ) external onlyOwner {
        if (vaults[vault].vaultAddress != address(0))
            revert VaultAlreadyStored();

        if (vaults[vault].active) revert VaultAlreadyStored();

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

    // slither-disable-next-line timestamp
    function removeVault(address vault) external onlyOwner {
        if (vaults[vault].vaultAddress == address(0)) revert VaultNotStored();
        vaults[vault].active = false;
        emit VaultRemoved(vault);
    }

    function getAllVaults() external view returns (VaultInfo[] memory) {
        uint256 totalLength = vaultList.length;
        VaultInfo[] memory allVaults = new VaultInfo[](totalLength);
        for (uint i = 0; i < totalLength; i++) {
            allVaults[i] = vaults[vaultList[i]];
        }
        return allVaults;
    }

    function getActiveVaults() external view returns (address[] memory) {
        uint256 activeCount = 0;
        uint256 totalLength = vaultList.length;

        // First pass: count active vaults
        for (uint256 i = 0; i < totalLength; i++) {
            if (vaults[vaultList[i]].active) {
                activeCount++;
            }
        }

        // Create array with exact size needed
        address[] memory activeVaults = new address[](activeCount);
        uint256 currentIndex = 0;

        // Second pass: populate array
        for (uint256 i = 0; i < totalLength; i++) {
            if (vaults[vaultList[i]].active) {
                activeVaults[currentIndex] = vaultList[i];
                currentIndex++;
            }
        }

        return activeVaults;
    }

    function getVault(address vault) external view returns (VaultInfo memory) {
        return vaults[vault];
    }

    function vaultExists(address vault) external view returns (bool) {
        return vaults[vault].active;
    }
}
