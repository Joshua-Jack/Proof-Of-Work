// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC1155RWA} from "../src/assets/ERC1155RWA.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {console} from "forge-std/console.sol";

contract DeployERC1155RWA is Script {
    function run() external {
        // Get deployment parameters from environment
        address admin = vm.envAddress("ADMIN_ADDRESS");
        string memory baseUri = vm.envString("BASE_URI");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        ERC1155RWA implementation = new ERC1155RWA();

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin(admin);

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            ERC1155RWA.initialize.selector,
            admin,
            baseUri
        );

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        // Get the proxy address cast as ERC1155RWA
        ERC1155RWA rwaToken = ERC1155RWA(address(proxy));

        vm.stopBroadcast();

        // Log deployment addresses
        console.log("ERC1155RWA Implementation:", address(implementation));
        console.log("Proxy Admin:", address(proxyAdmin));
        console.log("ERC1155RWA Proxy:", address(proxy));

        // Verify initialization
        require(
            rwaToken.hasRole(rwaToken.DEFAULT_ADMIN_ROLE(), admin),
            "Admin role not set"
        );
        require(
            rwaToken.hasRole(rwaToken.MINTER_ROLE(), admin),
            "Minter role not set"
        );
        require(
            rwaToken.hasRole(rwaToken.PAUSER_ROLE(), admin),
            "Pauser role not set"
        );
        require(
            rwaToken.hasRole(rwaToken.ROYALTY_ROLE(), admin),
            "Royalty role not set"
        );
    }
}
