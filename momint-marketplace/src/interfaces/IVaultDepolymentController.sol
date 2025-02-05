//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// import {ImplData} from "./IImpl.sol";

interface IVaultDepolymentController {
    function removeImplementation(bytes32 id_) external;

    function deployNewVault(
        bytes32 id_,
        bytes calldata data_
    ) external returns (address);

    function removeVault(address vault_, bytes32 vaultId_) external;
}
