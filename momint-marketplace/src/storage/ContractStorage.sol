// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContractData} from "../interfaces/IContractStorage.sol";
import {IContractStorage} from "../interfaces/IContractStorage.sol";

/// @title Contract Storage
/// @notice Manages the registration and removal of contracts.
/// @dev Inherits from Ownable for access control and utilizes Errors for custom error handling.
contract ContractStorage is Ownable, IContractStorage {
    /// @notice Mapping of contract ID to its data.
    /// @dev The ID is a bytes32 hash derived from encoding the name and version of the contract.
    mapping(bytes32 => ContractData) private _contracts;

    /// @notice Mapping to track if a contract ID exists.
    mapping(bytes32 => bool) public contractExists;

    /// @notice Array to keep track of all contract addresses added.
    address[] public allContracts;

    /// @notice Event emitted when a new contract is added.
    event ContractAdded(bytes32 indexed id, ContractData contract_);

    event ContractRemoved(bytes32 indexed id, ContractData contract_);

    error ContractAlreadyExists(bytes32 id_);
    error ContractDoesNotExist(bytes32 id_);
    error ContractAlreadyRemoved(bytes32 id_);

    /// @param owner_ The address of the contract owner.
    constructor(address owner_) Ownable(owner_) {}

    /// @notice Adds a new contract to the registry.
    /// @param id_ The unique identifier for the contract.
    /// @param contract_ The contract data including the address and whether initialization data is required.
    /// @dev Emits a ContractAdded event upon success.
    function addContract(
        bytes32 id_,
        ContractData memory contract_
    ) external onlyOwner {
        if (contractExists[id_]) {
            revert ContractAlreadyExists(id_);
        }

        _contracts[id_] = contract_;
        contractExists[id_] = true;
        allContracts.push(contract_.contractAddress);

        emit ContractAdded(id_, contract_);
    }

    /// @notice Removes a contract from the registry.
    /// @param id_ The unique identifier for the contract to remove.
    /// @dev Sets the contract data to a default value and removes it from the tracking array.
    function removeContract(bytes32 id_) external onlyOwner {
        if (!contractExists[id_]) {
            revert ContractDoesNotExist(id_);
        }
        address contractAddress = _contracts[id_].contractAddress;
        emit ContractRemoved(id_, _contracts[id_]);
        delete _contracts[id_];
        contractExists[id_] = false;

        uint256 indexToBeRemoved = 0;
        uint256 len = allContracts.length;
        for (uint256 i = 0; i < len; ) {
            if (allContracts[i] == contractAddress) {
                indexToBeRemoved = i;
                break;
            }
            unchecked {
                i++;
            }
        }

        allContracts[indexToBeRemoved] = allContracts[len - 1];
        allContracts.pop();
    }

    /// @notice Retrieves the contract data for a given ID.
    /// @param id_ The unique identifier for the contract.
    /// @return The contract data.
    function getContract(
        bytes32 id_
    ) external view returns (ContractData memory) {
        return _contracts[id_];
    }
}
