//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626Upgradeable, IERC20, IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

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
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice Minimum amount considered for calculations to prevent dust
    /// @dev Used as a threshold for minimum meaningful operations
    uint32 private constant DUST = 1e8;

    /// @notice Precision factor used in internal calculations
    /// @dev High precision to minimize rounding errors
    uint256 private constant PRECISION = 1e36;

    /// @notice Timestamp of the first deposit into the vault
    /// @dev Used for various time-based calculations
    uint256 public firstDeposit = 0;

    /// @notice Number of seconds in a year
    /// @dev Used for annualized calculations
    uint256 private constant SECONDS_PER_YEAR = 365.25 days;

    /// @notice Number of decimals for the vault's shares
    /// @dev Fixed to prevent decimal-related exploits
    uint8 private constant _decimals = 8;

    /// @notice Decimal offset to prevent share price manipulation
    /// @dev Applied to share calculations as a security measure
    uint8 public constant decimalOffset = 4;

    /// @notice Maximum total value of assets that can be deposited
    /// @dev Limit is in USD value of total assets
    uint256 public depositLimit;

    /// @notice Last time the fee structure was modified
    /// @dev Timestamp of the most recent fee update
    uint256 public feesUpdatedAt;

    /// @notice Address that receives collected fees
    /// @dev Must be non-zero when fees are enabled
    address public feeReceiver;

    /// @notice Address of the vault's underlying token
    /// @dev Token that the vault accepts for deposits
    address private vaultTokenAddress;

    /// @notice Tracks total returns claimed by each user
    /// @dev Maps user address to their total claimed returns
    mapping(address => uint256) public totalReturnsClaimed;

    /// @notice Emitted when the vault is initialized
    /// @param vaultName Address identifier for the vault
    /// @param underlyingAsset Address of the token the vault accepts
    event Initialized(
        address indexed vaultName,
        address indexed underlyingAsset
    );

    /// @notice Emitted when tokens are deposited into the vault
    /// @param token Address of the deposited token
    /// @param amount Amount of tokens deposited
    /// @param user Address of the depositor
    event TokenDeposited(address token, uint256 amount, address user);

    /// @notice Emitted when a user claims their returns
    /// @param user Address of the user claiming returns
    /// @param amount Amount of returns claimed
    event ClaimedReturns(address indexed user, uint256 amount);
}
