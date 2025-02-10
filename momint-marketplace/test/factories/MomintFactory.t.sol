// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MomintFactory} from "../../src/factories/MomintFactory.sol";
import {MockInitializableContract} from "../mocks/MockInitializableContract.sol";
import {ContractData} from "../../src/interfaces/IMomintFactory.sol";

contract MomintFactoryTest is Test {
    MomintFactory public factory;
    address public admin = address(0x1);
    address public user = address(0x2);

    event ContractDeployed(address indexed contractAddress);

    function setUp() public {
        factory = new MomintFactory(admin);
    }

    function test_DeployContractWithInit() public {
        vm.startPrank(admin);

        // Deploy implementation with proper initialization
        MockInitializableContract implementation = new MockInitializableContract();
        bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        ContractData memory contractData = ContractData({
            contractAddress: address(implementation),
            initDataRequired: true
        });

        address newContract = factory.deployContract(
            contractData,
            initData,
            salt
        );

        assertTrue(newContract != address(0));
        assertTrue(newContract != address(implementation));
        assertTrue(MockInitializableContract(newContract).initialized());

        vm.stopPrank();
    }

    function test_DeployContractWithoutInit() public {
        vm.startPrank(admin);

        MockInitializableContract implementation = new MockInitializableContract();
        bytes32 salt = keccak256("test_salt");

        ContractData memory contractData = ContractData({
            contractAddress: address(implementation),
            initDataRequired: false
        });

        address newContract = factory.deployContract(contractData, "", salt);

        assertTrue(newContract != address(0));
        assertTrue(newContract != address(implementation));
        assertFalse(MockInitializableContract(newContract).initialized());

        vm.stopPrank();
    }

    function test_DeterministicDeployment() public {
        vm.startPrank(admin);

        MockInitializableContract implementation = new MockInitializableContract();
        bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        ContractData memory contractData = ContractData({
            contractAddress: address(implementation),
            initDataRequired: true
        });

        address deployment1 = factory.deployContract(
            contractData,
            initData,
            salt
        );
        assertTrue(deployment1 != address(0));

        vm.expectRevert(); // Should revert when trying to deploy with same salt
        factory.deployContract(contractData, initData, salt);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedDeploy() public {
        vm.startPrank(user);

        ContractData memory contractData = ContractData({
            contractAddress: address(0x3),
            initDataRequired: false
        });

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        factory.deployContract(contractData, "", bytes32(0));

        vm.stopPrank();
    }

    function test_RevertFailedInitialization() public {
        vm.startPrank(admin);

        MockInitializableContract implementation = new MockInitializableContract();
        bytes memory invalidInitData = abi.encodeWithSignature(
            "invalidFunction()"
        );
        bytes32 salt = keccak256("test_salt");

        ContractData memory contractData = ContractData({
            contractAddress: address(implementation),
            initDataRequired: true
        });

        vm.expectRevert("DeployInitFailed");
        factory.deployContract(contractData, invalidInitData, salt);

        vm.stopPrank();
    }
}
