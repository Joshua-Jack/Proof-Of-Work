// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "../../src/marketplace/MarketplaceFactoryBeacon.sol";
import "../../src/marketplace/Marketplace.sol";
import "../../src/assets/ERC1155RWA.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MarketplaceBeaconTest is Test {
    MarketplaceFactoryBeacon public beacon;
    Marketplace public implementation;
    Marketplace public marketplace;

    // RWA token setup
    ERC1155RWA public rwaImplementation;
    TransparentUpgradeableProxy public rwaProxy;
    ProxyAdmin public proxyAdmin;
    ERC1155RWA public rwaToken;

    address public admin;
    address public user;
    address public proxyToken;

    event ProxyDeployed(address indexed proxy, address indexed owner);

    function setUp() public {
        admin = address(this);
        user = makeAddr("user");

        // Deploy RWA token through proxy
        rwaImplementation = new ERC1155RWA();
        proxyAdmin = new ProxyAdmin(admin);

        bytes memory rwaInitData = abi.encodeWithSelector(
            ERC1155RWA.initialize.selector,
            admin,
            "ipfs://"
        );

        rwaProxy = new TransparentUpgradeableProxy(
            address(rwaImplementation),
            address(proxyAdmin),
            rwaInitData
        );
        rwaToken = ERC1155RWA(address(rwaProxy));
        proxyToken = address(rwaToken);

        // Deploy marketplace implementation and beacon
        implementation = new Marketplace();
        beacon = new MarketplaceFactoryBeacon(address(implementation), admin);
    }

    function test_DeployMarketplaceProxy() public {
        bytes memory initData = abi.encodeWithSelector(
            Marketplace.initialize.selector,
            proxyToken,
            admin,
            250
        );

        address proxyAddress = beacon.createMarketplaceProxy(
            initData,
            address(proxyToken)
        );
        marketplace = Marketplace(payable(proxyAddress));

        assertTrue(proxyAddress != address(0));
        assertEq(address(marketplace.rwaToken()), proxyToken);
        assertEq(marketplace.owner(), admin);
    }

    function test_ProxyInitialization() public {
        bytes memory initData = abi.encodeWithSelector(
            Marketplace.initialize.selector,
            address(rwaToken),
            admin,
            250
        );

        address proxyAddress = beacon.createMarketplaceProxy(initData);
        marketplace = Marketplace(payable(proxyAddress));

        assertEq(address(marketplace.rwaToken()), address(rwaToken));
        assertEq(marketplace.owner(), admin);
        assertEq(marketplace.feeRecipient(), admin);
        assertEq(marketplace.protocolFee(), 250);
    }

    // function test_MarketplaceAndRWAIntegration() public {
    //     bytes memory initData = abi.encodeWithSelector(
    //         Marketplace.initialize.selector,
    //         address(rwaToken),
    //         admin,
    //         250
    //     );

    //     address proxyAddress = beacon.createMarketplaceProxy(initData);
    //     marketplace = Marketplace(payable(proxyAddress));

    //     // Test RWA token integration
    //     vm.startPrank(admin);
    //     rwaToken.grantRole(rwaToken.MINTER_ROLE(), address(marketplace));
    //     marketplace.setAcceptedToken(address(rwaToken), true);
    //     vm.stopPrank();

    //     // Verify setup
    //     assertTrue(
    //         rwaToken.hasRole(rwaToken.MINTER_ROLE(), address(marketplace))
    //     );
    //     assertTrue(marketplace.isAcceptedToken(address(rwaToken)));
    // }

    function test_RevertWhen_UnauthorizedUpgrade() public {
        Marketplace newImplementation = new Marketplace();

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        beacon.upgradeTo(address(newImplementation));
    }
}
