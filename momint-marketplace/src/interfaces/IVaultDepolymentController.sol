//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {ImplData} from "./IImpl.sol";

interface IVaultDepolymentController {
    function addImplementation(
        bytes32 id_,
        ImplData calldata implementation_
    ) external;

    function removeImplementation(bytes32 id_) external;

    function deployNewVault(
        bytes32 id_,
        bytes calldata data_
    ) external returns (address);

    function removeVault(address vault_, bytes32 vaultId_) external;
}
