// TestSetup.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MomintVault} from "../../src/vault/MomintVault.sol";
import {Module, VaultFees} from "../../src/interfaces/IMomintVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestSetup} from "../TestSetup.t.sol";
import {IModule} from "../../src/interfaces/IModule.sol";
import {SPModule} from "../../src/modules/SPModule.sol";
import {console} from "forge-std/console.sol";
import "forge-std/StdStyle.sol";
import {Styles} from "../utils/Styles.sol";

// MomintVaultTests.t.sol
contract MomintVaultTests is TestSetup {
    uint256 constant DECIMALS = 6;
    uint256 constant PRECISION = 10 ** DECIMALS;
    uint256 constant PROJECT_ID = 1;
    uint256 constant PRICE_PER_SHARE = 1e18; // $1 in 18 decimals
    uint256 constant TOTAL_SHARES = 1000 * PRECISION;
    string constant URI = "ipfs://metadata";
    string constant PROJECT_NAME = "Test Solar Project";
    Module public mockModule;

    event SharesAllocated(
        address indexed user,
        uint256 indexed projectId,
        uint256 shares,
        uint256 invested,
        uint256 refunded
    );

    function setUp() public virtual override {
        super.setUp();

        // Create mock module
        mockModule = _createMockModule(admin);

        // Make sure admin has necessary permissions
        vm.startPrank(admin);
        // Any additional setup needed
        vm.stopPrank();
    }

    function test_vaultInfo() public view {
        assertEq(vault.name(), "Momint Vault", "Name");
        console.log(Styles.h1("Name: Momint Vault"));
        assertEq(vault.symbol(), "MV", "Symbol");
        console.log(Styles.h1("Symbol: MV"));
        assertEq(vault.decimals(), 15, "Decimals");
        console.log(Styles.h1("Decimals: 15"));
        assertEq(vault.asset(), address(USDT), "Vault Token Address");
        console.log(
            Styles.h1("Vault Token Address:"),
            StdStyle.green(address(USDT))
        );
        assertEq(vault.owner(), admin, "Owner");
        console.log(Styles.h1("Owner: "), StdStyle.green(admin));
        VaultFees memory fees = vault.getVaultFees();
        assertEq(vault.feeRecipient(), feeRecipient, "Fee Recipient");
        console.log(Styles.h1("Fee Recipient: "), StdStyle.green(feeRecipient));
        assertEq(fees.depositFee, 500, "Deposit Fee");
        assertEq(fees.withdrawalFee, 100, "Withdrawal Fee");
        assertEq(fees.protocolFee, 300, "Protocol Fee");
        console.log(Styles.h1("Protocol Fee: 300"));
    }

    function test_deposit() public {
        console.log("\n=== Starting deposit test ===");

        vm.startPrank(admin);
        console.log("Creating single project module as admin...");
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;

        console.log("Adding module to vault...");
        console.log("Module address:", address(singleProjectModule.module));
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        console.log("\nStarting user operations as:", user1);
        console.log("Initial user USDT balance:", USDT.balanceOf(user1));

        uint256 userBalance = USDT.balanceOf(user1);
        console.log("Approving vault to spend USDT...");
        USDT.approve(vaultAddress, userBalance);

        SPModule module = SPModule(address(singleProjectModule.module));

        // Log initial states
        console.log("\nInitial states:");
        console.log("- Vault balance of user:", vault.balanceOf(user1));
        console.log(
            "- Fee recipient USDT balance:",
            USDT.balanceOf(feeRecipient)
        );
        console.log(
            "- Available shares in module:",
            module.getAvailableShares()
        );
        console.log(
            "- Allocated shares in module:",
            module.getAllocatedShares()
        );

        uint256 depositAmount = 15e6;
        console.log("\nAttempting deposit of", depositAmount, "USDT");

        uint256 shares = vault.deposit(depositAmount, user1, 0);

        console.log("\nDeposit results:");
        console.log("- Shares received:", shares);
        console.log("- New vault balance:", vault.balanceOf(user1));
        console.log("- New USDT balance:", USDT.balanceOf(user1));
        console.log("- Vault total supply:", vault.totalSupply());
        console.log("- Vault total assets:", vault.totalAssets());

        // Get and log module state
        (uint256 moduleShares, uint256 totalInvested, ) = module
            .getUserInvestment(user1);
        console.log("\nModule state after deposit:");
        console.log("- User shares in module:", moduleShares);
        console.log("- Total invested:", totalInvested);
        console.log("- Available shares:", module.getAvailableShares());
        console.log("- Allocated shares:", module.getAllocatedShares());

        vm.stopPrank();
        console.log("=== Deposit test complete ===\n");
    }

    function test_distributeReturns() public {
        console.log("\n=== Starting distributeReturns test ===");

        vm.startPrank(user1);
        console.log("Transferring USDT from user1 to admin...");
        console.log("Initial user1 USDT balance:", USDT.balanceOf(user1));
        USDT.transfer(admin, 100e6);
        console.log("Final user1 USDT balance:", USDT.balanceOf(user1));
        vm.stopPrank();

        vm.startPrank(admin);
        console.log("\nSetting up as admin...");
        console.log("Admin USDT balance:", USDT.balanceOf(admin));

        console.log("Creating and adding single project module...");
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        vault.addModule(singleProjectModule, false, 0);

        console.log("\nDistributing returns...");
        USDT.approve(address(vault), 100e6);
        vault.distributeReturns(100e6, 0);

        // Log epoch info
        (uint256 id, uint256 amount, uint256 pendingRewards) = vault
            .getEpochInfo(1);
        console.log("\nEpoch information:");
        console.log("- ID:", id);
        console.log("- Amount:", amount);
        console.log("- Pending rewards:", pendingRewards);
        console.log("- Current epoch ID:", vault.currentEpochId());

        vm.stopPrank();
        console.log("=== distributeReturns test complete ===\n");
    }

    function test_withdraw() public {
        console.log("\n=== Starting withdraw test ===");

        // Setup initial transfers
        vm.startPrank(usdtWhale);
        console.log("Transferring USDT from whale to admin...");
        console.log("Whale initial balance:", USDT.balanceOf(usdtWhale));
        USDT.transfer(admin, USDT.balanceOf(usdtWhale));
        console.log("Whale final balance:", USDT.balanceOf(usdtWhale));
        vm.stopPrank();

        // Admin setup
        vm.startPrank(admin);
        console.log("\nSetting up module as admin...");
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User operations
        vm.startPrank(user2);
        console.log("\nStarting user operations...");
        uint256 depositAmount = 100e6;
        console.log("Initial user2 USDT balance:", USDT.balanceOf(user2));

        console.log("Approving and depositing", depositAmount, "USDT");
        USDT.approve(address(vault), depositAmount);

        // Record and log initial module state
        Module memory module = vault.getModule(0);
        console.log("\nInitial module state:");
        console.log("- Available shares:", module.module.getAvailableShares());
        console.log("- Allocated shares:", module.module.getAllocatedShares());
        console.log("- Total shares:", module.module.getTotalShares());

        uint256 shares = vault.deposit(depositAmount, user2, 0);
        console.log("\nDeposit results:");
        console.log("- Shares received:", shares);

        // Log post-deposit state
        console.log("\nPost-deposit module state:");
        console.log("- Available shares:", module.module.getAvailableShares());
        console.log("- Allocated shares:", module.module.getAllocatedShares());

        // Withdraw operation
        uint256 withdrawShares = shares / 2;
        console.log("\nAttempting to withdraw", withdrawShares, "shares");

        uint256 balanceBefore = USDT.balanceOf(user2);
        uint256 withdrawnAmount = vault.withdraw(withdrawShares, user2);

        console.log("\nWithdraw results:");
        console.log("- Amount withdrawn:", withdrawnAmount);
        console.log("- New vault balance:", vault.balanceOf(user2));
        console.log(
            "- USDT balance change:",
            USDT.balanceOf(user2) - balanceBefore
        );

        // Final module state
        console.log("\nFinal module state:");
        console.log("- User shares:", module.module.getUserShares(user2));
        console.log("- Available shares:", module.module.getAvailableShares());
        console.log("- Allocated shares:", module.module.getAllocatedShares());
        console.log("- Total shares:", module.module.getTotalShares());

        vm.stopPrank();
        console.log("=== Withdraw test complete ===\n");
    }

    function test_claimReturns() public {
        console.log("\n=== Starting claimReturns test ===");

        // Initial setup - Transfer from user1 to admin
        vm.startPrank(user1);

        console.log("\nInitial transfer from user1 to admin:");

        uint256 user1BalanceBefore = USDT.balanceOf(user1);
        console.log("- User1 initial USDT balance:", user1BalanceBefore);
        USDT.transfer(admin, user1BalanceBefore);
        console.log("- User1 final USDT balance:", USDT.balanceOf(user1));
        vm.stopPrank();

        // Transfer from whale to admin
        vm.startPrank(usdtWhale);
        console.log("\nTransfer from USDT whale to admin:");
        uint256 bal = USDT.balanceOf(usdtWhale);
        console.log("- Whale initial USDT balance:", bal);
        USDT.transfer(admin, bal);
        console.log("- Whale final USDT balance:", USDT.balanceOf(usdtWhale));
        console.log(
            "- Admin USDT balance after transfers:",
            USDT.balanceOf(admin)
        );
        vm.stopPrank();

        // Admin setup
        vm.startPrank(admin);
        console.log("\nAdmin setting up module:");
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        console.log("- Module address:", address(singleProjectModule.module));

        console.log("Adding module to vault...");
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User deposit
        vm.startPrank(user2);
        console.log("\nUser2 deposit process:");
        console.log("- Initial USDT balance:", USDT.balanceOf(user2));
        console.log("- Approving 10e6 USDT to vault");
        USDT.approve(address(vault), 10e6);

        uint256 shares = vault.deposit(10e6, user2, 0);
        console.log("- Shares received from deposit:", shares);
        console.log("- USDT balance after deposit:", USDT.balanceOf(user2));
        console.log("- Vault share balance:", vault.balanceOf(user2));
        vm.stopPrank();

        // Admin distributes returns
        vm.startPrank(admin);
        console.log("\nAdmin distributing returns:");
        uint256 adminBalanceBefore = USDT.balanceOf(admin);
        console.log("- Admin initial USDT balance:", adminBalanceBefore);

        uint256 distributionAmount = 100_000_000_000; // 100,000 USDT
        console.log("- Distribution amount:", distributionAmount);

        console.log("Approving and distributing returns...");
        USDT.approve(address(vault), distributionAmount);
        vault.distributeReturns(distributionAmount, 0);

        console.log("Distribution results:");
        console.log("- Admin final USDT balance:", USDT.balanceOf(admin));
        console.log(
            "- Balance change:",
            adminBalanceBefore - USDT.balanceOf(admin)
        );

        // Log epoch information
        (uint256 epochId, uint256 epochAmount, uint256 pendingRewards) = vault
            .getEpochInfo(1);
        console.log("\nEpoch information:");
        console.log("- Epoch ID:", epochId);
        console.log("- Epoch amount:", epochAmount);
        console.log("- Pending rewards:", pendingRewards);
        vm.stopPrank();

        // User claims returns
        vm.startPrank(user2);
        console.log("\nUser2 claiming returns:");
        uint256 balanceBefore = USDT.balanceOf(user2);
        console.log("- Initial USDT balance:", balanceBefore);
        console.log("- Vault shares held:", vault.balanceOf(user2));

        uint256 claimed = vault.claimReturns(0, 1);

        console.log("\nClaim results:");
        console.log("- Amount claimed:", claimed);
        console.log("- New USDT balance:", USDT.balanceOf(user2));
        console.log(
            "- Balance increase:",
            USDT.balanceOf(user2) - balanceBefore
        );

        // Get final module state
        Module memory module = vault.getModule(0);
        console.log("\nFinal module state:");
        console.log("- User shares:", module.module.getUserShares(user2));
        console.log("- Available shares:", module.module.getAvailableShares());
        console.log("- Allocated shares:", module.module.getAllocatedShares());

        vm.stopPrank();
        console.log("=== claimReturns test complete ===\n");
    }

    function test_addProjectModule() public {
        vm.startPrank(admin);

        // Create single project module
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;

        // Add module
        vault.addModule(singleProjectModule, false, 0);

        vm.stopPrank();

        // Verify module was added
        (IModule module, bool isSingleProject, bool active) = vault.modules(0);
        assertEq(address(module), address(singleProjectModule.module));
        assertEq(isSingleProject, true);
        assertEq(active, true);
    }

    function test_removeProjectModule() public {
        vm.startPrank(admin);

        // Add module
        vault.addModule(mockModule, false, 0);

        // Store initial length
        uint256 initialLength = vault.getModulesLength();

        // Remove module
        vault.removeModule(0);

        // Verify length decreased
        assertEq(vault.getModulesLength(), initialLength - 1);

        // Verify we can't access the removed index
        vm.expectRevert();
        vault.getModule(0);

        vm.stopPrank();
    }

    function toWei(uint256 amount) internal pure returns (uint256) {
        return amount * PRECISION;
    }

    function fromWei(uint256 amount) internal pure returns (uint256) {
        return amount / PRECISION;
    }
}
