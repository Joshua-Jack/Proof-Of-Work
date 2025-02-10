// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleStorage {
    struct ModuleInfo {
        address moduleAddress;
        uint256 projectId;
        string name;
        address vault;
        bool active;
        uint256 deployedAt;
    }

    function storeModule(address module, bytes32 moduleId_) external;

    function removeModule(address module, bytes32 moduleId_) external;

    function getAllModules() external view returns (address[] memory);

    function getModule(bytes32 moduleId_) external view returns (address);
}
