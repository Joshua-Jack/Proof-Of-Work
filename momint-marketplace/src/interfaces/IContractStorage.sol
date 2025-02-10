// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/// @title Contract Data Structure
/// @notice Defines the structure for storing contract information
struct ContractData {
    /// @notice The address of the contract
    address contractAddress;
    /// @notice Whether the contract requires initialization data
    bool initDataRequired;
}

/// @title IContractStorage Interface
/// @notice Interface for the ContractStorage contract
interface IContractStorage {
    /// @notice Adds a new contract to the registry
    /// @param id_ The unique identifier for the contract
    /// @param contract_ The contract data to add
    function addContract(bytes32 id_, ContractData memory contract_) external;

    /// @notice Removes a contract from the registry
    /// @param id_ The unique identifier for the contract to remove
    function removeContract(bytes32 id_) external;

    /// @notice Gets the contract data for a given ID
    /// @param id_ The unique identifier for the contract
    /// @return The contract data
    function getContract(
        bytes32 id_
    ) external view returns (ContractData memory);

    function getAllContracts() external view returns (address[] memory);
}
