// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MomintFactory
/// @notice Factory for deploying both vaults and modules with clone or direct deployment options
contract MomintFactory is Ownable {
    /// @notice Deployment types
    enum DeploymentType {
        CLONE,
        DIRECT
    }

    /// @notice Deployment configuration
    struct DeployConfig {
        address implementation;
        bytes initData;
        bytes32 salt;
        DeploymentType deployType;
        bytes creationCode; // Added for direct deployment
    }

    event ContractDeployed(
        address indexed newContract,
        DeploymentType deployType,
        bytes32 salt
    );

    error DeploymentFailed();
    error InvalidImplementation();
    error InvalidParameters();

    constructor(address owner_) Ownable(owner_) {}

    /// @notice Deploys a new contract using either cloning or direct deployment
    /// @param config The deployment configuration
    /// @return newContract The address of the newly deployed contract
    function deploy(
        DeployConfig calldata config
    ) external onlyOwner returns (address newContract) {
        if (config.implementation == address(0)) revert InvalidImplementation();
        emit ContractDeployed(newContract, config.deployType, config.salt);

        if (config.deployType == DeploymentType.CLONE) {
            newContract = _deployClone(
                config.implementation,
                config.initData,
                config.salt
            );
        } else {
            newContract = _deployDirect(
                config.creationCode,
                config.initData,
                config.salt
            );
        }

        return newContract;
    }

    /// @notice Deploys a contract using cloning
    function _deployClone(
        address implementation,
        bytes memory initData,
        bytes32 salt
    ) internal returns (address newContract) {
        if (implementation == address(0)) revert InvalidImplementation();
        if (salt == bytes32(0)) revert InvalidParameters();
        if (initData.length == 0) revert InvalidParameters();
        newContract = Clones.cloneDeterministic(implementation, salt);

        if (initData.length > 0) {
            // slither-disable-next-line missing-zero-check
            (bool success, ) = newContract.call(initData);
            if (!success) revert DeploymentFailed();
        }

        return newContract;
    }

    /// @notice Deploys a contract directly using CREATE2
    function _deployDirect(
        bytes memory creationCode,
        bytes memory constructorArgs,
        bytes32 salt
    ) internal returns (address deployed) {
        if (creationCode.length == 0) revert InvalidParameters();
        if (constructorArgs.length == 0) revert InvalidParameters();
        if (salt == bytes32(0)) revert InvalidParameters();
        // Use abi.encode instead of abi.encodePacked for safer encoding
        bytes memory bytecode = abi.encode(creationCode, constructorArgs);

        assembly {
            deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        require(deployed != address(0), "Failed to deploy contract");
        return deployed;
    }

    /// @notice Predicts the address where a contract will be deployed
    function predictDeploymentAddress(
        bytes32 salt,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) public view returns (address) {
        if (creationCode.length == 0) revert InvalidParameters();
        if (constructorArgs.length == 0) revert InvalidParameters();
        if (salt == bytes32(0)) revert InvalidParameters();
        // Use abi.encode instead of abi.encodePacked for safer encoding
        bytes memory bytecode = abi.encode(creationCode, constructorArgs);

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
