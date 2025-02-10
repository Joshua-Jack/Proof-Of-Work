// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ContractStorage} from "../../src/storage/ContractStorage.sol";
import {ContractData} from "../../src/interfaces/IContractStorage.sol";

contract ContractStorageTest is Test {
    ContractStorage public contractStorage;
    address public admin = address(0x1);
    address public user = address(0x2);
    address public contractAddress = address(0x3);

    bytes32 public constant TEST_ID = keccak256("TEST_CONTRACT_V1");

    event ContractAdded(bytes32 indexed id, ContractData contract_);
    event ContractRemoved(bytes32 indexed id, ContractData contract_);
    error ContractDoesNotExist(bytes32 id_);

    function setUp() public {
        contractStorage = new ContractStorage(admin);
    }

    function test_AddContract() public {
        vm.startPrank(admin);

        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });

        vm.expectEmit(true, true, true, true);
        emit ContractAdded(TEST_ID, contractData);

        contractStorage.addContract(TEST_ID, contractData);

        ContractData memory storedData = contractStorage.getContract(TEST_ID);
        assertEq(storedData.contractAddress, contractAddress);
        assertTrue(storedData.initDataRequired);
        assertTrue(contractStorage.contractExists(TEST_ID));

        vm.stopPrank();
    }

    function test_RemoveContract() public {
        vm.startPrank(admin);

        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });

        contractStorage.addContract(TEST_ID, contractData);

        vm.expectEmit(true, true, true, true);
        emit ContractRemoved(TEST_ID, contractData);

        contractStorage.removeContract(TEST_ID);

        assertFalse(contractStorage.contractExists(TEST_ID));

        vm.stopPrank();
    }

    function test_GetAllContracts() public {
        vm.startPrank(admin);

        // Test empty list first
        address[] memory emptyContracts = contractStorage.getAllContracts();
        assertEq(emptyContracts.length, 0);

        // Add multiple contracts
        bytes32 id1 = keccak256("CONTRACT1");
        bytes32 id2 = keccak256("CONTRACT2");

        ContractData memory data1 = ContractData({
            contractAddress: address(0x4),
            initDataRequired: true
        });

        ContractData memory data2 = ContractData({
            contractAddress: address(0x5),
            initDataRequired: false
        });

        contractStorage.addContract(id1, data1);
        contractStorage.addContract(id2, data2);

        address[] memory allContracts = contractStorage.getAllContracts();
        assertEq(allContracts.length, 2);
        assertEq(allContracts[0], address(0x4));
        assertEq(allContracts[1], address(0x5));

        vm.stopPrank();
    }

    function test_RevertUnauthorizedAdd() public {
        vm.startPrank(user);

        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });

        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        contractStorage.addContract(TEST_ID, contractData);

        vm.stopPrank();
    }

    function test_RevertUnauthorizedRemove() public {
        vm.startPrank(admin);
        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });
        contractStorage.addContract(TEST_ID, contractData);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        contractStorage.removeContract(TEST_ID);
        vm.stopPrank();
    }

    function test_RevertDuplicateContract() public {
        vm.startPrank(admin);

        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });

        contractStorage.addContract(TEST_ID, contractData);

        vm.expectRevert(
            abi.encodeWithSignature("ContractAlreadyExists(bytes32)", TEST_ID)
        );
        contractStorage.addContract(TEST_ID, contractData);

        vm.stopPrank();
    }

    function test_RevertRemoveNonExistentContract() public {
        vm.startPrank(admin);

        vm.expectRevert(
            abi.encodeWithSignature("ContractDoesNotExist(bytes32)", TEST_ID)
        );
        contractStorage.removeContract(TEST_ID);

        vm.stopPrank();
    }

    function test_RevertRemoveAlreadyRemovedContract() public {
        vm.startPrank(admin);

        ContractData memory contractData = ContractData({
            contractAddress: contractAddress,
            initDataRequired: true
        });

        contractStorage.addContract(TEST_ID, contractData);
        contractStorage.removeContract(TEST_ID);

        vm.expectRevert(
            abi.encodeWithSignature("ContractDoesNotExist(bytes32)", TEST_ID)
        );
        contractStorage.removeContract(TEST_ID);

        vm.stopPrank();
    }
}
