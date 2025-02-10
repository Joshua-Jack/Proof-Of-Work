//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";

/// @title MarketplaceController
/// @author Momint
/// @notice Controller contract for managing marketplace configurations and operations
/// @dev Implements OpenZeppelin's AccessControl for role-based permissions
contract MarketplaceController is AccessControl {
    /// @notice Role identifier for marketplace controller permissions
    bytes32 public constant MARKETPLACE_CONTROLLER_ROLE =
        keccak256("MARKETPLACE_CONTROLLER_ROLE");

    /// @notice Role identifier for pause controller permissions
    bytes32 public constant PAUSE_CONTROLLER_ROLE =
        keccak256("PAUSE_CONTROLLER_ROLE");

    /// @notice Emitted when a marketplace's fee recipient is updated
    event FeeRecipientUpdated(
        address indexed marketplace,
        address indexed newRecipient
    );

    /// @notice Emitted when a marketplace's protocol fee is updated
    event ProtocolFeeUpdated(address indexed marketplace, uint256 newFee);

    /// @notice Emitted when a token is accepted/rejected in a marketplace
    event TokenAcceptanceUpdated(
        address indexed marketplace,
        address indexed token,
        bool accepted
    );

    /// @notice Emitted when a marketplace is paused
    event MarketplacePaused(address indexed marketplace);

    /// @notice Emitted when a marketplace is unpaused
    event MarketplaceUnpaused(address indexed marketplace);

    /// @notice Emitted when emergency withdraw is called
    event EmergencyWithdraw(
        address indexed marketplace,
        address indexed token,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice Emitted when emergency stop is toggled
    event EmergencyStopToggled(address indexed marketplace, bool emergencyStop);

    /// @notice Initializes the contract with an admin address
    /// @dev Grants roles to admin
    /// @param admin Address to be granted admin privileges
    constructor(address admin) {
        require(admin != address(0), "Invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MARKETPLACE_CONTROLLER_ROLE, admin);
        _grantRole(PAUSE_CONTROLLER_ROLE, admin);
    }

    /// @notice Updates the fee recipient for a marketplace
    /// @dev Only callable by accounts with MARKETPLACE_CONTROLLER_ROLE
    /// @param marketplace_ Address of the marketplace to update
    /// @param newRecipient_ Address of the new fee recipient
    function setFeeRecipient(
        address marketplace_,
        address newRecipient_
    ) external onlyRole(MARKETPLACE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        require(newRecipient_ != address(0), "Invalid recipient address");
        emit FeeRecipientUpdated(marketplace_, newRecipient_);

        IMarketplace(marketplace_).setFeeRecipient(newRecipient_);
    }

    /// @notice Updates the protocol fee for a marketplace
    /// @dev Only callable by accounts with MARKETPLACE_CONTROLLER_ROLE
    /// @param marketplace_ Address of the marketplace to update
    /// @param newFee_ New protocol fee value (in basis points)
    function setProtocolFee(
        address marketplace_,
        uint256 newFee_
    ) external onlyRole(MARKETPLACE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        require(newFee_ <= 10000, "Fee exceeds maximum"); // Max 100%
        emit ProtocolFeeUpdated(marketplace_, newFee_);

        IMarketplace(marketplace_).setProtocolFee(newFee_);
    }

    /// @notice Sets whether a token is accepted in a marketplace
    /// @dev Only callable by accounts with MARKETPLACE_CONTROLLER_ROLE
    /// @param marketplace_ Address of the marketplace
    /// @param token_ Address of the token
    /// @param accepted_ Whether the token should be accepted
    function setAcceptedToken(
        address marketplace_,
        address token_,
        bool accepted_
    ) external onlyRole(MARKETPLACE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        require(token_ != address(0), "Invalid token address");
        emit TokenAcceptanceUpdated(marketplace_, token_, accepted_);

        IMarketplace(marketplace_).setAcceptedToken(token_, accepted_);
    }

    function emergencyWithdraw(
        address marketplace_,
        address token_,
        uint256 tokenId_,
        uint256 amount,
        address admin
    ) external onlyRole(PAUSE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        require(token_ != address(0), "Invalid token address");
        require(tokenId_ != 0, "Invalid tokenId");
        require(amount > 0, "Invalid amount");

        emit EmergencyWithdraw(marketplace_, token_, tokenId_, amount);
        IMarketplace(marketplace_).emergencyWithdraw(
            token_,
            tokenId_,
            amount,
            admin
        );
    }

    /// @notice Pauses a marketplace's operations
    /// @dev Only callable by accounts with PAUSE_CONTROLLER_ROLE
    /// @param marketplace_ Address of the marketplace to pause
    function pauseMarketplace(
        address marketplace_
    ) external onlyRole(PAUSE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        emit MarketplacePaused(marketplace_);
        IMarketplace(marketplace_).pause();
    }

    /// @notice Unpauses a marketplace's operations
    /// @dev Only callable by accounts with PAUSE_CONTROLLER_ROLE
    /// @param marketplace_ Address of the marketplace to unpause
    function unpauseMarketplace(
        address marketplace_
    ) external onlyRole(PAUSE_CONTROLLER_ROLE) {
        require(marketplace_ != address(0), "Invalid marketplace address");
        emit MarketplaceUnpaused(marketplace_);
        IMarketplace(marketplace_).unpause();
    }
}
