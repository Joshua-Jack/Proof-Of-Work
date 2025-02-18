// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultController} from "../src/controllers/VaultController.sol";
import {console} from "forge-std/console.sol";

contract GrantAccess is Script {
    // Reference from VaultController.sol
    bytes32 public constant VAULT_CONTROLLER_ROLE =
        keccak256("VAULT_CONTROLLER");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Address of your deployed VaultController
        address controllerAddress = vm.envAddress("CONTROLLER_ADDRESS");
        // Address to grant access to
        address newAdmin = vm.envAddress("NEW_ADMIN_ADDRESS");

        VaultController controller = VaultController(controllerAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Grant VAULT_CONTROLLER_ROLE
        controller.grantRole(VAULT_CONTROLLER_ROLE, newAdmin);

        // Optionally grant DEFAULT_ADMIN_ROLE
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        controller.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        console.log("Granted roles to:", newAdmin);

        vm.stopBroadcast();
    }
}
