// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./Marketplace.sol";

/**
 * @title RWA Marketplace Factory Beacon
 * @dev Combined factory and beacon for deploying marketplace proxies
 */
contract MarketplaceFactoryBeacon is UpgradeableBeacon {
    event ProxyDeployed(address indexed proxy, address indexed owner);
    event BeaconUpgraded(address indexed implementation);

    constructor(
        address implementation_,
        address initialOwner
    ) UpgradeableBeacon(implementation_, initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Creates a new marketplace proxy
     * @param initData Initialization data for the marketplace
     * @return proxy Address of the newly created proxy
     */
    function createMarketplaceProxy(
        bytes memory initData,
        address implementation
    ) external returns (address) {
        // Create new proxy with the correct initialization data
        BeaconProxy proxy = new BeaconProxy(implementation, initData);

        emit ProxyDeployed(address(proxy), owner);
        return address(proxy);
    }

    /**
     * @dev Returns the current implementation address
     */
    function getImplementation() external view returns (address) {
        return implementation();
    }
}
