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
import {IMomintVault, Module, VaultFees} from "../interfaces/IMomintVault.sol";
import {MAX_BASIS_POINTS} from "../utils/Constants.sol";
import {console} from "forge-std/console.sol";

// TODO: Add configurable project owner withdraw amount example - 10% of the deposit amount is held in liqudidty and the rest is sent to the owner
// TODO CHECK THE RETURN BALANCE
// TODO ADD FUNCTION TO UPDATE THE SHARE HOLDER BEFORE ERC20 SHARES ARE TRANSFERRED

/// @title MomintVault
/// @author Momint
/// @notice An upgradeable ERC4626-compliant vault with enhanced security features
/// @dev Implements ERC4626 with additional security measures including:
///      - Reentrancy protection
///      - Pausability
///      - Access control
///      - Decimal offset to prevent share inflation attacks
contract MomintVault is
    ERC4626Upgradeable,
    ReentrancyGuard,
    PausableUpgradeable,
    OwnableUpgradeable,
    IMomintVault
{
    using SafeERC20 for IERC20;
    using Math for uint256;
    error InvalidIndex(uint256 index);

    /// @notice Minimum amount considered for calculations to prevent dust
    /// @dev Used as a threshold for minimum meaningful operations
    uint32 private constant DUST = 1e4;

    /// @notice Precision factor used in internal calculations
    /// @dev High precision to minimize rounding errors
    uint256 private constant PRECISION = 1e36;

    /// @notice Timestamp of the first deposit into the vault
    /// @dev Used for various time-based calculations
    uint256 public firstDeposit = 0;

    /// @notice Number of decimals for the vault's shares
    /// @dev Fixed to prevent decimal-related exploits
    uint8 private _decimals;

    /// @notice Decimal offset to prevent share price manipulation
    /// @dev Applied to share calculations as a security measure
    uint8 public constant decimalOffset = 9;

    /// @notice Maximum total value of assets that can be deposited
    /// @dev Limit is in USD value of total assets
    uint256 public depositLimit;

    /// @notice Last time the fee structure was modified
    /// @dev Timestamp of the most recent fee update
    uint256 public feesUpdatedAt;

    /// @notice Address that receives collected fees
    /// @dev Must be non-zero when fees are enabled
    address public feeRecipient;

    /// @notice Address of the vault's underlying token
    /// @dev Token that the vault accepts for deposits
    address private vaultTokenAddress;

    /// @notice The array of strategies that the vault can interact with.
    /// @dev Public array storing the strategies associated with the vault.
    Module[] public modules;

    IModule public module;

    /// @notice The fee structure of the vault.
    /// @dev Public variable storing the fees associated with the vault.
    VaultFees private fees;
    uint256 public lastUpdateTime;
    /// @notice Tracks total returns claimed by each user
    /// @dev Maps user address to their total claimed returns
    mapping(address => uint256) public totalReturnsClaimed;
    mapping(address => uint256) public pendingReturns;
    mapping(address => UserReturns) public userReturns;
    uint256 public totalPendingReturns;
    uint256 public totalDistributedReturns;
    /// @notice Emitted when the vault is initialized
    /// @param vaultName Address identifier for the vault
    /// @param underlyingAsset Address of the token the vault accepts
    event Initialized(
        address indexed vaultName,
        address indexed underlyingAsset
    );

    // Add these events
    event ReturnsDistributed(uint256 amount);
    event ReturnsClaimed(
        address indexed user,
        uint256 moduleIndex,
        uint256 epochId,
        uint256 amount
    );

    // Add these errors
    error InsufficientReturns();
    error NoReturnsAvailable();

    /// @notice Emitted when tokens are deposited into the vault
    /// @param token Address of the deposited token
    /// @param amount Amount of tokens deposited
    /// @param user Address of the depositor
    event TokenDeposited(address token, uint256 amount, address user);

    /// @notice Emitted when a user claims their returns
    /// @param user Address of the user claiming returns
    /// @param amount Amount of returns claimed
    event ClaimedReturns(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SharesMinted(address indexed user, uint256 shares, uint256 assets);
    event ReturnsDistributed(uint256 amount, uint256 epochId);
    /// @notice Error for invalid fee recipient address.
    error InvalidFeeRecipient();
    /// @notice Error for invalid asset address.
    error InvalidAssetAddress();

    error AssetMismatch();
    error ModuleRemovalFailed();
    error CannotRemoveLastModule();
    error InvalidModuleAddress();
    // Add these errors
    error InvalidAmount();
    error InvalidReceiver();
    error NoActiveModules();
    error SharesMismatch();
    error ZeroAmount();

    struct Epoch {
        uint256 id; // Unique epoch identifier
        uint256 amount; // Amount distributed in this epoch
        uint256 pendingRewards; // Unclaimed rewards from this epoch
        mapping(address => bool) hasClaimed; // Track who has claimed in this epoch
    }

    // Track epochs by ID
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpochId;

    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the vault with basic parameters
    /// @param baseAsset_ The underlying asset token
    /// @param symbol_ Symbol of the vault token
    /// @param shareName_ Name of the vault token
    /// @param owner_ Owner of the vault
    /// @param feeRecipient_ The recipient of the fees collected by the vault.
    // slither didn't detect the nonReentrant modifier
    // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,calls-loop,costly-loop
    function initialize(
        IERC20 baseAsset_,
        string memory symbol_,
        string memory shareName_,
        address owner_,
        address feeRecipient_,
        VaultFees memory fees_
    ) external initializer nonReentrant {
        __ERC4626_init(baseAsset_);
        __Ownable_init(owner_);
        __ERC20_init(shareName_, symbol_);
        __Pausable_init();
        if (address(baseAsset_) == address(0)) revert InvalidAssetAddress();
        if (feeRecipient_ == address(0)) {
            revert InvalidFeeRecipient();
        }
        vaultTokenAddress = address(baseAsset_);
        (_decimals) = VaultHelper.validateVaultParameters(
            baseAsset_,
            decimalOffset,
            fees_,
            fees
        );
        feeRecipient = feeRecipient_;
        emit Initialized(address(this), address(baseAsset_));
    }

    /**
     * @notice Returns the decimals of the vault's shares.
     * @dev Overrides the decimals function in inherited contracts to return the custom vault decimals.
     * @return The decimals of the vault's shares.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Pauses all deposit and withdrawal functions.
     * @dev Can only be called by the owner. Emits a `Paused` event.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the vault, allowing deposit and withdrawal functions.
     * @dev Can only be called by the owner. Emits an `Unpaused` event.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function deposit(
        uint256 assets_,
        uint256 index_
    ) external returns (uint256) {
        return deposit(assets_, msg.sender, index_);
    }

    /// @notice Deposit assets and receive shares
    /// @param assets Amount of assets to deposit
    /// @param receiver Address to receive the shares
    /// @return shares Amount of shares minted
    function deposit(
        uint256 assets,
        address receiver,
        uint256 index_
    ) public nonReentrant whenNotPaused returns (uint256 shares) {
        if (assets == 0) revert InvalidAmount();
        if (receiver == address(0)) revert InvalidReceiver();
        // Check for active modules
        if (modules.length == 0) revert NoActiveModules();
        // Get reference to first active module (simplified version)
        Module storage activeModule = modules[index_];
        if (!activeModule.active) revert NoActiveModules();

        uint256 feeShares = _convertToShares(
            assets.mulDiv(
                uint256(fees.depositFee),
                MAX_BASIS_POINTS,
                Math.Rounding.Floor
            ),
            Math.Rounding.Floor
        );

        // Calculate the net shares
        shares = _convertToShares(assets, Math.Rounding.Floor) - feeShares;
        if (shares <= DUST) revert ZeroAmount();

        // Transfer assets from user
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Handle fees
        if (feeShares > 0) {
            IERC20(asset()).safeTransfer(feeRecipient, feeShares);
        }
        // Invest in module
        (uint256 projectShares, uint256 refund) = activeModule.module.invest(
            assets - feeShares, // Invest net amount after fees
            receiver
        );

        // Handle refund
        if (refund > 0) {
            IERC20(asset()).safeTransfer(msg.sender, refund);
            emit Refund(msg.sender, refund);
        }

        // Mint shares only once
        _mint(receiver, projectShares);

        emit Deposit(msg.sender, receiver, assets - refund, projectShares);
        return projectShares;
    }

    error InsufficientBalance();
    error WithdrawalTooSmall();
    event Withdraw(
        address indexed user,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    function withdraw(uint256 shares) external returns (uint256) {
        return withdraw(shares, msg.sender);
    }

    function withdraw(
        uint256 shares,
        address receiver
    ) public nonReentrant whenNotPaused returns (uint256 assets) {
        if (shares == 0) revert InvalidAmount();
        if (receiver == address(0)) revert InvalidReceiver();

        // Check for active modules
        if (modules.length == 0) revert NoActiveModules();
        Module storage activeModule = modules[0];
        if (!activeModule.active) revert NoActiveModules();

        // Check user's balance
        if (balanceOf(msg.sender) < shares) revert InsufficientBalance();

        // Divest from module first to get actual asset amount
        uint256 divestAmount = activeModule.module.divest(shares, msg.sender);
        if (divestAmount <= DUST) revert WithdrawalTooSmall();

        // Calculate withdrawal fee based on divest amount
        uint256 withdrawalFee = divestAmount.mulDiv(
            uint256(fees.withdrawalFee),
            MAX_BASIS_POINTS,
            Math.Rounding.Floor
        );

        // Net amount after fees
        uint256 netAssets = divestAmount - withdrawalFee;

        // Burn shares after successful divestment
        _burn(msg.sender, shares);

        // Handle fees
        if (withdrawalFee > 0) {
            IERC20(asset()).safeTransfer(feeRecipient, withdrawalFee);
        }

        // Transfer net assets to receiver
        IERC20(asset()).safeTransfer(receiver, netAssets);

        emit Withdraw(msg.sender, receiver, netAssets, shares);
        return netAssets;
    }

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

    error DistributionTooSmall();

    function distributeReturns(
        uint256 amount,
        uint256 index_
    ) external nonReentrant onlyOwner {
        if (amount == 0) revert InvalidAmount();
        uint256 minUserShares = 1; // Minimum possible shares is 1
        uint256 totalShares = modules[index_].module.getTotalShares(); // Assuming at least one module
        uint256 minUserShare = (amount * minUserShares) / totalShares;

        // Ensure minimum share is above DUST
        if (minUserShare <= DUST) {
            revert DistributionTooSmall();
        }
        // Transfer returns to vault
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

        // Create new epoch
        uint256 epochId = ++currentEpochId;
        Epoch storage newEpoch = epochs[epochId];
        newEpoch.id = epochId;
        newEpoch.amount = amount;
        newEpoch.pendingRewards = amount;

        totalDistributedReturns += amount;

        emit ReturnsDistributed(amount, epochId);
    }

    error InvalidEpochId();
    error AlreadyClaimed();
    error NoSharesOwned();
    error InvalidModuleIndex();

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

        // Get total shares directly from module
        uint256 totalShares = modulesP.module.getTotalShares();

        // Calculate user's share with proper scaling
        // First multiply by amount to prevent truncation
        uint256 userShare = (epoch.amount * userShares) / totalShares;

        if (userShare <= DUST) revert NoReturnsAvailable();

        // Mark as claimed and update pending rewards
        epoch.hasClaimed[msg.sender] = true;
        epoch.pendingRewards -= userShare;

        // Transfer claimed amount using SafeERC20
        IERC20(asset()).safeTransfer(msg.sender, userShare);

        emit ReturnsClaimed(msg.sender, moduleIndex, epochId, userShare);
        return userShare;
    }

    /**
     * @notice Updates the vault's fee structure.
     * @dev Can only be called by the vault owner. Emits an event upon successful update.
     * @param newFees_ The new fee structure to apply to the vault.
     */
    function setVaultFees(VaultFees calldata newFees_) external onlyOwner {
        fees = newFees_; // Update the fee structure
        feesUpdatedAt = block.timestamp; // Record the time of the fee update
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

    /**
     * @notice Retrieves the current fee structure of the vault.
     * @dev Returns the vault's fees including deposit, withdrawal, protocol, and performance fees.
     * @return A `VaultFees` struct containing the current fee rates.
     */
    function getVaultFees() public view returns (VaultFees memory) {
        return fees;
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

    event ModuleAdded(
        address indexed module,
        bool isSingleProject,
        uint256 indexed index
    );

    function addModule(
        Module calldata newModule_,
        bool replace_,
        uint256 index_
    ) external nonReentrant onlyOwner {
        // Input validation
        if (address(newModule_.module) == address(0))
            revert InvalidModuleAddress();
        if (replace_ && index_ >= modules.length) revert InvalidIndex(index_);

        IModule newModule;
        IModule removedModule;

        // Add or replace module
        (newModule, removedModule) = VaultHelper.addOrReplaceModule(
            modules,
            newModule_,
            replace_,
            index_
        );

        // Emit appropriate events
        if (address(removedModule) != address(0)) {
            emit ModuleRemoved(address(removedModule));
        }
        emit ModuleAdded(
            address(newModule),
            newModule_.isSingleProject,
            replace_ ? index_ : modules.length - 1
        );
    }

    // In MomintVault.sol
    function removeModule(uint256 index_) external nonReentrant onlyOwner {
        uint256 len = modules.length;
        if (index_ >= len) revert InvalidIndex(index_);

        // Store module reference before removal
        IModule moduleToBeRemoved = modules[index_].module;

        // Deactivate the module first
        modules[index_].active = false;

        // Swap and pop if not the last element
        if (index_ != len - 1) {
            modules[index_] = modules[len - 1];
        }
        modules.pop();

        emit ModuleRemoved(address(moduleToBeRemoved));
    }

    // Add a getter function for modules
    function getModule(uint256 index_) external view returns (Module memory) {
        if (index_ >= modules.length) revert InvalidIndex(index_);
        return modules[index_];
    }

    function getModulesLength() external view returns (uint256) {
        return modules.length;
    }
}
