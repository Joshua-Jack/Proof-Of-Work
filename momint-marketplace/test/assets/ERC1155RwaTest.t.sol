// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../../src/assets/ERC1155RWA.sol";
import {Styles} from "../utils/Styles.sol";

/// @title ERC1155RWA Test Suite
/// @notice Test suite for the ERC1155RWA contract
/// @dev Tests all major functionality including minting, royalties, and access control
contract ERC1155RwaTest is Test {
    ERC1155RWA public implementation;
    TransparentUpgradeableProxy public proxy;
    ProxyAdmin public proxyAdmin;
    ERC1155RWA public token;
    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    // Test addresses
    address public admin;
    address public minter;
    address public pauser;
    address public royaltyManager;
    address public user1;
    address public user2;
    address public zeroAddress = address(0);

    // Test constants
    string constant BASE_URI = "ipfs.io/";
    string constant METADATA_URI = "ipfs://QmTest/1";
    string constant METADATA_URI_2 = "ipfs://QmTest/2";
    uint256 constant INITIAL_SUPPLY = 100;
    uint256 constant ROYALTY_BASIS = 1000; // 10%

    // ERC1155RWATest.t.sol
    function setUp() public {
        // Generate test addresses
        minter = makeAddr("minter");
        pauser = makeAddr("pauser");
        royaltyManager = makeAddr("royaltyManager");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        admin = address(this);

        // Deploy implementation
        implementation = new ERC1155RWA();

        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin(admin);

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            ERC1155RWA.initialize.selector,
            admin,
            BASE_URI
        );

        // Deploy proxy
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        // Create token instance
        token = ERC1155RWA(address(proxy));

        // Grant roles
        vm.startPrank(address(this));
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.PAUSER_ROLE(), pauser);
        token.grantRole(token.ROYALTY_ROLE(), royaltyManager);
        token.grantRole(token.ROYALTY_ROLE(), minter);
        vm.stopPrank();
    }

    function test_case1() public {
        console.log(Styles.h1("RWA Token Test"));
        initialization();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case2() public {
        console.log(Styles.h1("RWA Token Test: Basic Mint"));
        basicMint();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case3() public {
        console.log(Styles.h1("RWA Token Test: Mint With Royalties"));
        mintWithRoyalties();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case4() public {
        console.log(Styles.h1("RWA Token Test: Batch Mint"));
        batchMint();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case5() public {
        console.log(Styles.h1("RWA Token Test: Royalty Calculations"));
        royaltyCalculations();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case6() public {
        console.log(Styles.h1("RWA Token Test: Update Metadata URI"));
        updateMetadataURI();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    function test_case7() public {
        console.log(Styles.h1("RWA Token Test: Update Royalties"));
        updateRoyalties();
        console.log("");
        console.log(
            Styles.h2(
                "End of RWA Token Test ----------------------------------------"
            )
        );
    }

    // Add a separate test for initialization failure
    function testFailDoubleInitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");
        token.initialize(admin, BASE_URI);
    }

    /// @notice Test contract initialization
    function initialization() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(token.hasRole(token.MINTER_ROLE(), address(this)));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), address(this)));
        assertTrue(token.hasRole(token.ROYALTY_ROLE(), address(this)));
        assertEq(token.getCurrentTokenId(), 1);
    }

    /// @notice Test basic minting functionality
    function basicMint() public {
        console.log("");
        console.log(Styles.h2("Basic Minting Scenario"));
        console.log(
            Styles.p(
                "This test demonstrates the basic minting process of a new RWA token"
            )
        );
        console.log("");

        vm.startPrank(minter);
        console.log(
            Styles.p("Minting new token as authorized minter:"),
            StdStyle.green(minter)
        );

        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );

        // Get actual values from contract
        (uint256 supply, string memory uri, , ) = token.getAssetInfo(tokenId);

        console.log("");
        console.log(Styles.h2("Minted Token Details"));
        console.log(Styles.p("New Token ID:"), StdStyle.green(tokenId));
        console.log(Styles.p("Token Shares:"), StdStyle.green(supply));
        console.log(Styles.p("Token Metadata Location:"), StdStyle.green(uri));
        console.log("");
        console.log(
            Styles.p("Next Available Token ID:"),
            StdStyle.green(token.getCurrentTokenId())
        );
        console.log(
            Styles.p("Tokens Held by Minter:"),
            StdStyle.green(token.balanceOf(minter, tokenId))
        );

        vm.stopPrank();
        console.log("");
    }

    /// @notice Test minting with royalties
    function mintWithRoyalties() public {
        console.log("");
        console.log(Styles.h2("Minting Token with Royalty Configuration"));
        console.log(
            Styles.p(
                "This test demonstrates minting a token with multiple royalty recipients"
            )
        );
        console.log("");

        console.log(Styles.h2("Setting Up Royalty Structure"));
        console.log(
            Styles.p(
                "Configuring two recipients with different royalty shares:"
            )
        );
        console.log(Styles.p("- First Recipient (5%):"), StdStyle.green(user1));
        console.log(
            Styles.p("- Second Recipient (3%):"),
            StdStyle.green(user2)
        );
        console.log("");

        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 500; // 5%
        shares[1] = 300; // 3%

        vm.startPrank(minter);
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            recipients,
            shares
        );

        // Get actual values from contract
        (
            uint256 supply,
            string memory uri,
            address[] memory actualRecipients,
            uint256[] memory actualShares
        ) = token.getAssetInfo(tokenId);

        console.log(Styles.h2("Created Token Information"));
        console.log(Styles.p("Token ID:"), StdStyle.green(tokenId));
        console.log(Styles.p("Initial Shares:"), StdStyle.green(supply));
        console.log(Styles.p("Metadata Location:"), StdStyle.green(uri));

        console.log("");
        console.log(Styles.h2("Configured Royalty Structure"));
        for (uint i = 0; i < actualRecipients.length; i++) {
            console.log(
                Styles.p(
                    string.concat("Recipient ", vm.toString(i + 1), " Address:")
                ),
                StdStyle.green(actualRecipients[i])
            );
            console.log(
                Styles.p(
                    string.concat("Recipient ", vm.toString(i + 1), " Share:")
                ),
                StdStyle.green(
                    string.concat(vm.toString(actualShares[i] / 100), "%")
                )
            );
        }

        // Example sale calculation
        uint256 salePrice = 1000 ether;
        (address[] memory royaltyRecipients, uint256[] memory amounts) = token
            .getRoyaltyDetails(tokenId, salePrice);

        console.log("");
        console.log(Styles.h2("Example Royalty Distribution"));
        console.log(
            Styles.p("For a sale price of:"),
            StdStyle.green(
                string.concat(vm.toString(salePrice / 1 ether), " ETH")
            )
        );
        for (uint i = 0; i < royaltyRecipients.length; i++) {
            console.log(
                Styles.p(
                    string.concat(
                        "Recipient ",
                        vm.toString(i + 1),
                        " would receive:"
                    )
                ),
                StdStyle.green(
                    string.concat(vm.toString(amounts[i] / 1 ether), " ETH")
                )
            );
        }

        vm.stopPrank();
        console.log("");
    }

    /// @notice Test batch minting functionality with valid inputs
    function batchMint() public {
        console.log("");
        console.log(Styles.h2("Batch Minting Scenario"));
        console.log(
            Styles.p(
                "This test demonstrates minting multiple tokens in a single transaction"
            )
        );
        console.log(
            Styles.p(
                "Creating two tokens with different Shares amounts and royalty configurations"
            )
        );
        console.log("");

        console.log(Styles.h2("Token Configuration"));
        console.log(Styles.p("Token 1:"));
        console.log(Styles.p("- Shares: 100"));
        console.log(Styles.p("- Royalty: 5% to"), StdStyle.green(user1));
        console.log("");
        console.log(Styles.p("Token 2:"));
        console.log(Styles.p("- Shares: 200"));
        console.log(Styles.p("- Royalty: 3% to"), StdStyle.green(user2));
        console.log("");

        uint256[] memory supplies = new uint256[](2);
        supplies[0] = 100;
        supplies[1] = 200;

        string[] memory uris = new string[](2);
        uris[0] = METADATA_URI;
        uris[1] = METADATA_URI_2;

        address[][] memory royaltyRecipients = new address[][](2);
        uint256[][] memory royaltyShares = new uint256[][](2);

        // First token royalties
        royaltyRecipients[0] = new address[](1);
        royaltyRecipients[0][0] = user1;
        royaltyShares[0] = new uint256[](1);
        royaltyShares[0][0] = 500; // 5%

        // Second token royalties
        royaltyRecipients[1] = new address[](1);
        royaltyRecipients[1][0] = user2;
        royaltyShares[1] = new uint256[](1);
        royaltyShares[1][0] = 300; // 3%

        // Store initial token ID for assertions
        uint256 initialTokenId = token.getCurrentTokenId();

        vm.startPrank(minter);
        uint256[] memory tokenIds = token.batchMint(
            supplies,
            uris,
            royaltyRecipients,
            royaltyShares
        );

        // Assert correct number of tokens minted
        assertEq(tokenIds.length, 2, "Incorrect number of tokens minted");

        // Assert token IDs are sequential
        assertEq(tokenIds[0], initialTokenId, "First token ID incorrect");
        assertEq(tokenIds[1], initialTokenId + 1, "Second token ID incorrect");

        // Assert token supplies
        assertEq(
            token.totalSupply(tokenIds[0]),
            supplies[0],
            "Token 1 supply incorrect"
        );
        assertEq(
            token.totalSupply(tokenIds[1]),
            supplies[1],
            "Token 2 supply incorrect"
        );

        // Assert URIs
        assertEq(token.uri(tokenIds[0]), uris[0], "Token 1 URI incorrect");
        assertEq(token.uri(tokenIds[1]), uris[1], "Token 2 URI incorrect");

        // Assert royalty configurations
        (address[] memory recipients1, uint256[] memory shares1) = token
            .getRoyaltyDetails(tokenIds[0], 10000);
        assertEq(recipients1.length, 1, "Token 1 recipient count incorrect");
        assertEq(recipients1[0], user1, "Token 1 recipient incorrect");
        assertEq(shares1[0], 500, "Token 1 royalty share incorrect");

        (address[] memory recipients2, uint256[] memory shares2) = token
            .getRoyaltyDetails(tokenIds[1], 10000);
        assertEq(recipients2.length, 1, "Token 2 recipient count incorrect");
        assertEq(recipients2[0], user2, "Token 2 recipient incorrect");
        assertEq(shares2[0], 300, "Token 2 royalty share incorrect");

        // Assert balances
        assertEq(
            token.balanceOf(minter, tokenIds[0]),
            supplies[0],
            "Minter balance for token 1 incorrect"
        );
        assertEq(
            token.balanceOf(minter, tokenIds[1]),
            supplies[1],
            "Minter balance for token 2 incorrect"
        );

        vm.stopPrank();
        console.log("");

        // Original console logging for visual verification
        console.log(Styles.h2("Minted Tokens Results"));
        for (uint i = 0; i < tokenIds.length; i++) {
            (
                uint256 supply,
                string memory uri,
                address[] memory recipients,
                uint256[] memory shares
            ) = token.getAssetInfo(tokenIds[i]);

            console.log("");
            console.log(Styles.p(string.concat("Token ", vm.toString(i + 1))));
            console.log(Styles.p("- ID:"), StdStyle.green(tokenIds[i]));
            console.log(Styles.p("- Shares:"), StdStyle.green(supply));
            console.log(Styles.p("- Metadata:"), StdStyle.green(uri));

            if (recipients.length > 0) {
                console.log(
                    Styles.p("- Royalty Recipient:"),
                    StdStyle.green(recipients[0])
                );
                console.log(
                    Styles.p("- Royalty Percentage:"),
                    StdStyle.green(
                        string.concat(vm.toString(shares[0] / 100), "%")
                    )
                );
            }
        }
    }

    function test_RevertWhen_BatchMintWithMismatchedArrayLengths() public {
        uint256[] memory supplies = new uint256[](2);
        supplies[0] = INITIAL_SUPPLY;
        supplies[1] = INITIAL_SUPPLY;

        string[] memory uris = new string[](1); // Mismatched length
        uris[0] = METADATA_URI;

        address[][] memory royaltyRecipients = new address[][](2);
        uint256[][] memory royaltyShares = new uint256[][](2);

        vm.startPrank(minter);
        vm.expectRevert("Array lengths must match");
        token.batchMint(supplies, uris, royaltyRecipients, royaltyShares);
        vm.stopPrank();
    }

    /// @notice Test royalty calculations
    function royaltyCalculations() public {
        console.log("");
        console.log(Styles.h2("Starting Royalty Calculations Test"));
        console.log("");

        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 500; // 5%
        shares[1] = 300; // 3%

        console.log(Styles.h2("Royalty Configuration"));
        console.log(Styles.p("Recipient 1:"), StdStyle.green(recipients[0]));
        console.log(
            Styles.p("Share 1:"),
            StdStyle.green(shares[0]),
            Styles.p("(5%)")
        );
        console.log(Styles.p("Recipient 2:"), StdStyle.green(recipients[1]));
        console.log(
            Styles.p("Share 2:"),
            StdStyle.green(shares[1]),
            Styles.p("(3%)")
        );
        console.log("");

        vm.prank(minter);
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            recipients,
            shares
        );

        uint256 salePrice = 10000;
        (address receiver, uint256 royaltyAmount) = token.royaltyInfo(
            tokenId,
            salePrice
        );

        console.log(Styles.h2("Royalty Calculation Results"));
        console.log(Styles.p("Sale Price:"), StdStyle.green(salePrice));
        console.log(Styles.p("Primary Receiver:"), StdStyle.green(receiver));
        console.log(
            Styles.p("Total Royalty Amount:"),
            StdStyle.green(royaltyAmount)
        );

        (address[] memory royaltyRecipients, uint256[] memory amounts) = token
            .getRoyaltyDetails(tokenId, salePrice);

        console.log("");
        console.log(Styles.h2("Individual Royalty Distributions"));
        for (uint i = 0; i < royaltyRecipients.length; i++) {
            console.log(
                Styles.p(string.concat("Recipient ", vm.toString(i + 1), ":")),
                StdStyle.green(royaltyRecipients[i])
            );
            console.log(
                Styles.p(string.concat("Amount ", vm.toString(i + 1), ":")),
                StdStyle.green(amounts[i])
            );
        }

        console.log("");
        console.log(
            Styles.h2("Royalty Calculations Test Completed Successfully")
        );
        console.log("");
    }

    /// @notice Test metadata URI updates
    function updateMetadataURI() public {
        console.log("");
        console.log(Styles.h2("Metadata URI Update Test"));
        console.log(
            Styles.p("This test demonstrates updating a token's metadata URI")
        );
        console.log("");

        // First mint a token
        vm.startPrank(minter);
        console.log(Styles.p("Initial URI:"), StdStyle.green(METADATA_URI));
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();

        string memory newUri = "ipfs://QmTest/updated";

        // Grant DEFAULT_ADMIN_ROLE to admin if not already granted
        if (!token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin)) {
            vm.prank(address(this));
            token.grantRole(token.DEFAULT_ADMIN_ROLE(), admin);
        }

        console.log("");
        console.log(Styles.p("Updating URI as admin:"), StdStyle.green(admin));
        console.log(Styles.p("New URI:"), StdStyle.green(newUri));

        vm.startPrank(admin);
        token.updateMetadataURI(tokenId, newUri);
        vm.stopPrank();

        string memory updatedUri = token.uri(tokenId);
        console.log("");
        console.log(Styles.p("Verification"));
        console.log(Styles.p("Updated URI:"), StdStyle.green(updatedUri));

        assertEq(updatedUri, newUri, "URI not updated correctly");
        console.log("");
        console.log(
            Styles.h2("Metadata URI Update Test Completed Successfully")
        );
        console.log("");
    }

    /// @notice Test updating royalties
    function updateRoyalties() public {
        console.log("");
        console.log(Styles.h2("Royalty Update Test"));
        console.log(
            Styles.p(
                "This test demonstrates updating royalty configuration for an existing token"
            )
        );
        console.log("");

        // First mint a token without royalties
        vm.startPrank(minter);
        console.log(Styles.h2("Step 1: Initial Token Creation"));
        console.log(Styles.p("Minting token without initial royalties"));

        uint256 initialTokenId = token.getCurrentTokenId();
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );

        vm.stopPrank();

        // Get initial state
        (
            uint256 initialSupply,
            string memory initialUri,
            address[] memory initialRecipients,
            uint256[] memory initialShares
        ) = token.getAssetInfo(tokenId);

        console.log(
            Styles.p("Initial Token ID:"),
            StdStyle.green(initialTokenId)
        );
        console.log(Styles.p("Token ID:"), StdStyle.green(tokenId));
        console.log(Styles.p("Initial Shares:"), StdStyle.green(initialSupply));
        console.log(Styles.p("Initial URI:"), StdStyle.green(initialUri));
        console.log(
            Styles.p("Initial Recipients:"),
            StdStyle.green(initialRecipients.length)
        );
        console.log("");

        // Setup new royalty configuration
        console.log(Styles.h2("Step 2: New Royalty Configuration"));
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = ROYALTY_BASIS; // Using constant instead of hardcoded value

        console.log(
            Styles.p("New Royalty Recipient:"),
            StdStyle.green(recipients[0])
        );
        console.log(
            Styles.p("New Royalty Share:"),
            StdStyle.green(string.concat(vm.toString(ROYALTY_BASIS / 100), "%"))
        );
        console.log("");

        // Update royalties
        console.log(Styles.h2("Step 3: Updating Royalties"));
        console.log(
            Styles.p("Updating as royalty manager:"),
            StdStyle.green(royaltyManager)
        );

        vm.startPrank(royaltyManager);
        token.setRoyalties(tokenId, recipients, shares);
        vm.stopPrank();

        // Verify the update with actual contract values
        (
            uint256 updatedSupply,
            string memory updatedUri,
            address[] memory updatedRecipients,
            uint256[] memory updatedShares
        ) = token.getAssetInfo(tokenId);

        console.log("");
        console.log(Styles.h2("Step 4: Verification"));
        console.log(Styles.p("Current Shares:"), StdStyle.green(updatedSupply));
        console.log(Styles.p("Current URI:"), StdStyle.green(updatedUri));
        console.log(
            Styles.p("Updated Recipients Count:"),
            StdStyle.green(updatedRecipients.length)
        );

        for (uint i = 0; i < updatedRecipients.length; i++) {
            console.log(
                Styles.p(string.concat("Recipient ", vm.toString(i + 1), ":")),
                StdStyle.green(updatedRecipients[i])
            );
            console.log(
                Styles.p(string.concat("Share ", vm.toString(i + 1), ":")),
                StdStyle.green(
                    string.concat(vm.toString(updatedShares[i] / 100), "%")
                )
            );
        }

        // Example royalty calculation with actual values
        uint256 salePrice = 100 ether;
        (address[] memory royaltyRecipients, uint256[] memory amounts) = token
            .getRoyaltyDetails(tokenId, salePrice);

        console.log("");
        console.log(Styles.h2("Example Royalty Calculation"));
        console.log(
            Styles.p("For sale price of:"),
            StdStyle.green(
                string.concat(vm.toString(salePrice / 1 ether), " ETH")
            )
        );
        for (uint i = 0; i < royaltyRecipients.length; i++) {
            console.log(
                Styles.p(
                    string.concat(
                        "Recipient ",
                        vm.toString(i + 1),
                        " would receive:"
                    )
                ),
                StdStyle.green(
                    string.concat(vm.toString(amounts[i] / 1 ether), " ETH")
                )
            );
        }

        // Assertions with actual contract values
        assertEq(
            updatedRecipients[0],
            recipients[0],
            "Recipient not updated correctly"
        );
        assertEq(
            updatedShares[0],
            ROYALTY_BASIS,
            "Share not updated correctly"
        );

        console.log("");
        console.log(Styles.h2("Royalty Update Test Completed Successfully"));
        console.log("");
    }

    /// @notice Test pause functionality
    function test_PauseUnpause() public {
        vm.prank(pauser);
        token.pause();
        assertTrue(token.paused());

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(minter);
        token.mint(100, "ipfs://QmTest/1", new address[](0), new uint256[](0));

        vm.prank(pauser);
        token.unpause();
        assertFalse(token.paused());
    }

    /// @notice Test failure cases
    function test_RevertWhen_MetadataURIEmpty() public {
        vm.prank(minter);
        vm.expectRevert("Metadata URI cannot be empty");
        token.mint(INITIAL_SUPPLY, "", new address[](0), new uint256[](0));
    }

    function test_RevertWhen_UnauthorizedMint() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                user1,
                token.MINTER_ROLE()
            )
        );
        token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();
    }

    function test_RevertWhen_ExcessiveRoyalties() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10001; // More than 100%

        vm.prank(minter);
        vm.expectRevert("Total royalties cannot exceed 100%");
        token.mint(INITIAL_SUPPLY, METADATA_URI, recipients, shares);
    }

    function test_RevertWhen_ZeroAddressRoyaltyRecipient() public {
        address[] memory recipients = new address[](1);
        recipients[0] = zeroAddress;
        uint256[] memory shares = new uint256[](1);
        shares[0] = ROYALTY_BASIS;

        vm.prank(minter);
        vm.expectRevert("Invalid recipient");
        token.mint(INITIAL_SUPPLY, METADATA_URI, recipients, shares);
    }

    /// @notice Test getOwnerTokens functionality
    function test_GetOwnerTokens() public {
        vm.startPrank(minter);
        // Mint multiple tokens
        uint256 tokenId1 = token.mint(
            100,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        uint256 tokenId2 = token.mint(
            200,
            METADATA_URI_2,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();

        (uint256[] memory tokenIds, uint256[] memory balances) = token
            .getOwnerTokens(minter);

        assertEq(tokenIds.length, 2);
        assertEq(tokenIds[0], tokenId1);
        assertEq(tokenIds[1], tokenId2);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }

    /// @notice Test getAssetInfo functionality
    function test_GetAssetInfo() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1000; // 10%

        vm.startPrank(minter);
        uint256 tokenId = token.mint(100, METADATA_URI, recipients, shares);
        vm.stopPrank();

        (
            uint256 totalSupply,
            string memory metadataURI,
            address[] memory royaltyRecipients,
            uint256[] memory royaltyShares
        ) = token.getAssetInfo(tokenId);

        assertEq(totalSupply, 100);
        assertEq(metadataURI, METADATA_URI);
        assertEq(royaltyRecipients[0], user1);
        assertEq(royaltyShares[0], 1000);
    }

    /// @notice Test token URI functionality
    function test_TokenURI() public {
        vm.startPrank(minter);
        uint256 tokenId = token.mint(
            100,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();

        assertEq(token.uri(tokenId), METADATA_URI);
    }

    /// @notice Test non-existent token queries
    function test_RevertOnNonexistentToken() public {
        vm.expectRevert("URI query for nonexistent token");
        token.uri(999);

        vm.expectRevert("Token does not exist");
        token.getAssetInfo(999);
    }
}
