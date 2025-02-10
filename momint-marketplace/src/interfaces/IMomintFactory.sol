//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {ContractData} from "./IContractStorage.sol";

interface IMomintFactory {
    function deployContract(
        ContractData calldata contractData,
        bytes calldata data_,
        bytes32 salt_
    ) external returns (address);
}
