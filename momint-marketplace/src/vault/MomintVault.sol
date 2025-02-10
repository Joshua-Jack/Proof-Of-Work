//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626Upgradeable, IERC20, IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IModule} from "../interfaces/IModule.sol";
import {VaultHelper} from "../libraries/VaultHelper.sol";
import {IMomintVault, Module, VaultFees, OwnerAllocation, Epoch, InitParams} from "../interfaces/IMomintVault.sol";
import {MAX_BASIS_POINTS} from "../utils/Constants.sol";
import {console} from "forge-std/console.sol";

contract MomintVault is
    ERC4626Upgradeable,
    ReentrancyGuard,
    PausableUpgradeable,
    OwnableUpgradeable,
    IMomintVault
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Errors ============
    error InvalidIndex(uint256 index);
    error InsufficientReturns();
    error NoReturnsAvailable();
    error InvalidFeeRecipient();
    error InvalidAssetAddress();
    error AssetMismatch();
    error ModuleRemovalFailed();
    error CannotRemoveLastModule();
    error InvalidModuleAddress();
    error InvalidAmount();
    error InvalidReceiver();
    error NoActiveModules();
    error ZeroAmount();
    error InsufficientBalance();
    error WithdrawalTooSmall();
    error DistributionTooSmall();
    error InvalidEpochId();
    error AlreadyClaimed();
    error NoSharesOwned();
    error InvalidModuleIndex();
    error TransferFailed();
    // ============ Constants ============
    uint32 private constant DUST = 1e4;
    uint256 private constant PRECISION = 1e36;
    uint256 public constant BUFFER_THRESHOLD_BP = 1500; // 15% buffer threshold
    uint16 public constant ABSOLUTE_MIN_LIQUIDITY_BP = 1000; // 10% absolute minimum
    uint16 public constant ABSOLUTE_MAX_OWNER_BP = 9000; // 90% absolute maximum
    uint8 public constant decimalOffset = 9;
    uint256 public constant RELEASE_PERIOD = 7 days;
    uint256 public constant RELEASE_PORTIONS = 4; // Release over 4 weeks
    uint256 public constant liquidityBuffer = 1000;

    // ============ State Variables ============
    uint8 private _decimals;
    uint256 public feesUpdatedAt;
    address public feeRecipient;
    address private vaultTokenAddress;
    uint256 public currentEpochId;
    uint16 public minLiquidityHoldBP;
    uint16 public maxOwnerShareBP;
    uint256 public totalDistributedReturns;

    // ============ Data Structures ============
    Module[] public modules;
    IModule public module;
    VaultFees private fees;
    mapping(address => OwnerAllocation) public ownerAllocations;
    mapping(address => uint256) public totalReturnsClaimed;
    mapping(address => uint256) public pendingReturns;
    mapping(address => UserReturns) public userReturns;
    mapping(uint256 => Epoch) public epochs;

    // ============ Events ============
    event LiquidityRatiosUpdated(
        uint16 minLiquidityHoldBP,
        uint16 maxOwnerShareBP
    );
    event Initialized(
        address indexed vaultName,
        address indexed underlyingAsset
    );
    event ReturnsDistributed(uint256 amount, uint256 epochId);
    event ReturnsClaimed(
        address indexed user,
        uint256 moduleIndex,
        uint256 epochId,
        uint256 amount
    );
    event TokenDeposited(address token, uint256 amount, address user);
    event ClaimedReturns(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SharesMinted(address indexed user, uint256 shares, uint256 assets);
    event Withdraw(
        address indexed user,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );
    event ModuleAdded(
        address indexed module,
        bool isSingleProject,
        uint256 indexed index
    );

    constructor() {
        _disableInitializers();
    }

    // ============ Initialization & Core Functions ============
    function initialize(
        InitParams calldata params
    ) external initializer nonReentrant {
        _validateInitParams(params);
        _initializeCore(params);
        emit Initialized(address(this), address(params.baseAsset));
    }

    function _validateInitParams(InitParams calldata params) internal pure {
        if (address(params.baseAsset) == address(0))
            revert InvalidAssetAddress();
        if (params.feeRecipient == address(0)) revert InvalidFeeRecipient();

        require(
            params.liquidityHoldBP >= ABSOLUTE_MIN_LIQUIDITY_BP,
            "Liquidity ratio too low"
        );
        require(
            params.maxOwnerShareBP <= ABSOLUTE_MAX_OWNER_BP,
            "Owner share too high"
        );
        require(
            params.liquidityHoldBP + params.maxOwnerShareBP <= MAX_BASIS_POINTS,
            "Invalid ratio configuration"
        );
    }

    function _initializeCore(InitParams calldata params) internal {
        __ERC4626_init(params.baseAsset);
        __Ownable_init(params.owner);
        __ERC20_init(params.shareName, params.symbol);
        __Pausable_init();
        module = IModule(address(0));
        vaultTokenAddress = address(params.baseAsset);
        (_decimals) = VaultHelper.validateVaultParameters(
            params.baseAsset,
            decimalOffset,
            params.fees,
            fees
        );

        feeRecipient = params.feeRecipient;
        minLiquidityHoldBP = params.liquidityHoldBP;
        maxOwnerShareBP = params.maxOwnerShareBP;
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        emit FeeRecipientSet(feeRecipient, newFeeRecipient);
        feeRecipient = newFeeRecipient;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ============ Deposit Functions ============
    function deposit(
        uint256 assets_,
        uint256 index_
    ) external returns (uint256) {
        return deposit(assets_, msg.sender, index_);
    }

    function deposit(
        uint256 assets,
        address receiver,
        uint256 index_
    ) public nonReentrant whenNotPaused returns (uint256 shares) {
        _validateDepositParams(assets, receiver, index_);

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Calculate and take out fees
        uint256 netAmount = _handleFees(assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        // Process the deposit with the full net amount
        shares = _processDeposit(netAmount, receiver, index_);

        return shares;
    }

    function _handleFees(uint256 assets) internal returns (uint256) {
        uint256 feeAmount = assets.mulDiv(
            uint256(fees.depositFee),
            MAX_BASIS_POINTS,
            Math.Rounding.Floor
        );

        if (feeAmount > 0) {
            require(
                IERC20(asset()).balanceOf(address(this)) >= feeAmount,
                "Insufficient balance for fee"
            );
            IERC20(asset()).safeTransfer(feeRecipient, feeAmount);
        }

        return assets - feeAmount;
    }

    // The _processDeposit function is calling trusted code from the module.
    // slither-disable-next-line reentrancy-events, reentrancy-benign, reentrancy-vulnerabilities
    function _processDeposit(
        uint256 amount,
        address receiver,
        uint256 index_
    ) internal returns (uint256) {
        Module storage activeModule = modules[index_];

        if (!activeModule.active) {
            activeModule.active = true;
        }

        uint256 preBalance = IERC20(asset()).balanceOf(address(this));

        // Invest the full amount
        (uint256 shares, uint256 refund) = activeModule.module.invest(
            amount,
            receiver
        );
        // Verify state changes
        require(
            IERC20(asset()).balanceOf(address(this)) >= preBalance - refund,
            "Invalid balance change"
        );

        // Calculate liquidity split after successful investment
        uint256 actualInvestment = amount - refund;
        uint256 liquidityPortion = (actualInvestment * minLiquidityHoldBP) /
            MAX_BASIS_POINTS;
        uint256 ownerPortion = actualInvestment - liquidityPortion;

        address projectOwner = activeModule.module.getProjectInfo().owner;

        // Handle refund if any
        if (refund > 0) {
            emit Refund(msg.sender, refund);
            IERC20(asset()).safeTransfer(msg.sender, refund);
        }

        _mint(receiver, shares);

        _allocationToOwner(projectOwner, ownerPortion);

        return shares;
    }

    function _validateDepositParams(
        uint256 assets,
        address receiver,
        uint256 index_
    ) internal view {
        if (assets == 0) revert InvalidAmount();
        if (receiver == address(0)) revert InvalidReceiver();
        if (modules.length == 0) revert NoActiveModules();

        Module storage activeModule = modules[index_];
        if (!activeModule.active) revert NoActiveModules();
    }

    // ============ Withdrawal Functions ============
    function withdraw(
        uint256 shares,
        uint256 index_
    ) external returns (uint256) {
        return withdraw(shares, msg.sender, index_);
    }

    function withdraw(
        uint256 shares,
        address receiver,
        uint256 index_
    ) public nonReentrant whenNotPaused returns (uint256 assets) {
        if (shares == 0) revert InvalidAmount();
        if (receiver == address(0)) revert InvalidReceiver();
        if (modules.length == 0) revert NoActiveModules();
        if (balanceOf(msg.sender) < shares) revert InsufficientBalance();

        Module storage activeModule = modules[index_];
        if (!activeModule.active) revert NoActiveModules();

        // Get divestment amount first to check liquidity
        uint256 divestAmount = activeModule.module.divest(shares, msg.sender);
        if (divestAmount == 0) revert InvalidAmount();
        if (divestAmount <= DUST) revert WithdrawalTooSmall();

        uint256 withdrawalFee = divestAmount.mulDiv(
            uint256(fees.withdrawalFee),
            MAX_BASIS_POINTS,
            Math.Rounding.Floor
        );

        uint256 netAssets = divestAmount - withdrawalFee;

        // Check liquidity before proceeding with transfers
        if (!_checkLiquidity(netAssets)) {
            revert("Insufficient liquidity");
        }

        _burn(msg.sender, shares);

        if (withdrawalFee > 0) {
            IERC20(asset()).safeTransfer(feeRecipient, withdrawalFee);
        }

        IERC20(asset()).safeTransfer(receiver, netAssets);

        emit Withdraw(msg.sender, receiver, netAssets, shares);
        return netAssets;
    }

    // ============ Liquidity Management Functions ============
    function updateLiquidityRatios(
        uint16 newMinLiquidityBP_,
        uint16 newMaxOwnerBP_
    ) external onlyOwner {
        require(
            newMinLiquidityBP_ >= ABSOLUTE_MIN_LIQUIDITY_BP,
            "Liquidity ratio too low"
        );
        require(
            newMaxOwnerBP_ <= ABSOLUTE_MAX_OWNER_BP,
            "Owner share too high"
        );
        require(
            newMinLiquidityBP_ + newMaxOwnerBP_ <= MAX_BASIS_POINTS,
            "Invalid ratio configuration"
        );

        if (totalAssets() > 0) {
            require(
                newMinLiquidityBP_ >= minLiquidityHoldBP,
                "Cannot decrease liquidity ratio with active deposits"
            );
        }

        minLiquidityHoldBP = newMinLiquidityBP_;
        maxOwnerShareBP = newMaxOwnerBP_;

        emit LiquidityRatiosUpdated(newMinLiquidityBP_, newMaxOwnerBP_);
    }

    // slither-disable-next-line timestamp
    function _checkLiquidity(
        uint256 withdrawalAmount
    ) internal view returns (bool) {
        uint256 availableLiquidity = IERC20(asset()).balanceOf(address(this));
        uint256 bufferRequired = (totalAssets() * liquidityBuffer) /
            MAX_BASIS_POINTS;
        return availableLiquidity >= (withdrawalAmount + bufferRequired);
    }

    function _allocationToOwner(address projectOwner, uint256 amount) internal {
        OwnerAllocation storage allocation = ownerAllocations[projectOwner];
        allocation.totalAmount += amount;
        allocation.lastReleaseTime = block.timestamp;
    }

    // ============ Returns Distribution Functions ============
    function distributeReturns(
        uint256 amount,
        uint256 index_
    ) external nonReentrant onlyOwner {
        if (amount == 0) revert InvalidAmount();
        uint256 minUserShares = 1;
        uint256 totalShares = modules[index_].module.getTotalShares();
        uint256 minUserShare = (amount * minUserShares) / totalShares;

        if (minUserShare <= DUST) {
            revert DistributionTooSmall();
        }

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

        uint256 epochId = ++currentEpochId;
        Epoch storage newEpoch = epochs[epochId];
        newEpoch.id = epochId;
        newEpoch.amount = amount;
        newEpoch.pendingRewards = amount;

        totalDistributedReturns += amount;

        emit ReturnsDistributed(amount, epochId);
    }

    function claimReturns(
        uint256 moduleIndex,
        uint256 epochId
    ) external nonReentrant returns (uint256) {
        if (moduleIndex >= modules.length) revert InvalidModuleIndex();
        if (epochId == 0 || epochId > currentEpochId) revert InvalidEpochId();

        Epoch storage epoch = epochs[epochId];
        if (epoch.hasClaimed[msg.sender]) revert AlreadyClaimed();

        Module storage modulesP = modules[moduleIndex];
        uint256 userShares = modulesP.module.getUserShares(msg.sender);
        if (userShares == 0) revert NoSharesOwned();

        uint256 totalShares = modulesP.module.getTotalShares();
        uint256 userShare = (epoch.amount * userShares) / totalShares;

        if (userShare <= DUST) revert NoReturnsAvailable();

        epoch.hasClaimed[msg.sender] = true;
        epoch.pendingRewards -= userShare;

        IERC20(asset()).safeTransfer(msg.sender, userShare);

        emit ReturnsClaimed(msg.sender, moduleIndex, epochId, userShare);
        return userShare;
    }

    // slither-disable-next-line timestamp
    function claimOwnerAllocation() external {
        OwnerAllocation storage allocation = ownerAllocations[msg.sender];
        require(
            allocation.totalAmount > allocation.releasedAmount,
            "Nothing to claim"
        );

        uint256 elapsedTime = block.timestamp - allocation.lastReleaseTime;

        // Fix division before multiplication by combining the calculations
        uint256 releaseAmount = Math.mulDiv(
            Math.mulDiv(
                allocation.totalAmount * elapsedTime,
                1,
                RELEASE_PERIOD * RELEASE_PORTIONS,
                Math.Rounding.Floor
            ),
            1,
            1,
            Math.Rounding.Floor
        );

        releaseAmount = Math.min(
            releaseAmount,
            allocation.totalAmount - allocation.releasedAmount
        );

        require(_checkLiquidity(releaseAmount), "Insufficient liquidity");

        allocation.releasedAmount += releaseAmount;
        allocation.lastReleaseTime = block.timestamp;

        IERC20(asset()).safeTransfer(msg.sender, releaseAmount);
    }

    // ============ Module Management Functions ============
    function addModule(
        Module calldata newModule_,
        bool replace_,
        uint256 index_
    ) external nonReentrant onlyOwner {
        if (address(newModule_.module) == address(0))
            revert InvalidModuleAddress();
        if (replace_ && index_ >= modules.length) revert InvalidIndex(index_);

        IModule newModule;
        IModule removedModule;

        (newModule, removedModule) = VaultHelper.addOrReplaceModule(
            modules,
            newModule_,
            replace_,
            index_
        );

        if (address(removedModule) != address(0)) {
            emit ModuleRemoved(address(removedModule));
        }
        emit ModuleAdded(
            address(newModule),
            newModule_.isSingleProject,
            replace_ ? index_ : modules.length - 1
        );
    }

    function removeModule(uint256 index_) external nonReentrant onlyOwner {
        uint256 len = modules.length;
        if (index_ >= len) revert InvalidIndex(index_);

        IModule moduleToBeRemoved = modules[index_].module;
        modules[index_].active = false;

        if (index_ != len - 1) {
            modules[index_] = modules[len - 1];
        }
        modules.pop();

        emit ModuleRemoved(address(moduleToBeRemoved));
    }

    // ============ View Functions ============
    function getModule(uint256 index_) external view returns (Module memory) {
        if (index_ >= modules.length) revert InvalidIndex(index_);
        return modules[index_];
    }

    function getModulesLength() external view returns (uint256) {
        return modules.length;
    }

    function getModules() external view returns (Module[] memory) {
        return modules;
    }

    function getVaultFees() public view returns (VaultFees memory) {
        return fees;
    }

    function getLiquidityRatios()
        external
        view
        returns (
            uint16 currentMinLiquidity,
            uint16 currentMaxOwner,
            uint16 absoluteMinLiquidity,
            uint16 absoluteMaxOwner
        )
    {
        return (
            minLiquidityHoldBP,
            maxOwnerShareBP,
            ABSOLUTE_MIN_LIQUIDITY_BP,
            ABSOLUTE_MAX_OWNER_BP
        );
    }

    function getClaimableReturns(
        address user,
        uint256 moduleIndex,
        uint256 epochId
    ) external view returns (uint256) {
        if (epochId == 0 || epochId > currentEpochId) return 0;

        Epoch storage epoch = epochs[epochId];
        if (epoch.hasClaimed[user]) return 0;

        modules[moduleIndex].module;
        uint256 userShares = module.getUserShares(user);
        if (userShares == 0) return 0;

        uint256 totalShares = module.getTotalShares();
        return (userShares * epoch.amount) / totalShares;
    }

    function hasUserClaimed(
        address user,
        uint256 epochId
    ) external view returns (bool) {
        return epochs[epochId].hasClaimed[user];
    }

    function getEpochInfo(
        uint256 epochId
    )
        external
        view
        returns (uint256 id, uint256 amount, uint256 pendingRewards)
    {
        Epoch storage epoch = epochs[epochId];
        return (epoch.id, epoch.amount, epoch.pendingRewards);
    }

    // ============ Internal Functions ============
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 supply = totalSupply();
        return
            supply == 0
                ? shares
                : shares.mulDiv(
                    totalAssets(),
                    supply + 10 ** decimals(),
                    rounding
                );
    }

    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 supply = totalSupply();
        return
            supply == 0
                ? assets
                : assets.mulDiv(
                    supply + 10 ** decimals(),
                    totalAssets() + 1,
                    rounding
                );
    }

    function setVaultFees(VaultFees calldata newFees_) external onlyOwner {
        fees = newFees_;
        feesUpdatedAt = block.timestamp;
    }
}
