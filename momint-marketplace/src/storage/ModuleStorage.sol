//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IModuleStorage} from "../interfaces/IModuleStorage.sol";

contract ModuleStorage is Ownable, IModuleStorage {
    uint256 public maxModules = 1000;
    address[] public moduleList;
    uint256 public currentProjectId;

    mapping(address => bool) public moduleExists;
    mapping(bytes32 => address) public module;

    event ModuleStored(address indexed module, bytes32 indexed moduleId);
    event ModuleRemoved(address indexed module);

    error ModuleAlreadyStored();
    error ModuleNotStored();
    error InvalidAddress();
    error MaxModulesReached(uint256 maxModules);
    error ModuleDoesNotExist(bytes32 moduleId);

    /// @param owner_ The address of the contract owner.
    constructor(address owner_) Ownable(owner_) {}

    // slither-disable-next-line timestamp
    function storeModule(
        address module_,
        bytes32 moduleId_
    ) external onlyOwner {
        if (module_ == address(0)) revert InvalidAddress();
        if (moduleExists[module_]) revert ModuleAlreadyStored();
        emit ModuleStored(module_, moduleId_);

        moduleExists[module_] = true;
        module[moduleId_] = module_;
        moduleList.push(module_);
        if (moduleList.length > maxModules)
            revert MaxModulesReached(moduleList.length);
    }

    // slither-disable-next-line timestamp
    function removeModule(
        address module_,
        bytes32 moduleId_
    ) external onlyOwner {
        if (!moduleExists[module_]) revert ModuleNotStored();
        if (module[moduleId_] == address(0)) revert InvalidAddress();
        delete moduleExists[module_];
        delete module[moduleId_];
        emit ModuleRemoved(module_);
    }

    function getAllModules() external view returns (address[] memory) {
        return moduleList;
    }

    function getModule(bytes32 moduleId_) external view returns (address) {
        if (module[moduleId_] == address(0))
            revert ModuleDoesNotExist(moduleId_);
        return module[moduleId_];
    }
}
