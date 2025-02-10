// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../../src/controllers/UpgradableBeaconController.sol";
import {Marketplace} from "../../src/marketplace/Marketplace.sol";
import {ERC1155RWA} from "../../src/assets/ERC1155RWA.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// Custom error from Initializable contract
error InvalidInitialization();

contract Foo {
    constructor() {}
}

contract UpgradableBeaconControllerTest is Test {
    UpgradableBeaconController public beaconController;
    Marketplace public implementation;
    Marketplace public marketplace;
    string constant MARKETPLACE_BEACON = "MARKETPLACE_V1";

    // RWA token setup
    ERC1155RWA public rwaImplementation;
    TransparentUpgradeableProxy public rwaProxy;
    ProxyAdmin public proxyAdmin;
    ERC1155RWA public rwaToken;

    address public admin;
    address public user;
    address public proxyToken;

    event UpgradedImplementation(address controller, address newImplementation);
    event UpgradableBeaconDeployed(
        address deployer,
        address beacon,
        address initalImplementation
    );

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
        proxyToken = address(rwaProxy);

        // Deploy Marketplace implementation and beacon
        implementation = new Marketplace();
        beaconController = new UpgradableBeaconController();

        // Deploy beacon through controller - make the controller the owner
        beaconController.deployUpgradeableBeacon(
            MARKETPLACE_BEACON,
            address(implementation),
            address(beaconController)
        );
    }

    function test_DeployMarketplaceProxy() public {
        address beaconAddress = beaconController.beacons(MARKETPLACE_BEACON);
        require(beaconAddress != address(0), "Beacon address cannot be zero");

        BeaconProxy proxy = new BeaconProxy(
            beaconAddress,
            abi.encodeWithSelector(
                Marketplace.initialize.selector,
                proxyToken,
                admin,
                250
            )
        );

        marketplace = Marketplace(payable(address(proxy)));

        assertTrue(address(proxy) != address(0));
        assertEq(address(marketplace.rwaToken()), proxyToken);
        assertEq(marketplace.owner(), admin);
    }

    function test_ProxyInitialization() public {
        BeaconProxy proxy = new BeaconProxy(
            beaconController.beacons(MARKETPLACE_BEACON),
            abi.encodeWithSelector(
                Marketplace.initialize.selector,
                address(rwaToken),
                admin,
                250
            )
        );

        marketplace = Marketplace(payable(address(proxy)));

        assertEq(address(marketplace.rwaToken()), address(rwaToken));
        assertEq(marketplace.owner(), admin);
        assertEq(marketplace.feeRecipient(), admin);
        assertEq(marketplace.protocolFee(), 250);
    }

    function test_UpgradeImplementation() public {
        // Deploy new implementation
        Foo newImplementation = new Foo();

        // Expect event from the controller
        vm.expectEmit(true, true, true, true);
        emit UpgradedImplementation(address(this), address(newImplementation));

        beaconController.upgrade(
            address(newImplementation),
            MARKETPLACE_BEACON
        );

        assertEq(
            beaconController.getImplementation(MARKETPLACE_BEACON),
            address(newImplementation)
        );
    }

    function test_RevertWhen_UnauthorizedUpgrade() public {
        Marketplace newImplementation = new Marketplace();

        vm.prank(user);
        vm.expectRevert("Must specify a implementation address.");
        beaconController.upgrade(address(0), MARKETPLACE_BEACON);
    }

    function test_RevertWhen_NameAlreadyCreated() public {
        // Try to deploy another beacon with the same name
        vm.expectRevert("Name has already been created");
        beaconController.deployUpgradeableBeacon(
            MARKETPLACE_BEACON,
            address(implementation),
            address(beaconController)
        );
    }

    function test_RevertWhen_ImplementationInvalid() public {
        string memory newBeaconName = "NEW_BEACON";
        vm.expectRevert("Must specify a implementation address.");
        beaconController.deployUpgradeableBeacon(
            newBeaconName,
            address(0),
            address(beaconController)
        );
    }

    function test_RevertWhen_UnauthorizedBeaconDeployment() public {
        string memory newBeaconName = "NEW_BEACON";

        // Try to deploy beacon as unauthorized user
        vm.startPrank(user);
        vm.expectRevert("Must specify a implementation address.");
        beaconController.deployUpgradeableBeacon(
            newBeaconName,
            address(0),
            address(beaconController)
        );
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedProxyCreation() public {
        vm.startPrank(user);

        BeaconProxy proxy = new BeaconProxy(
            beaconController.beacons(MARKETPLACE_BEACON),
            abi.encodeWithSelector(
                Marketplace.initialize.selector,
                proxyToken,
                user,
                250
            )
        );

        marketplace = Marketplace(payable(address(proxy)));

        // Try to initialize again - should fail
        vm.expectRevert(InvalidInitialization.selector);
        marketplace.initialize(proxyToken, user, 250);

        vm.stopPrank();
    }

    function test_RevertWhen_DoubleInitialization() public {
        BeaconProxy proxy = new BeaconProxy(
            beaconController.beacons(MARKETPLACE_BEACON),
            abi.encodeWithSelector(
                Marketplace.initialize.selector,
                proxyToken,
                admin,
                250
            )
        );

        marketplace = Marketplace(payable(address(proxy)));

        vm.expectRevert(InvalidInitialization.selector);
        marketplace.initialize(proxyToken, admin, 250);
    }
}
