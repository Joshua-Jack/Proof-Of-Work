// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {MomintVault} from "../src/vault/MomintVault.sol";
import {Module, VaultFees} from "../src/interfaces/IMomintVault.sol";
import {Test, stdError} from "forge-std/Test.sol";
import {IModule} from "../src/interfaces/IModule.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SPModule} from "../src/modules/SPModule.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Global} from "./Global.t.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {InitParams} from "../src/interfaces/IMomintVault.sol";

contract TestSetup is Test, Global {
    MomintVault vault;
    address vaultAddress;

    SPModule spModule;
    address spModuleAddress;

    uint256 lisk;
    string constant LISK_RPC_URL = "https://rpc.api.lisk.com";
    uint256 constant FORK_BLOCK_NUMBER = 11774326;

    function test() public {}

    function setUp() public virtual {
        _createForks();
        _setupVault();
        _setupModule();
    }

    function _deployContracts() internal {}

    /// Creates testing forks
    function _createForks() internal virtual {
        lisk = vm.createFork(LISK_RPC_URL, FORK_BLOCK_NUMBER);
        vm.selectFork(lisk);
    }

    function _setupVault() internal {
        // Deploy vault with admin as owner
        implementation = address(new MomintVault());
        vaultAddress = Clones.clone(implementation);
        vault = MomintVault(vaultAddress);
        InitParams memory params = InitParams({
            baseAsset: USDT,
            symbol: "MV",
            shareName: "Momint Vault",
            owner: admin,
            feeRecipient: feeRecipient,
            fees: VaultFees({
                depositFee: 500,
                withdrawalFee: 100,
                protocolFee: 300
            }),
            liquidityHoldBP: 3000, // 30%
            maxOwnerShareBP: 7000 // 70%
        });
        vault.initialize(params);
        vm.makePersistent(vaultAddress);
    }

    function _setupModule() internal {
        spModule = new SPModule();
        spModule.initialize(
            admin,
            address(vaultAddress),
            "Test Project",
            5e6,
            100,
            "ipfs://metadata",
            user3
        );
        spModuleAddress = address(spModule);
        vm.makePersistent(spModuleAddress);
    }

    function _createMockModule(
        address admin_
    ) internal returns (Module memory) {
        spModule = new SPModule();
        spModule.initialize(
            admin,
            address(vaultAddress),
            "Test Project",
            5e6,
            100,
            "ipfs://metadata",
            user3
        );
        spModuleAddress = address(spModule);
        return
            Module({
                module: IModule(address(spModuleAddress)),
                isSingleProject: true,
                active: false // Will be set to true when added
            });
    }
}
