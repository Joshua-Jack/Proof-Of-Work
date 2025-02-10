// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Marketplace} from "../src/marketplace/Marketplace.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {console} from "forge-std/console.sol";

contract DeployMarketplace is Script {
    function run() external {
        // Get deployment parameters from environment
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address rwaToken = vm.envAddress("RWA_TOKEN_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");
        uint256 protocolFee = vm.envUint("PROTOCOL_FEE");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        Marketplace implementation = new Marketplace();

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin(admin);

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            Marketplace.initialize.selector,
            rwaToken,
            feeRecipient,
            protocolFee
        );

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        // Get the proxy address cast as Marketplace
        Marketplace marketplace = Marketplace(address(proxy));

        vm.stopBroadcast();

        // Log deployment addresses
        console.log("Marketplace Implementation:", address(implementation));
        console.log("Proxy Admin:", address(proxyAdmin));
        console.log("Marketplace Proxy:", address(proxy));

        // Verify initialization
        require(marketplace.owner() == admin, "Owner not set correctly");
        require(
            address(marketplace.rwaToken()) == rwaToken,
            "RWA token not set correctly"
        );
        require(
            marketplace.feeRecipient() == feeRecipient,
            "Fee recipient not set correctly"
        );
        require(
            marketplace.protocolFee() == protocolFee,
            "Protocol fee not set correctly"
        );
    }
}
