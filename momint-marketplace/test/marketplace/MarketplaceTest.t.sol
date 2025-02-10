// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../../src/controllers/UpgradableBeaconController.sol";
import "../../src/controllers/MarketplaceController.sol";
import {Marketplace} from "../../src/marketplace/Marketplace.sol";
import {ERC1155RWA} from "../../src/assets/ERC1155RWA.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Styles} from "../utils/Styles.sol";
// Custom errors
error InvalidInitialization();
error AccessControlUnauthorizedAccount(address account, bytes32 role);

contract MarketplaceTest is Test {
    // Controllers
    UpgradableBeaconController public beaconController;
    MarketplaceController public marketplaceController;

    // Core contracts
    Marketplace public implementation;
    Marketplace public marketplace;
    ERC1155RWA public rwaToken;

    // Constants
    string constant MARKETPLACE_BEACON = "MARKETPLACE_V1";
    uint256 constant PROTOCOL_FEE = 250; // 2.5%
    uint256 constant INITIAL_BALANCE = 10000 * 10 ** 18; // 10000 USDC
    uint256 constant INITIAL_SUPPLY = 100;
    string constant LISK_RPC_URL = "https://rpc.api.lisk.com";
    uint256 constant FORK_BLOCK_NUMBER = 11774326; // We'll need the actual block number
    address constant LISK_TOKEN = 0xac485391EB2d7D88253a7F1eF18C37f4242D1A24;
    IERC20 public USDT = IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);
    address LISK_WHALE = 0xC8CFB2922414DcD4Eb61380A8b59bB8166c225f1; // We'll need a whale address
    // Test addresses
    address public admin = 0x8907C46657c18C7E12efCe6aE7E820cC12Ee2d61;
    address public seller = 0xC20e318fe1830DE929bB8eE57F6209a89F0ab00F;
    address public buyer = 0x07aE8551Be970cB1cCa11Dd7a11F47Ae82e70E67;
    address public feeRecipient = 0x3031B7445F27D68d19B8A3aAeDE9F036945D9c60;
    address public pauseController;

    event FeeRecipientUpdated(
        address indexed marketplace,
        address newFeeRecipient
    );
    event ProtocolFeeUpdated(
        address indexed marketplace,
        uint256 newProtocolFee
    );
    event EmergencyWithdraw(
        address indexed marketplace,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount
    );
    event EmergencyStopToggled(address indexed marketplace, bool emergencyStop);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        // Create fork
        uint256 lisk = vm.createFork(LISK_RPC_URL, FORK_BLOCK_NUMBER);
        vm.selectFork(lisk);
        // Deploy controllers
        beaconController = new UpgradableBeaconController();
        marketplaceController = new MarketplaceController(admin);

        // Start as admin for role management
        vm.startPrank(admin);

        // Update the roles - now as admin
        marketplaceController.grantRole(
            marketplaceController.PAUSE_CONTROLLER_ROLE(),
            address(marketplaceController)
        );

        // Grant MARKETPLACE_CONTROLLER_ROLE to admin
        marketplaceController.grantRole(
            marketplaceController.MARKETPLACE_CONTROLLER_ROLE(),
            admin
        );

        // Deploy RWA implementation and proxy setup
        ERC1155RWA rwaImplementation = new ERC1155RWA();
        ProxyAdmin proxyAdmin = new ProxyAdmin(admin);

        bytes memory rwaInitData = abi.encodeWithSelector(
            ERC1155RWA.initialize.selector,
            admin,
            "ipfs://"
        );

        TransparentUpgradeableProxy rwaProxy = new TransparentUpgradeableProxy(
            address(rwaImplementation),
            address(proxyAdmin),
            rwaInitData
        );

        rwaToken = ERC1155RWA(address(rwaProxy));
        vm.makePersistent(address(rwaToken));
        // Deploy marketplace implementation
        implementation = new Marketplace();

        // Deploy beacon through controller
        beaconController.deployUpgradeableBeacon(
            MARKETPLACE_BEACON,
            address(implementation),
            address(beaconController)
        );

        // Deploy and initialize marketplace proxy
        BeaconProxy proxy = new BeaconProxy(
            beaconController.beacons(MARKETPLACE_BEACON),
            abi.encodeWithSelector(
                Marketplace.initialize.selector,
                address(rwaToken),
                feeRecipient,
                PROTOCOL_FEE
            )
        );

        marketplace = Marketplace(address(proxy));
        vm.makePersistent(address(marketplace));
        // Transfer ownership of marketplace to controller
        marketplace.transferOwnership(address(marketplaceController));

        // Setup roles and permissions
        rwaToken.grantRole(rwaToken.MINTER_ROLE(), admin);

        // Set accepted token
        marketplaceController.setAcceptedToken(
            address(marketplace),
            address(USDT),
            true
        );

        // Stop being admin
        vm.stopPrank();
    }

    function test_case1() public view {
        console.log(Styles.h1("Marketplace Test"));
        marketplaceInitialization();
        console.log("");
        console.log(
            Styles.h2(
                "End of Marketplace Initialization ----------------------------------------"
            )
        );
    }

    function test_case2() public {
        console.log(Styles.h1("Marketplace Test: Update Fee Recipient"));
        updateFeeRecipient();
        console.log("");
        console.log(
            Styles.h2(
                "End of Update Fee Recipient ----------------------------------------"
            )
        );
    }

    function test_case3() public {
        console.log(Styles.h1("Marketplace Test: Update Protocol Fee"));
        updateProtocolFee();
        console.log("");
        console.log(
            Styles.h2(
                "End of Update Protocol Fee ----------------------------------------"
            )
        );
    }

    function test_case4() public {
        console.log(Styles.h1("Marketplace Test: Whitelist Token"));
        whitelistToken();
        console.log("");
        console.log(
            Styles.h2(
                "End of Whitelist Token ----------------------------------------"
            )
        );
    }

    function test_case5() public {
        console.log(Styles.h1("Marketplace Test: Remove Token from Whitelist"));
        removeTokenFromWhitelist();
        console.log("");
        console.log(
            Styles.h2(
                "End of Remove Token from Whitelist ----------------------------------------"
            )
        );
    }

    function test_case6() public {
        console.log(
            Styles.h1("Marketplace Test: Create Listing with LISK Token")
        );
        createListingWithLiskToken();
        console.log("");
        console.log(
            Styles.h2(
                "End of Create Listing with LISK Token ----------------------------------------"
            )
        );
    }

    function test_case7() public {
        console.log(Styles.h1("Marketplace Test: Purchase with LISK Token"));
        purchaseWithLiskToken();
        console.log("");
        console.log(
            Styles.h2(
                "End of Purchase with LISK Token ----------------------------------------"
            )
        );
    }

    function test_case8() public {
        console.log(Styles.h1("Marketplace Test: Cancel Listing"));
        cancelListing();
        console.log("");
        console.log(
            Styles.h2(
                "End of Cancel Listing ----------------------------------------"
            )
        );
    }

    function cancelListing() public {
        console.log("");
        console.log(Styles.h1("Test: Cancel Listing"));
        console.log(
            Styles.p(
                "This test verifies the listing cancellation functionality"
            )
        );
        console.log("");

        // Step 1: Setup - Whitelist LISK token
        console.log(Styles.h2("Step 1: Setup"));
        vm.startPrank(admin);
        marketplaceController.setAcceptedToken(
            address(marketplace),
            LISK_TOKEN,
            true
        );
        console.log(
            Styles.p("LISK Token Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(LISK_TOKEN))
        );

        // Mint and transfer RWA token
        uint256 tokenId = rwaToken.mint(
            100,
            "ipfs://metadata",
            new address[](0),
            new uint256[](0)
        );
        console.log(
            Styles.p("RWA Token Minted - ID:"),
            StdStyle.green(tokenId)
        );

        rwaToken.safeTransferFrom(admin, seller, tokenId, 50, "");
        console.log(
            Styles.p("Tokens Transferred to Seller:"),
            StdStyle.green(rwaToken.balanceOf(seller, tokenId))
        );
        vm.stopPrank();

        // Step 2: Create listing
        console.log("");
        console.log(Styles.h2("Step 2: Creating Listing"));
        vm.startPrank(seller);
        rwaToken.setApprovalForAll(address(marketplace), true);
        console.log(
            Styles.p("Marketplace Approval Status:"),
            StdStyle.green(
                rwaToken.isApprovedForAll(seller, address(marketplace))
            )
        );

        uint256 listingId = marketplace.createListing(
            tokenId,
            25,
            1 ether,
            LISK_TOKEN
        );

        // Log initial listing details
        (
            address listingSeller,
            uint256 listingTokenId,
            uint256 listingAmount,
            uint256 listingPrice,
            address listingPaymentToken,
            bool listingActive
        ) = marketplace.listings(listingId);

        console.log("");
        console.log(Styles.h2("Initial Listing Details"));
        console.log(Styles.p("Listing ID:"), StdStyle.green(listingId));
        console.log(Styles.p("Seller:"), StdStyle.green(listingSeller));
        console.log(Styles.p("Token ID:"), StdStyle.green(listingTokenId));
        console.log(Styles.p("Amount Listed:"), StdStyle.green(listingAmount));
        console.log(
            Styles.p("Price Per Token:"),
            StdStyle.green(
                string.concat(vm.toString(listingPrice / 1 ether), " ETH")
            )
        );
        console.log(
            Styles.p("Payment Token:"),
            StdStyle.green(listingPaymentToken)
        );
        console.log(Styles.p("Listing Active:"), StdStyle.green(listingActive));

        // Step 3: Cancel the listing
        console.log("");
        console.log(Styles.h2("Step 3: Canceling Listing"));
        marketplace.cancelListing(listingId);
        vm.stopPrank();

        // Step 4: Verify the cancellation
        console.log("");
        console.log(Styles.h2("Step 4: Verification"));

        (
            listingSeller,
            listingTokenId,
            listingAmount,
            listingPrice,
            listingPaymentToken,
            listingActive
        ) = marketplace.listings(listingId);

        console.log(Styles.h2("Updated Listing Status"));
        console.log(Styles.p("Listing ID:"), StdStyle.green(listingId));
        console.log(
            Styles.p("Amount Remaining:"),
            StdStyle.green(listingAmount)
        );
        console.log(Styles.p("Listing Active:"), StdStyle.green(listingActive));

        // Verify seller still has their tokens
        uint256 sellerBalance = rwaToken.balanceOf(seller, tokenId);
        console.log("");
        console.log(Styles.h2("Token Balance Verification"));
        console.log(
            Styles.p("Seller's Token Balance:"),
            StdStyle.green(sellerBalance)
        );

        // Assertions
        assertFalse(listingActive, "Listing should be inactive");
        assertEq(sellerBalance, 50, "Seller should still have their tokens");

        console.log("");
        console.log(Styles.h2("Cancel Listing Test Completed Successfully"));
        console.log("");
    }

    function marketplaceInitialization() public view {
        assertEq(address(marketplace.rwaToken()), address(rwaToken));
        console.log("");
        console.log(Styles.p("ERC1155RWA:"), StdStyle.green(address(rwaToken)));
        console.log("");
        assertEq(marketplace.feeRecipient(), feeRecipient);
        console.log("");
        console.log(Styles.p("Fee Recipient:"), StdStyle.green(feeRecipient));
        console.log("");
        assertEq(marketplace.protocolFee(), PROTOCOL_FEE);
        console.log("");
        console.log(Styles.p("Protocol Fee:"), StdStyle.green(PROTOCOL_FEE));
        console.log("");
    }

    function updateFeeRecipient() public {
        vm.startPrank(admin);
        address newFeeRecipient = makeAddr("newFeeRecipient");
        console.log("");
        console.log(
            Styles.p("Old Fee Recipient:"),
            StdStyle.green(feeRecipient)
        );
        console.log("");

        marketplaceController.setFeeRecipient(
            address(marketplace),
            newFeeRecipient
        );

        assertEq(marketplace.feeRecipient(), newFeeRecipient);
        console.log("");
        console.log(
            Styles.p("New Fee Recipient:"),
            StdStyle.green(marketplace.feeRecipient())
        );
        console.log("");
        vm.stopPrank();
    }

    function updateProtocolFee() public {
        vm.startPrank(admin);
        uint256 newFee = 500; // 5%
        uint256 oldFee = PROTOCOL_FEE;
        console.log("");
        console.log(
            Styles.p("Old Protocol Fee:"),
            StdStyle.green(PROTOCOL_FEE)
        );
        console.log("");

        marketplaceController.setProtocolFee(address(marketplace), newFee);

        assertEq(marketplace.protocolFee(), newFee);
        console.log("");
        console.log(
            Styles.p("New Protocol Fee:"),
            StdStyle.green(marketplace.protocolFee())
        );
        console.log("");
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedPause() public {
        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                seller,
                marketplaceController.PAUSE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.pauseMarketplace(address(marketplace));

        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedFeeUpdate() public {
        vm.startPrank(seller);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                seller,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setProtocolFee(address(marketplace), 300);

        vm.stopPrank();
    }

    function test_RevertWhen_DoubleInitialization() public {
        vm.expectRevert(InvalidInitialization.selector);
        marketplace.initialize(address(rwaToken), feeRecipient, PROTOCOL_FEE);
    }

    function test_RevertWhen_UnauthorizedFeeRecipientUpdate() public {
        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                seller,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setFeeRecipient(address(marketplace), seller);
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedProtocolFeeUpdate() public {
        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                seller,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setProtocolFee(address(marketplace), 500);
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidProtocolFee() public {
        vm.startPrank(admin);
        vm.expectRevert("Fee exceeds maximum");
        marketplaceController.setProtocolFee(address(marketplace), 10001); // More than 100%
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidFeeRecipient() public {
        vm.startPrank(admin);
        vm.expectRevert("Invalid recipient address");
        marketplaceController.setFeeRecipient(address(marketplace), address(0));
        vm.stopPrank();
    }

    function whitelistToken() public {
        vm.startPrank(admin);
        console.log("");
        console.log(
            Styles.p("LISK Token Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(LISK_TOKEN))
        );
        console.log("");
        marketplaceController.setAcceptedToken(
            address(marketplace),
            LISK_TOKEN,
            true
        );
        assertTrue(marketplace.acceptedTokens(LISK_TOKEN));
        console.log("");
        console.log(
            Styles.p("LISK Token Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(LISK_TOKEN))
        );
        console.log("");
        vm.stopPrank();
    }

    function removeTokenFromWhitelist() public {
        // First verify USDC is whitelisted (from setUp)
        vm.startPrank(admin);
        assertTrue(marketplace.acceptedTokens(address(USDT)));
        console.log("");
        console.log(
            Styles.p("USDT Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(address(USDT)))
        );
        console.log("");
        marketplaceController.setAcceptedToken(
            address(marketplace),
            address(USDT),
            false
        );

        assertFalse(marketplace.acceptedTokens(address(USDT)));
        console.log("");
        console.log(
            Styles.p("USDT Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(address(USDT)))
        );
        console.log("");
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedWhitelistUpdate() public {
        address newToken = makeAddr("newToken");

        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                seller,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setAcceptedToken(
            address(marketplace),
            newToken,
            true
        );
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidTokenAddress() public {
        vm.startPrank(admin);
        vm.expectRevert("Invalid token address");
        marketplaceController.setAcceptedToken(
            address(marketplace),
            address(0),
            true
        );
        vm.stopPrank();
    }

    function createListingWithLiskToken() public {
        // Setup
        vm.startPrank(admin);

        uint256 tokenId = rwaToken.mint(
            100,
            "ipfs://metadata",
            new address[](0),
            new uint256[](0)
        );
        rwaToken.safeTransferFrom(admin, seller, tokenId, 50, "");
        console.log("");
        console.log(Styles.p("Token Minted:"), StdStyle.green(tokenId));
        console.log("");
        // Whitelist LISK token
        marketplaceController.setAcceptedToken(
            address(marketplace),
            LISK_TOKEN,
            true
        );
        console.log("");
        console.log(
            Styles.p("LISK Token Whitelisted:"),
            StdStyle.green(marketplace.acceptedTokens(LISK_TOKEN))
        );
        console.log("");
        vm.stopPrank();

        // Create listing with LISK token as payment
        vm.startPrank(seller);
        console.log("");
        console.log(
            Styles.p("Approving RWA tokens for marketplace"),
            StdStyle.green(address(marketplace))
        );
        console.log("");
        rwaToken.setApprovalForAll(address(marketplace), true);
        uint256 listingId = marketplace.createListing(
            tokenId,
            25,
            1 ether,
            LISK_TOKEN
        );
        console.log("");
        console.log(Styles.p("Listing Created:"), StdStyle.green(listingId));
        console.log("");
        vm.stopPrank();

        // Verify listing details
        (
            address listingSeller,
            uint256 listingTokenId,
            uint256 listingAmount,
            uint256 listingPrice,
            address listingPaymentToken,
            bool listingActive
        ) = marketplace.listings(listingId);
        console.log("");
        console.log(Styles.p("Listing Seller:"), StdStyle.green(listingSeller));
        console.log("");
        console.log(
            Styles.p("Listing Token ID:"),
            StdStyle.green(listingTokenId)
        );
        console.log("");
        console.log(Styles.p("Listing Amount:"), StdStyle.green(listingAmount));
        console.log("");
        console.log(Styles.p("Listing Price:"), StdStyle.green(listingPrice));
        console.log("");
        console.log(
            Styles.p("Listing Payment Token:"),
            StdStyle.green(listingPaymentToken)
        );
        console.log("");
        console.log(Styles.p("Listing Active:"), StdStyle.green(listingActive));
        console.log("");
        assertEq(listingSeller, seller);
        assertEq(listingTokenId, tokenId);
        assertEq(listingAmount, 25);
        assertEq(listingPrice, 1 ether);
        assertEq(listingPaymentToken, LISK_TOKEN);
        assertTrue(listingActive);
    }

    // Create a struct to hold test data
    struct TestSetup {
        uint256 tokenId;
        uint256 listingAmount;
        uint256 listingPrice;
        uint256 purchaseAmount;
        address[] royaltyRecipients;
        uint256[] royaltyShares;
    }

    // Helper struct for purchase calculations
    struct PurchaseCalc {
        uint256 totalCost;
        uint256 protocolFeeAmount;
        uint256 totalRoyalties;
        uint256[] royaltyAmounts;
        uint256 sellerRevenue;
    }

    function purchaseWithLiskToken() public {
        console.log("");
        console.log(Styles.h1("RWA Token Purchase Test with Royalties"));
        console.log(
            Styles.p("Testing purchase flow with royalty distribution")
        );
        console.log("");

        uint256 currentProtocolFee = marketplace.protocolFee();
        TestSetup memory setup = setupTestData();

        // Setup phase
        vm.startPrank(admin);
        rwaToken.safeTransferFrom(
            admin,
            seller,
            setup.tokenId,
            setup.listingAmount,
            ""
        );
        marketplaceController.setAcceptedToken(
            address(marketplace),
            LISK_TOKEN,
            true
        );
        vm.stopPrank();

        // Create listing
        vm.startPrank(seller);
        rwaToken.setApprovalForAll(address(marketplace), true);
        uint256 listingId = marketplace.createListing(
            setup.tokenId,
            setup.listingAmount,
            setup.listingPrice,
            LISK_TOKEN
        );
        vm.stopPrank();

        // Fund buyer with sufficient LISK tokens
        vm.startPrank(LISK_WHALE);
        uint256 requiredBalance = setup.purchaseAmount * setup.listingPrice;
        // Add extra buffer for fees
        uint256 bufferAmount = (requiredBalance * 1000) / 10000; // 10% buffer
        IERC20(LISK_TOKEN).transfer(buyer, requiredBalance + bufferAmount);
        vm.stopPrank();

        // Execute purchase
        vm.startPrank(buyer);
        IERC20(LISK_TOKEN).approve(address(marketplace), type(uint256).max);
        marketplace.buyTokens(listingId, setup.purchaseAmount);
        vm.stopPrank();

        // Verify balances and ownership
        assertEq(
            rwaToken.balanceOf(buyer, setup.tokenId),
            setup.purchaseAmount,
            "Buyer should receive correct RWA tokens"
        );
        assertEq(
            IERC20(LISK_TOKEN).balanceOf(address(marketplace)),
            0,
            "Marketplace should not hold LISK tokens"
        );
    }

    function setupTestData() internal returns (TestSetup memory setup) {
        setup.royaltyRecipients = new address[](2);
        setup.royaltyRecipients[0] = makeAddr("royalty1");
        setup.royaltyRecipients[1] = makeAddr("royalty2");

        setup.royaltyShares = new uint256[](2);
        setup.royaltyShares[0] = 500; // 5%
        setup.royaltyShares[1] = 300; // 3%

        vm.startPrank(admin);
        setup.tokenId = rwaToken.mint(
            INITIAL_SUPPLY,
            "ipfs://metadata",
            setup.royaltyRecipients,
            setup.royaltyShares
        );
        vm.stopPrank();

        setup.listingAmount = INITIAL_SUPPLY / 4;
        setup.listingPrice = 1 ether; // More reasonable price
        setup.purchaseAmount = setup.listingAmount / 2;

        return setup;
    }

    function test_MarketplaceController_PauseUnpause() public {
        console.log(Styles.h1("Marketplace Controller: Pause/Unpause Tests"));

        // Start as admin
        vm.startPrank(admin);

        // Grant pause role to admin for testing
        marketplaceController.grantRole(
            marketplaceController.PAUSE_CONTROLLER_ROLE(),
            admin
        );

        // Test pause
        marketplaceController.pauseMarketplace(address(marketplace));
        assertTrue(marketplace.paused(), "Marketplace should be paused");

        // Test unpause
        marketplaceController.unpauseMarketplace(address(marketplace));
        assertFalse(marketplace.paused(), "Marketplace should be unpaused");

        vm.stopPrank();
    }

    function test_BatchBuyTokens_MultipleListings() public {
        // Setup multiple listings
        TestSetup memory setup = setupTestData();
        uint256[] memory listingIds = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);

        // Create multiple listings with USDT as payment token (1 USDT per token)
        vm.startPrank(admin);
        marketplaceController.setAcceptedToken(
            address(marketplace),
            address(USDT),
            true
        );
        vm.stopPrank();

        for (uint256 i = 0; i < 3; i++) {
            listingIds[i] = _createListing(setup.tokenId, 10, 1000000); // 1 USDT (6 decimals)
            amounts[i] = 3;
        }

        // Setup buyer with USDT
        vm.startPrank(LISK_WHALE);
        IERC20(LISK_TOKEN).transfer(buyer, 1000 * 10 ** 6); // Transfer 1000 USDT to buyer
        vm.stopPrank();

        // Execute batch purchase
        vm.startPrank(buyer);
        IERC20(LISK_TOKEN).approve(address(marketplace), type(uint256).max);
        USDT.approve(address(marketplace), type(uint256).max);
        uint256 USDT_BALANCE = IERC20(LISK_TOKEN).balanceOf(buyer);
        console.log("USDT Balance:", USDT_BALANCE);
        marketplace.batchBuyTokens(listingIds, amounts);
        vm.stopPrank();

        // Verify results
        assertEq(
            rwaToken.balanceOf(buyer, setup.tokenId),
            9,
            "Buyer should have received 9 tokens total"
        );

        // Verify listing states
        for (uint256 i = 0; i < 3; i++) {
            (, , , , , bool active) = marketplace.listings(listingIds[i]);
            assertTrue(active, "Listing should still be active");

            // Verify remaining amounts
            (, , uint256 remainingAmount, , , ) = marketplace.listings(
                listingIds[i]
            );
            assertEq(
                remainingAmount,
                7,
                "Listing should have 7 tokens remaining"
            );
        }
    }

    function test_RevertWhen_BatchBuyTokens_ArrayMismatch() public {
        uint256[] memory listingIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](3);

        vm.expectRevert(Marketplace.ArrayLengthMismatch.selector);
        marketplace.batchBuyTokens(listingIds, amounts);
    }

    function test_RevertWhen_BatchBuyTokens_ExceedsMaxLength() public {
        uint256[] memory listingIds = new uint256[](11); // MAX_ARRAY_LENGTH is 10
        uint256[] memory amounts = new uint256[](11);

        vm.expectRevert(Marketplace.ArrayLengthTooLong.selector);
        marketplace.batchBuyTokens(listingIds, amounts);
    }

    function test_MarketplaceController_AccessControl() public {
        console.log(Styles.h1("Marketplace Controller: Access Control Tests"));

        address unauthorized = makeAddr("unauthorized");

        vm.startPrank(unauthorized);

        // Test unauthorized pause
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                unauthorized,
                marketplaceController.PAUSE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.pauseMarketplace(address(marketplace));

        // Test unauthorized protocol fee update
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                unauthorized,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setProtocolFee(address(marketplace), 300);

        // Test unauthorized token acceptance update
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                unauthorized,
                marketplaceController.MARKETPLACE_CONTROLLER_ROLE()
            )
        );
        marketplaceController.setAcceptedToken(
            address(marketplace),
            address(0x1),
            true
        );

        vm.stopPrank();
    }

    // Helper function for creating and minting a token
    function _createAndMintToken() internal returns (uint256) {
        vm.startPrank(admin);
        uint256 tokenId = rwaToken.mint(
            100,
            "ipfs://test",
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();
        return tokenId;
    }

    // Helper function for creating a listing
    function _createListing(
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerToken
    ) internal returns (uint256) {
        vm.startPrank(admin);
        rwaToken.setApprovalForAll(address(marketplace), true);
        uint256 listingId = marketplace.createListing(
            tokenId,
            amount,
            pricePerToken,
            address(USDT)
        );
        vm.stopPrank();
        return listingId;
    }

    function test_EmergencyWithdraw() public {
        console.log(Styles.h1("Emergency Withdraw Tests"));
        uint256 tokenId = _createAndMintToken();
        uint256 listingId = _createListing(tokenId, 100, 1 ether);

        vm.startPrank(admin);
        marketplaceController.pauseMarketplace(address(marketplace));
        uint256 balanceBefore = rwaToken.balanceOf(admin, tokenId);
        uint256 marketplaceBalanceBefore = rwaToken.balanceOf(
            address(marketplace),
            tokenId
        );
        marketplaceController.emergencyWithdraw(
            address(marketplace),
            address(rwaToken),
            tokenId,
            10,
            admin
        );
        assertEq(
            rwaToken.balanceOf(admin, tokenId),
            balanceBefore + 10,
            "Admin should receive 10 tokens"
        );
        assertEq(
            rwaToken.balanceOf(address(marketplace), tokenId),
            marketplaceBalanceBefore - 10,
            "Marketplace should receive 10 tokens"
        );
        vm.stopPrank();
    }

    function test_RevertWhen_EmergencyWithdraw_NotPaused() public {
        console.log(Styles.h1("Emergency Withdraw Tests"));
        uint256 tokenId = _createAndMintToken();
        uint256 listingId = _createListing(tokenId, 100, 1 ether);

        vm.startPrank(admin);
        vm.expectRevert(Marketplace.EmergencyStopActive.selector);
        marketplaceController.emergencyWithdraw(
            address(marketplace),
            address(rwaToken),
            tokenId,
            10,
            admin
        );
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedPauseUnpause() public {
        console.log(Styles.h1("Unauthorized Pause/Unpause Tests"));

        address unauthorized = makeAddr("unauthorized");

        vm.startPrank(unauthorized);

        // Test unauthorized pause
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                unauthorized
            )
        );
        marketplace.pause();

        // Test unauthorized unpause
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                unauthorized
            )
        );
        marketplace.unpause();

        vm.stopPrank();
    }
}
