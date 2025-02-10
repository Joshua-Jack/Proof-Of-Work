// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMomintFactory, ContractData} from "../interfaces/IMomintFactory.sol";

/// @title MomintFactory
/// @author Momint
/// @notice Factory contract for deploying minimal proxy vaults using EIP-1167
/// @dev Uses OpenZeppelin's Clones library for minimal proxy pattern implementation
///      and Ownable for access control. Each vault is deployed as a clone of a
///      pre-deployed implementation contract to minimize gas costs.
contract MomintFactory is Ownable, IMomintFactory {
    /// @notice Emitted when a new vault clone is successfully deployed
    /// @param contractAddress The address of the newly deployed contract clone
    event ContractDeployed(address indexed contractAddress);

    /// @notice Initializes the factory with an owner address
    /// @dev Sets up access control by initializing Ownable with the provided owner
    /// @param owner The address to be granted ownership rights
    constructor(address owner) Ownable(owner) {}

    /// @notice Creates a new vault clone with optional initialization
    /// @dev Uses deterministic deployment via CREATE2 to ensure predictable addresses
    /// @param implementation_ Struct containing implementation address and init requirements
    /// @param data_ Initialization calldata to be passed to the new vault (if required)
    /// @param salt_ Unique value to ensure unique deployment addresses
    /// @return newContract Address of the newly deployed contract clone
    /// @custom:security Only callable by owner
    /// @custom:throws VaultDeployInitFailed if initialization fails when required
    function deployContract(
        ContractData calldata implementation_,
        bytes calldata data_,
        bytes32 salt_
    ) external onlyOwner returns (address newContract) {
        newContract = Clones.cloneDeterministic(
            implementation_.contractAddress,
            salt_
        );
        emit ContractDeployed(newContract);
        if (implementation_.initDataRequired) {
            (bool success, ) = newContract.call(data_);
            if (!success) {
                revert("DeployInitFailed");
            }
        }
    }
}
