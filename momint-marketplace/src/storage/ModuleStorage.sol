//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ModuleStorage is Ownable {
    struct ModuleInfo {
        address moduleAddress;
        uint256 projectId;
        string name;
        address vault;
        bool active;
        uint256 deployedAt;
    }

    mapping(address => ModuleInfo) public modules;
    mapping(address => address[]) public vaultModules; // vault -> modules
    address[] public moduleList;
    uint256 public currentProjectId;
    event ModuleStored(
        address indexed module,
        uint256 projectId,
        string name,
        address vault
    );
    event ModuleRemoved(address indexed module);

    error ModuleAlreadyStored();
    error ModuleNotStored();

    /// @param owner_ The address of the contract owner.
    constructor(address owner_) Ownable(owner_) {}

    // slither-disable-next-line timestamp
    function storeModule(
        address module,
        string memory name,
        address vault
    ) external onlyOwner {
        if (modules[module].moduleAddress != address(0))
            revert ModuleAlreadyStored();

        currentProjectId++; // Increment the counter

        modules[module] = ModuleInfo({
            moduleAddress: module,
            projectId: currentProjectId, // Use the counter
            name: name,
            vault: vault,
            active: true,
            deployedAt: block.timestamp
        });
        moduleList.push(module);
        vaultModules[vault].push(module);

        emit ModuleStored(module, currentProjectId, name, vault);
    }

    // slither-disable-next-line timestamp
    function removeModule(address module) external onlyOwner {
        if (modules[module].moduleAddress == address(0))
            revert ModuleNotStored();
        modules[module].active = false;
        emit ModuleRemoved(module);
    }

    function getAllModules() external view returns (ModuleInfo[] memory) {
        uint256 totalLength = moduleList.length;
        ModuleInfo[] memory allModules = new ModuleInfo[](totalLength);
        for (uint i = 0; i < totalLength; i++) {
            allModules[i] = modules[moduleList[i]];
        }
        return allModules;
    }

    function getModule(
        address module
    ) external view returns (ModuleInfo memory) {
        return modules[module];
    }

    function getVaultModules(
        address vault
    ) external view returns (ModuleInfo[] memory) {
        address[] memory vaultModuleList = vaultModules[vault];
        ModuleInfo[] memory moduleInfos = new ModuleInfo[](
            vaultModuleList.length
        );
        for (uint i = 0; i < vaultModuleList.length; i++) {
            moduleInfos[i] = modules[vaultModuleList[i]];
        }
        return moduleInfos;
    }
}
