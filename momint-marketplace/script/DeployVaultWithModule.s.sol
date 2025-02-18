// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultController} from "../src/controllers/VaultController.sol";
import {VaultInfo, VaultFees} from "../src/interfaces/IMomintVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Module} from "../src/interfaces/IMomintVault.sol";
import {console} from "forge-std/console.sol";
import {IModule} from "../src/interfaces/IModule.sol";
import {ModuleStorage} from "../src/storage/ModuleStorage.sol";

contract DeployVaultWithModule is Script {
    // Constants from VaultController
    bytes32 public constant VAULT_IMPLEMENTATION_ID =
        keccak256("VAULT_IMPL_V1");
    bytes32 public constant MODULE_IMPLEMENTATION_ID =
        keccak256("MODULE_IMPL_V1");

    // Replace these with your actual addresses
    address public constant USDT = 0x05D032ac25d322df992303dCa074EE7392C117b9;
    address public constant CONTROLLER =
        0x0000000000000000000000000000000000000000; // Your deployed controller address
    address public constant MODULE_STORAGE =
        0x0000000000000000000000000000000000000000; // Your deployed module storage address

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Vault
        VaultInfo memory vaultParams = VaultInfo({
            baseAsset: IERC20(USDT),
            symbol: "MV",
            shareName: "Momint Vault",
            owner: admin,
            feeRecipient: admin,
            fees: VaultFees({
                depositFee: 500, // 5%
                withdrawalFee: 100, // 1%
                protocolFee: 300 // 3%
            }),
            liquidityHoldBP: 3000, // 30%
            maxOwnerShareBP: 7000 // 70%
        });

        bytes memory vaultInitData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(VaultInfo)")),
            vaultParams
        );

        VaultController controller = VaultController(CONTROLLER);
        ModuleStorage moduleStorage = ModuleStorage(MODULE_STORAGE);
        address newVault = controller.deployVault(
            VAULT_IMPLEMENTATION_ID,
            vaultInitData
        );
        console.log("Deployed vault at:", newVault);

        // 2. Deploy SP Module
        bytes memory moduleInitData = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    "initialize(address,address,string,uint256,uint256,string,address)"
                )
            ),
            admin,
            newVault,
            "Test Project",
            5e6, // 5 USDT per share
            100, // 100 total shares
            "ipfs://metadata",
            admin // project owner
        );

        controller.deployModule(MODULE_IMPLEMENTATION_ID, moduleInitData);

        address newModule = moduleStorage.getModule(MODULE_IMPLEMENTATION_ID);
        console.log("Deployed module at:", newModule);

        // 3. Add Module to Vault
        Module memory moduleData = Module({
            module: IModule(newModule),
            isSingleProject: true,
            active: true
        });

        controller.addModule(newVault, 0, moduleData);
        console.log("Added module to vault");

        vm.stopBroadcast();
    }
}
