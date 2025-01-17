// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../assets/ERC1155RWA.sol";

/**
 * @title RWA Marketplace
 * @dev Implementation contract for marketplace functionality
 */
contract Marketplace is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // State variables
    ERC1155RWA public rwaToken;
    mapping(address => bool) public acceptedTokens;
    uint256 public protocolFee;
    address public feeRecipient;
    bool public emergencyStop;
    uint256 private _nextListingId;

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerToken;
        address paymentToken;
        bool active;
    }

    // Mappings
    mapping(uint256 => Listing) public listings;

    // Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 pricePerToken,
        address paymentToken
    );
    event ListingCancelled(uint256 indexed listingId);
    event ListingSold(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice
    );
    event RoyaltyPaid(
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 amount
    );
    event ProtocolFeePaid(uint256 indexed listingId, uint256 amount);
    event EmergencyToggled(bool stopped);

    // Custom errors
    error InsufficientPayment(uint256 expected, uint256 received);
    error InvalidRoyaltyAmount(uint256 amount);
    error TransferFailed();
    error EmergencyStopActive();
    error InvalidToken();
    error InvalidAmount();
    error NotSeller();
    error ListingNotActive();
    error FeeTooHigh();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _rwaToken,
        address _feeRecipient,
        uint256 _protocolFee
    ) public initializer {
        if (_rwaToken == address(0)) revert InvalidToken();
        if (_feeRecipient == address(0)) revert InvalidToken();
        if (_protocolFee > 1000) revert FeeTooHigh();

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        rwaToken = ERC1155RWA(_rwaToken);
        feeRecipient = _feeRecipient;
        protocolFee = _protocolFee;
        _nextListingId = 0;
    }

    // Admin functions
    function setProtocolFee(uint256 _fee) external onlyOwner {
        if (_fee > 1000) revert FeeTooHigh();
        protocolFee = _fee;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidToken();
        feeRecipient = _feeRecipient;
    }

    function setAcceptedToken(address token, bool accepted) external onlyOwner {
        if (token == address(0)) revert InvalidToken();
        acceptedTokens[token] = accepted;
    }

    function toggleEmergencyStop() external onlyOwner {
        emergencyStop = !emergencyStop;
        emit EmergencyToggled(emergencyStop);
    }

    // Main marketplace functions
    function createListing(
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerToken,
        address paymentToken
    ) external returns (uint256) {
        if (emergencyStop) revert EmergencyStopActive();
        if (amount == 0) revert InvalidAmount();
        if (pricePerToken == 0) revert InvalidAmount();
        if (!acceptedTokens[paymentToken]) revert InvalidToken();

        if (rwaToken.balanceOf(msg.sender, tokenId) < amount)
            revert InsufficientPayment(
                amount,
                rwaToken.balanceOf(msg.sender, tokenId)
            );

        uint256 listingId = _nextListingId++;

        listings[listingId] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            amount: amount,
            pricePerToken: pricePerToken,
            paymentToken: paymentToken,
            active: true
        });

        // Transfer tokens to marketplace
        rwaToken.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );

        emit ListingCreated(
            listingId,
            msg.sender,
            tokenId,
            amount,
            pricePerToken,
            paymentToken
        );

        return listingId;
    }

    function cancelListing(uint256 listingId) external {
        if (emergencyStop) revert EmergencyStopActive();

        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (listing.seller != msg.sender) revert NotSeller();

        listing.active = false;

        // Return tokens to seller
        rwaToken.safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId,
            listing.amount,
            ""
        );

        emit ListingCancelled(listingId);
    }

    function buyTokens(
        uint256 listingId,
        uint256 amount
    ) external nonReentrant {
        if (emergencyStop) revert EmergencyStopActive();

        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (amount > listing.amount) revert InvalidAmount();

        uint256 totalPrice = _handlePayment(listingId, amount, msg.sender);

        // Transfer tokens to buyer
        rwaToken.safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId,
            amount,
            ""
        );

        // Update listing
        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit ListingSold(
            listingId,
            msg.sender,
            listing.tokenId,
            amount,
            totalPrice
        );
    }

    function batchBuyTokens(
        uint256[] calldata listingIds,
        uint256[] calldata amounts
    ) external nonReentrant {
        if (emergencyStop) revert EmergencyStopActive();
        if (listingIds.length != amounts.length) revert InvalidAmount();

        for (uint256 i = 0; i < listingIds.length; i++) {
            _processPurchase(listingIds[i], amounts[i]);
        }
    }

    // Internal functions
    function _handlePayment(
        uint256 listingId,
        uint256 amount,
        address buyer
    ) internal returns (uint256) {
        Listing storage listing = listings[listingId];
        uint256 totalPrice = amount * listing.pricePerToken;
        IERC20 paymentToken = IERC20(listing.paymentToken);

        // Calculate protocol fee
        uint256 protocolFeeAmount = (totalPrice * protocolFee) / 10000;

        // Get royalties from token contract
        (address[] memory recipients, uint256[] memory royalties) = rwaToken
            .getRoyaltyDetails(listing.tokenId, totalPrice);

        // Handle all payments atomically
        uint256 remainingAmount = totalPrice;

        // Transfer protocol fee
        if (protocolFeeAmount > 0) {
            bool feeTransferred = paymentToken.transferFrom(
                buyer,
                feeRecipient,
                protocolFeeAmount
            );
            if (!feeTransferred) revert TransferFailed();

            remainingAmount -= protocolFeeAmount;
            emit ProtocolFeePaid(listingId, protocolFeeAmount);
        }

        // Transfer royalties
        uint256 totalRoyalties = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (royalties[i] > 0) {
                bool royaltyTransferred = paymentToken.transferFrom(
                    buyer,
                    recipients[i],
                    royalties[i]
                );
                if (!royaltyTransferred) revert TransferFailed();

                totalRoyalties += royalties[i];
                emit RoyaltyPaid(listing.tokenId, recipients[i], royalties[i]);
            }
        }
        remainingAmount -= totalRoyalties;

        // Transfer remaining amount to seller
        bool sellerPaid = paymentToken.transferFrom(
            buyer,
            listing.seller,
            remainingAmount
        );
        if (!sellerPaid) revert TransferFailed();

        return totalPrice;
    }

    function _processPurchase(uint256 listingId, uint256 amount) internal {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (amount > listing.amount) revert InvalidAmount();

        uint256 totalPrice = _handlePayment(listingId, amount, msg.sender);

        // Transfer tokens to buyer
        rwaToken.safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId,
            amount,
            ""
        );

        // Update listing
        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit ListingSold(
            listingId,
            msg.sender,
            listing.tokenId,
            amount,
            totalPrice
        );
    }

    // Emergency functions
    function emergencyWithdraw(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        if (!emergencyStop) revert EmergencyStopActive();

        if (token == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC1155(token).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                amount,
                ""
            );
        }
    }
}
