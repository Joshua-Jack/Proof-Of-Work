//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title UpgradableBeaconController
 * @notice The Upgradable Beacon Controller is responsible for holding the current logic contracts and upgrading the logic contracts.
 */
contract UpgradableBeaconController is Initializable {
    /** @notice Store prior implementation addresses for each beacon. */
    mapping(string => address) private implementations;

    /** @notice Maps the name of the Upgradeable Beacon to its address. */
    mapping(string => address) public beacons;

    /** @notice Fires an event everytime an upgrade occurs. */
    event UpgradedImplementation(address controller, address newImplementation);
    /** @notice Fires an event when an upgradable beaon is deployed. */
    event UpgradableBeaconDeployed(
        address deployer,
        address beacon,
        address initalImplementation
    );

    ///@dev checks to ensure that only the controller can upgrade the implementation
    modifier isValidImplementation(address implementation_) {
        require(
            implementation_ != address(0),
            "Must specify a implementation address."
        );
        _;
    }

    ///@dev checks to ensure that the name in the mapping key has not been used
    modifier isValidName(string memory name_) {
        require(
            implementations[name_] == address(0),
            "Name has already been created"
        );
        _;
    }

    constructor() {}

    /**
     * @notice Deploys an upgradable beacon and sets an inital implementation address.
     * @param implementation_ The address of the inital V0 implementation.
     * @param name_ The name of which the implementation & beacon is stored.
     */
    function deployUpgradeableBeacon(
        string memory name_,
        address implementation_,
        address owner_
    ) public isValidImplementation(implementation_) isValidName(name_) {
        UpgradeableBeacon beacon = new UpgradeableBeacon(
            implementation_,
            owner_
        );
        beacons[name_] = address(beacon);
        implementations[name_] = implementation_;
        emit UpgradableBeaconDeployed(
            msg.sender,
            beacons[name_],
            implementation_
        );
    }

    /**
     * @notice Sets a new implementation address on an upgrade beacon.
     * have the index store the beacon?
     * @param newImplementation_ The address of the new implementation.
     * @param name_ The Name of which the implementation is stored.
     */
    function upgrade(
        address newImplementation_,
        string memory name_
    ) public isValidImplementation(newImplementation_) {
        UpgradeableBeacon beacon = UpgradeableBeacon(beacons[name_]);
        beacon.upgradeTo(newImplementation_);
        implementations[name_] = newImplementation_;

        emit UpgradedImplementation(msg.sender, newImplementation_);
    }

    /**
     * @notice Gets an implementation address based on the name of the beacon.
     * @param name_ the name in which the implementation is located.
     * @return the implementation contract.
     */
    function getImplementation(
        string memory name_
    ) public view returns (address) {
        return implementations[name_];
    }

    /**
     * @notice Gets a beacon address based on the name of the beacon.
     * @param name_ the name in which the implementation is located.
     * @return the implementation contract.
     */

    function getBeacon(string memory name_) external view returns (address) {
        return beacons[name_];
    }
}
