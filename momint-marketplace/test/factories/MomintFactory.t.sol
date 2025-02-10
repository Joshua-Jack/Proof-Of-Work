// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MomintFactory} from "../../src/factories/MomintFactory.sol";
import {MockInitializableContract} from "../mocks/MockInitializableContract.sol";

contract MomintFactoryTest is Test {
    MomintFactory public factory;
    address public admin = address(0x1);
    address public user = address(0x2);

    event ContractDeployed(
        address indexed newContract,
        MomintFactory.DeploymentType deployType,
        bytes32 salt
    );

    function setUp() public {
        factory = new MomintFactory(admin);
    }

    function test_DeployClone() public {
        vm.startPrank(admin);

        // Deploy implementation with proper initialization
        MockInitializableContract implementation = new MockInitializableContract();
        implementation.initialize(); // Initialize the implementation

        bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(implementation),
            initData: initData,
            salt: salt,
            deployType: MomintFactory.DeploymentType.CLONE,
            creationCode: ""
        });

        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(
            address(0),
            MomintFactory.DeploymentType.CLONE,
            salt
        );

        address newContract = factory.deploy(config);

        assertTrue(newContract != address(0));
        assertTrue(newContract != address(implementation));
        assertTrue(MockInitializableContract(newContract).initialized());

        vm.stopPrank();
    }

    function test_DeployDirect() public {
        vm.startPrank(admin);

        // Deploy implementation
        MockInitializableContract implementation = new MockInitializableContract();

        // Get creation code and constructor args separately
        bytes memory creationCode = type(MockInitializableContract)
            .creationCode;
        bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(implementation),
            initData: initData,
            salt: salt,
            deployType: MomintFactory.DeploymentType.DIRECT,
            creationCode: creationCode
        });

        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(
            address(0),
            MomintFactory.DeploymentType.DIRECT,
            salt
        );

        address newContract = factory.deploy(config);

        assertTrue(newContract != address(0));
        // For direct deployment, we don't need to check initialization
        // as it's handled during construction

        vm.stopPrank();
    }

    function test_RevertUnauthorizedDeploy() public {
        vm.startPrank(user);

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(0x3),
            initData: "",
            salt: bytes32(0),
            deployType: MomintFactory.DeploymentType.CLONE,
            creationCode: ""
        });

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        factory.deploy(config);

        vm.stopPrank();
    }

    function test_RevertInvalidImplementation() public {
        vm.startPrank(admin);

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(0),
            initData: "",
            salt: bytes32(0),
            deployType: MomintFactory.DeploymentType.CLONE,
            creationCode: ""
        });

        vm.expectRevert(MomintFactory.InvalidImplementation.selector);
        factory.deploy(config);

        vm.stopPrank();
    }

    function test_RevertInvalidParameters() public {
        vm.startPrank(admin);

        // For testing invalid parameters, we need a valid implementation first
        MockInitializableContract implementation = new MockInitializableContract();

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(implementation),
            initData: "",
            salt: bytes32(0),
            deployType: MomintFactory.DeploymentType.DIRECT,
            creationCode: "" // Empty creation code for direct deployment should trigger InvalidParameters
        });

        vm.expectRevert(MomintFactory.InvalidParameters.selector);
        factory.deploy(config);

        vm.stopPrank();
    }

    function test_DeterministicDeployment() public {
        vm.startPrank(admin);

        MockInitializableContract implementation = new MockInitializableContract();
        implementation.initialize();

        bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(implementation),
            initData: initData,
            salt: salt,
            deployType: MomintFactory.DeploymentType.CLONE,
            creationCode: ""
        });

        address deployment1 = factory.deploy(config);
        assertTrue(deployment1 != address(0));

        vm.expectRevert(); // Should revert when trying to deploy with same salt
        factory.deploy(config);

        vm.stopPrank();
    }

    function test_RevertFailedInitialization() public {
        vm.startPrank(admin);

        MockInitializableContract implementation = new MockInitializableContract();
        implementation.initialize(); // Initialize implementation first

        bytes memory invalidInitData = abi.encodeWithSignature(
            "invalidFunction()"
        );
        bytes32 salt = keccak256("test_salt");

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(implementation),
            initData: invalidInitData,
            salt: salt,
            deployType: MomintFactory.DeploymentType.CLONE,
            creationCode: ""
        });

        vm.expectRevert(MomintFactory.DeploymentFailed.selector);
        factory.deploy(config);

        vm.stopPrank();
    }

    function test_PredictDeploymentAddress() public {
        vm.startPrank(admin);

        bytes memory creationCode = type(MockInitializableContract)
            .creationCode;
        bytes memory constructorArgs = abi.encodeWithSignature("initialize()");
        bytes32 salt = keccak256("test_salt");

        address predicted = factory.predictDeploymentAddress(
            salt,
            creationCode,
            constructorArgs
        );

        MomintFactory.DeployConfig memory config = MomintFactory.DeployConfig({
            implementation: address(1), // Any non-zero address
            initData: constructorArgs,
            salt: salt,
            deployType: MomintFactory.DeploymentType.DIRECT,
            creationCode: creationCode
        });

        address deployed = factory.deploy(config);
        assertEq(
            predicted,
            deployed,
            "Predicted address should match deployed address"
        );

        vm.stopPrank();
    }
}
