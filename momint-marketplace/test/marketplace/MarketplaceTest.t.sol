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
    uint256 constant FORK_BLOCK_NUMBER = 1234567; // We'll need the actual block number
    address constant LISK_TOKEN = 0xac485391EB2d7D88253a7F1eF18C37f4242D1A24;
    address constant USDT = 0x05D032ac25d322df992303dCa074EE7392C117b9;
    address LISK_WHALE = 0xC8CFB2922414DcD4Eb61380A8b59bB8166c225f1; // We'll need a whale address
    // Test addresses
    address public admin = 0x8907C46657c18C7E12efCe6aE7E820cC12Ee2d61;
    address public seller = 0xC20e318fe1830DE929bB8eE57F6209a89F0ab00F;
    address public buyer = 0xC287129dcB73bd7065C3fB97f7FB7981f59166EB;
    address public feeRecipient = 0x3031B7445F27D68d19B8A3aAeDE9F036945D9c60;
    address public pauseController;

    function setUp() public {
        // Create fork
        vm.createSelectFork(LISK_RPC_URL, FORK_BLOCK_NUMBER);

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

    function test_case1() public {
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

    function marketplaceInitialization() public {
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
            StdStyle.green(marketplace.acceptedTokens(USDT))
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
            StdStyle.green(marketplace.acceptedTokens(USDT))
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

    function purchaseWithLiskToken() public {
        console.log("");
        console.log(Styles.h1("RWA Token Purchase Test with Royalties"));
        console.log(
            Styles.p("Testing purchase flow with royalty distribution")
        );
        console.log("");

        // Get initial protocol fee from contract
        uint256 currentProtocolFee = marketplace.protocolFee();
        console.log(Styles.h2("Protocol Fee Configuration"));
        console.log(
            Styles.p("Current Protocol Fee:"),
            StdStyle.green(
                string.concat(vm.toString(currentProtocolFee / 100), "%")
            )
        );

        // Setup royalty recipients with actual contract values
        vm.startPrank(admin);
        address[] memory royaltyRecipients = new address[](2);
        royaltyRecipients[0] = makeAddr("royalty1");
        royaltyRecipients[1] = makeAddr("royalty2");
        uint256[] memory royaltyShares = new uint256[](2);
        royaltyShares[0] = 500; // 5%
        royaltyShares[1] = 300; // 3%

        // Mint token with royalties
        uint256 tokenId = rwaToken.mint(
            INITIAL_SUPPLY,
            "ipfs://metadata",
            royaltyRecipients,
            royaltyShares
        );

        // Get actual token info from contract
        (
            uint256 actualSupply,
            string memory actualUri,
            address[] memory actualRecipients,
            uint256[] memory actualShares
        ) = rwaToken.getAssetInfo(tokenId);

        console.log(Styles.h2("Token Configuration"));
        console.log(Styles.p("Token ID:"), StdStyle.green(tokenId));
        console.log(Styles.p("Total Supply:"), StdStyle.green(actualSupply));
        console.log(Styles.p("Token URI:"), StdStyle.green(actualUri));
        console.log("");
        console.log(Styles.h2("Royalty Structure"));
        for (uint i = 0; i < actualRecipients.length; i++) {
            console.log(
                Styles.p(string.concat("Recipient ", vm.toString(i + 1), ":")),
                StdStyle.green(actualRecipients[i])
            );
            console.log(
                Styles.p(string.concat("Share ", vm.toString(i + 1), ":")),
                StdStyle.green(
                    string.concat(vm.toString(actualShares[i] / 100), "%")
                )
            );
        }

        // Transfer tokens to seller
        uint256 sellerAmount = actualSupply / 2;
        rwaToken.safeTransferFrom(admin, seller, tokenId, sellerAmount, "");
        console.log("");
        console.log(Styles.h2("Token Distribution"));
        console.log(
            Styles.p("Tokens Transferred to Seller:"),
            StdStyle.green(sellerAmount)
        );
        console.log(
            Styles.p("Seller Balance:"),
            StdStyle.green(rwaToken.balanceOf(seller, tokenId))
        );

        // Whitelist payment token
        marketplaceController.setAcceptedToken(
            address(marketplace),
            LISK_TOKEN,
            true
        );
        vm.stopPrank();

        // Create listing
        vm.startPrank(seller);
        rwaToken.setApprovalForAll(address(marketplace), true);
        uint256 listingAmount = sellerAmount / 2;
        uint256 listingPrice = 10 ether; // 10 LISK per token

        uint256 listingId = marketplace.createListing(
            tokenId,
            listingAmount,
            listingPrice,
            LISK_TOKEN
        );

        // Get actual listing details from contract
        (
            address actualSeller,
            uint256 actualTokenId,
            uint256 actualAmount,
            uint256 actualPrice,
            address actualPaymentToken,
            bool isActive
        ) = marketplace.listings(listingId);

        console.log("");
        console.log(Styles.h2("Listing Details"));
        console.log(Styles.p("Listing ID:"), StdStyle.green(listingId));
        console.log(Styles.p("Seller:"), StdStyle.green(actualSeller));
        console.log(Styles.p("Amount Listed:"), StdStyle.green(actualAmount));
        console.log(
            Styles.p("Price Per Token:"),
            StdStyle.green(
                string.concat(vm.toString(actualPrice / 1 ether), " LISK")
            )
        );
        vm.stopPrank();

        // Fund buyer
        vm.startPrank(LISK_WHALE);
        uint256 purchaseAmount = actualAmount / 2;
        uint256 requiredBalance = purchaseAmount * actualPrice;
        IERC20(LISK_TOKEN).transfer(buyer, requiredBalance * 2); // Extra for safety
        vm.stopPrank();

        // Execute purchase
        vm.startPrank(buyer);
        IERC20(LISK_TOKEN).approve(address(marketplace), type(uint256).max);

        uint256 totalCost = purchaseAmount * listingPrice;
        uint256 protocolFeeAmount = (totalCost * currentProtocolFee) / 10000;
        uint256[] memory royaltyAmounts = new uint256[](
            actualRecipients.length
        );
        uint256 totalRoyalties = 0;

        console.log("");
        console.log(Styles.h2("Transaction Details"));
        console.log(
            Styles.p("Purchase Amount:"),
            StdStyle.green(
                string.concat(vm.toString(purchaseAmount), " tokens")
            )
        );
        console.log(
            Styles.p("Price Per Token:"),
            StdStyle.green(
                string.concat(vm.toString(listingPrice / 1 ether), " LISK")
            )
        );
        console.log(
            Styles.p("Total Cost:"),
            StdStyle.green(
                string.concat(vm.toString(totalCost / 1 ether), " LISK")
            )
        );
        console.log("");

        // Calculate royalties
        for (uint i = 0; i < actualRecipients.length; i++) {
            royaltyAmounts[i] = (totalCost * actualShares[i]) / 10000; // 10000 basis points = 100%
            totalRoyalties += royaltyAmounts[i];

            console.log(
                Styles.p(
                    string.concat(
                        "Royalty ",
                        vm.toString(i + 1),
                        " (",
                        vm.toString(actualShares[i] / 100),
                        "%): "
                    )
                ),
                StdStyle.green(
                    string.concat(
                        vm.toString(royaltyAmounts[i] / 1 ether),
                        " LISK"
                    )
                )
            );
        }

        // Calculate protocol fee
        console.log(
            Styles.p(
                string.concat(
                    "Protocol Fee (",
                    vm.toString(currentProtocolFee / 100),
                    "%): "
                )
            ),
            StdStyle.green(
                string.concat(vm.toString(protocolFeeAmount / 1 ether), " LISK")
            )
        );

        uint256 sellerRevenue = totalCost - protocolFeeAmount - totalRoyalties;
        console.log(
            Styles.p("Seller Revenue: "),
            StdStyle.green(
                string.concat(vm.toString(sellerRevenue / 1 ether), " LISK")
            )
        );

        // Execute purchase
        marketplace.buyTokens(listingId, purchaseAmount);

        // Log final balances with proper decimal handling
        console.log("");
        console.log(Styles.h2("Final Balances"));

        // Seller
        uint256 finalSellerBalance = IERC20(LISK_TOKEN).balanceOf(seller);
        console.log(
            Styles.p("Seller LISK Balance:"),
            StdStyle.green(
                string.concat(
                    vm.toString(finalSellerBalance / 1 ether),
                    " LISK"
                )
            )
        );

        // Protocol Fee Recipient
        uint256 finalFeeRecipientBalance = IERC20(LISK_TOKEN).balanceOf(
            marketplace.feeRecipient()
        );
        console.log(
            Styles.p("Protocol Fee Recipient Balance:"),
            StdStyle.green(
                string.concat(
                    vm.toString(finalFeeRecipientBalance / 1 ether),
                    " LISK"
                )
            )
        );

        // Royalty Recipients
        for (uint i = 0; i < actualRecipients.length; i++) {
            uint256 recipientBalance = IERC20(LISK_TOKEN).balanceOf(
                actualRecipients[i]
            );
            console.log(
                Styles.p(
                    string.concat(
                        "Royalty Recipient ",
                        vm.toString(i + 1),
                        " Balance:"
                    )
                ),
                StdStyle.green(
                    string.concat(
                        vm.toString(recipientBalance / 1 ether),
                        " LISK"
                    )
                )
            );
        }

        // Buyer's token balance
        uint256 buyerTokenBalance = rwaToken.balanceOf(buyer, tokenId);
        console.log(
            Styles.p("Buyer RWA Token Balance:"),
            StdStyle.green(
                string.concat(vm.toString(buyerTokenBalance), " tokens")
            )
        );

        vm.stopPrank();
    }

    // Helper function to log token balances
    function logBalance(
        string memory label,
        address account,
        address token
    ) internal view {
        uint256 balance = IERC20(token).balanceOf(account);
        console.log(
            Styles.p(label),
            StdStyle.green(
                string.concat(vm.toString(balance / 1 ether), " LISK")
            )
        );
    }
}
