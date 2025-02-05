//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IModule} from "./IModule.sol";

struct Module {
    IModule module;
    bool active;
    bool isSingleProject;
}

struct Allocation {
    uint256 index;
    uint256 amount; // Represented in BPS of the amount of ETF that should go into strategy
}

///@notice VaultFees are represented in BPS
///@dev all downstream math needs to be / 10_000 because 10_000 bps == 100%
struct VaultFees {
    uint64 depositFee;
    uint64 withdrawalFee;
    uint64 protocolFee;
}

interface IMomintVault {
    struct UserReturns {
        uint256 index;
        uint256 claimedReturns;
    }

    event FeeRecipientUpdated(
        address indexed oldRecipient,
        address indexed newRecipient
    );
    event ToggleVaultIdle(bool pastValue, bool newValue);
    event ModuleAdded(address newModule);
    event ModuleRemoved(address oldModule);
    event DepositLimitSet(uint256 limit);
    event ModuleAllocationsChanged(Allocation[] newAllocations);
    event WithdrawalQueueUpdated(address oldQueue, address newQueue);
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 projectId
    );
    event FeeCollected(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);

    function setVaultFees(VaultFees calldata newFees_) external;

    function addModule(
        Module memory newModule,
        bool isSingleProject,
        uint256 projectId
    ) external;
}
