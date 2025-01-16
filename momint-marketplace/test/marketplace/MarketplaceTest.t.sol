// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import "../../src/marketplace/Marketplace.sol";
// import "../../src/assets/ERC1155RWA.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract MarketplaceTest is Test {
//     Marketplace public implementation;
//     TransparentUpgradeableProxy public proxy;
//     ProxyAdmin public proxyAdmin;
//     Marketplace public marketplace;
//     ERC1155RWA public rwaToken;
//     MockUSDC public usdc;

//     address public admin;
//     address public seller;
//     address public buyer;
//     address public feeRecipient;

//     uint256 constant PROTOCOL_FEE = 250; // 2.5%
//     uint256 constant INITIAL_BALANCE = 10000 * 10 ** 18; // 10000 USDC

//     function setUp() public {
//         // Setup addresses
//         admin = address(this);
//         seller = makeAddr("seller");
//         buyer = makeAddr("buyer");
//         feeRecipient = makeAddr("feeRecipient");

//         // Deploy implementation contracts
//         implementation = new Marketplace();
//         proxyAdmin = new ProxyAdmin(admin);
//         rwaToken = new ERC1155RWA();
//         usdc = new MockUSDC();

//         // Initialize RWA token
//         rwaToken.initialize(admin, "ipfs://");

//         // Deploy proxy with initialization
//         bytes memory initData = abi.encodeWithSelector(
//             Marketplace.initialize.selector,
//             address(rwaToken),
//             feeRecipient,
//             PROTOCOL_FEE
//         );

//         proxy = new TransparentUpgradeableProxy(
//             address(implementation),
//             address(proxyAdmin),
//             initData
//         );

//         // Create marketplace instance
//         marketplace = Marketplace(address(proxy));

//         // Setup roles and permissions
//         rwaToken.grantRole(rwaToken.MINTER_ROLE(), admin);
//         marketplace.setAcceptedToken(address(usdc), true);

//         // Fund accounts
//         usdc.transfer(buyer, INITIAL_BALANCE);

//         // Mint RWA token to seller
//         vm.startPrank(admin);
//         uint256 tokenId = rwaToken.mint(
//             100,
//             "ipfs://metadata",
//             new address[](0),
//             new uint256[](0)
//         );
//         rwaToken.safeTransferFrom(admin, seller, tokenId, 50, "");
//         vm.stopPrank();
//     }

//     // Add test for initialization
//     function test_InitializationFailure() public {
//         vm.expectRevert("Initializable: contract is already initialized");
//         marketplace.initialize(address(rwaToken), feeRecipient, PROTOCOL_FEE);
//     }

//     // Rest of the test functions remain the same...
// }
