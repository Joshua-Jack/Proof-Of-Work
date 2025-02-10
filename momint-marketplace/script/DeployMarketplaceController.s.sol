// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {MarketplaceController} from "../src/controllers/MarketplaceController.sol";

contract DeployMarketplaceController is Script {
    function run() external returns (MarketplaceController) {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MarketplaceController
        MarketplaceController controller = new MarketplaceController(admin);

        // Setup initial roles
        controller.grantRole(controller.PAUSE_CONTROLLER_ROLE(), admin);
        controller.grantRole(controller.MARKETPLACE_CONTROLLER_ROLE(), admin);

        vm.stopBroadcast();

        // Log deployment information
        console.log("MarketplaceController deployed at:", address(controller));
        console.log("Admin address:", admin);

        return controller;
    }
}
