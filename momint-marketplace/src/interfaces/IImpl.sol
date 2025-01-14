//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

struct ImplData {
    address implementationAddress;
    bool initDataRequired;
}

interface IImplRecords {
    function addImpl(bytes32 id_, ImplData calldata implementation_) external;

    function getImpl(bytes32 id_) external view returns (ImplData memory);

    function removeImpl(bytes32 id_) external;
}
