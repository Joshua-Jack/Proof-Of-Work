//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IModule} from "./IModule.sol";

struct Module {
    IModule module;
    bool active;
    bool isSingleProject;
}

///@notice VaultFees are represented in BPS
///@dev all downstream math needs to be / 10_000 because 10_000 bps == 100%
struct VaultFees {
    uint64 depositFee;
    uint64 withdrawalFee;
    uint64 protocolFee;
}

struct VaultInfo {
    IERC20 baseAsset;
    string symbol;
    string shareName;
    address owner;
    address feeRecipient;
    VaultFees fees;
    uint16 liquidityHoldBP;
    uint16 maxOwnerShareBP;
}

struct Epoch {
    uint256 id;
    uint256 amount;
    uint256 pendingRewards;
    mapping(address => bool) hasClaimed;
}

struct OwnerAllocation {
    uint256 totalAmount;
    uint256 releasedAmount;
    uint256 lastReleaseTime;
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
    event FeeRecipientSet(
        address indexed oldRecipient,
        address indexed newRecipient
    );

    function setVaultFees(VaultFees calldata newFees_) external;

    function addModule(
        Module memory newModule,
        bool replace,
        uint256 index
    ) external;

    function removeModule(uint256 index) external;

    function pause() external;

    function unpause() external;

    function setFeeRecipient(address newFeeRecipient) external;
}
