// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../../src/assets/ERC1155RWA.sol";

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

    // Add a separate test for initialization failure
    function testFailDoubleInitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");
        token.initialize(admin, BASE_URI);
    }

    /// @notice Test contract initialization
    function test_Initialization() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(token.hasRole(token.MINTER_ROLE(), address(this)));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), address(this)));
        assertTrue(token.hasRole(token.ROYALTY_ROLE(), address(this)));
        assertEq(token.getCurrentTokenId(), 0);
    }

    /// @notice Test basic minting functionality
    function test_BasicMint() public {
        vm.startPrank(minter);
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();

        assertEq(tokenId, 0);
        assertEq(token.getCurrentTokenId(), 1);
        assertEq(token.balanceOf(minter, tokenId), INITIAL_SUPPLY);
    }

    /// @notice Test minting with royalties
    function test_MintWithRoyalties() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = ROYALTY_BASIS;

        vm.startPrank(minter);
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            recipients,
            shares
        );
        vm.stopPrank();

        (
            uint256 supply,
            string memory uri,
            address[] memory royaltyRecipients,
            uint256[] memory royaltyShares
        ) = token.getAssetInfo(tokenId);

        assertEq(supply, INITIAL_SUPPLY);
        assertEq(uri, METADATA_URI);
        assertEq(royaltyRecipients[0], user1);
        assertEq(royaltyShares[0], ROYALTY_BASIS);
    }

    /// @notice Test batch minting functionality with valid inputs
    function test_BatchMint() public {
        // Setup test data
        uint256[] memory supplies = new uint256[](2);
        supplies[0] = INITIAL_SUPPLY;
        supplies[1] = INITIAL_SUPPLY * 2;

        string[] memory uris = new string[](2);
        uris[0] = METADATA_URI;
        uris[1] = METADATA_URI_2; // Different editions can have different metadata

        address[][] memory royaltyRecipients = new address[][](2);
        royaltyRecipients[0] = new address[](1);
        royaltyRecipients[0][0] = user1;
        royaltyRecipients[1] = new address[](1);
        royaltyRecipients[1][0] = user2;

        uint256[][] memory royaltyShares = new uint256[][](2);
        royaltyShares[0] = new uint256[](1);
        royaltyShares[0][0] = ROYALTY_BASIS;
        royaltyShares[1] = new uint256[](1);
        royaltyShares[1][0] = ROYALTY_BASIS;

        // Execute batch mint
        vm.startPrank(minter);
        uint256[] memory tokenIds = token.batchMint(
            supplies,
            uris,
            royaltyRecipients,
            royaltyShares
        );
        vm.stopPrank();

        // Verify results
        assertEq(tokenIds.length, 2);
        assertEq(token.balanceOf(minter, tokenIds[0]), supplies[0]);
        assertEq(token.balanceOf(minter, tokenIds[1]), supplies[1]);

        // Verify metadata and royalties for each token
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (
                uint256 supply,
                string memory uri,
                address[] memory recipients,
                uint256[] memory shares
            ) = token.getAssetInfo(tokenIds[i]);

            assertEq(supply, supplies[i]);
            assertEq(uri, uris[i]);
            assertEq(recipients[0], royaltyRecipients[i][0]);
            assertEq(shares[0], royaltyShares[i][0]);
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
    function test_RoyaltyCalculations() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 500; // 5%
        shares[1] = 300; // 3%

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

        assertEq(receiver, user1);
        assertEq(royaltyAmount, 800); // 8% of 10000

        (address[] memory royaltyRecipients, uint256[] memory amounts) = token
            .getRoyaltyDetails(tokenId, salePrice);

        assertEq(royaltyRecipients.length, 2);
        assertEq(amounts[0], 500); // 5% of 10000
        assertEq(amounts[1], 300); // 3% of 10000
    }

    /// @notice Test metadata URI updates
    function test_UpdateMetadataURI() public {
        vm.prank(minter);
        uint256 tokenId = token.mint(
            INITIAL_SUPPLY,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );

        string memory newUri = "ipfs://QmTest/updated";
        vm.prank(admin);
        token.updateMetadataURI(tokenId, newUri);

        assertEq(token.uri(tokenId), newUri);
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

    /// @notice Test royalty calculations with multiple recipients
    function test_MultipleRoyaltyRecipients() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 500; // 5%
        shares[1] = 300; // 3%

        vm.startPrank(minter);
        uint256 tokenId = token.mint(100, METADATA_URI, recipients, shares);
        vm.stopPrank();

        uint256 salePrice = 1000;
        (address[] memory royaltyRecipients, uint256[] memory amounts) = token
            .getRoyaltyDetails(tokenId, salePrice);

        assertEq(royaltyRecipients.length, 2);
        assertEq(amounts[0], 50); // 5% of 1000
        assertEq(amounts[1], 30); // 3% of 1000
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

    /// @notice Test updating royalties
    function test_UpdateRoyalties() public {
        vm.startPrank(minter);
        uint256 tokenId = token.mint(
            100,
            METADATA_URI,
            new address[](0),
            new uint256[](0)
        );
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1000;

        vm.prank(royaltyManager);
        token.setRoyalties(tokenId, recipients, shares);

        (
            ,
            ,
            address[] memory updatedRecipients,
            uint256[] memory updatedShares
        ) = token.getAssetInfo(tokenId);
        assertEq(updatedRecipients[0], user1);
        assertEq(updatedShares[0], 1000);
    }
}
