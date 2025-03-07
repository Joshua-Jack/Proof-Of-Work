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
import {VaultInfo} from "../../src/interfaces/IMomintVault.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {stdError} from "forge-std/Test.sol";

// MomintVaultTests.t.sol
contract MomintVaultTests is TestSetup {
    uint256 constant DECIMALS = 6;
    uint256 constant PRECISION = 10 ** DECIMALS;
    uint256 constant PROJECT_ID = 1;
    uint256 constant PRICE_PER_SHARE = 1e18; // $1 in 18 decimals
    uint256 constant TOTAL_SHARES = 1000 * PRECISION;
    uint256 constant MAX_BASIS_POINTS = 10000; // 100%
    string constant URI = "ipfs://metadata";
    string constant PROJECT_NAME = "Test Solar Project";
    Module public mockModule;
    error NoSharesOwned();
    error InvalidAmount();
    error InvalidInitialization();
    error InvalidReceiver();
    error InvalidFeeRecipient();
    error InvalidAssetAddress();
    error EnforcedPause();
    error AlreadyClaimed();
    error InvalidEpochId();
    error InvalidModuleAddress();
    error Unauthorized();

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

        // Make sure admin has necessary permissions and USDT
        vm.startPrank(admin);

        // Deal USDT to admin for distributions
        deal(address(USDT), admin, 1000000 * 10 ** 6); // 1M USDT

        // Initialize with default liquidity ratios
        uint16 defaultLiquidityHoldBP = 3000; // 30%
        uint16 defaultMaxOwnerShareBP = 7000; // 70%
        vault.updateLiquidityRatios(
            defaultLiquidityHoldBP,
            defaultMaxOwnerShareBP
        );
        vm.stopPrank();

        // Deal USDT to users for deposits
        deal(address(USDT), user1, 100000 * 10 ** 6); // 100k USDT
        deal(address(USDT), user2, 100000 * 10 ** 6); // 100k USDT
        deal(address(USDT), user3, 100000 * 10 ** 6); // 100k USDT
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

    function test_liquidityRatios() public {
        console.log("\n=== Starting liquidity ratios test ===");

        // Get initial ratios
        (
            uint16 currentMinLiquidity,
            uint16 currentMaxOwner,
            uint16 absoluteMinLiquidity,
            uint16 absoluteMaxOwner
        ) = vault.getLiquidityRatios();

        console.log("Initial ratios:");
        console.log("- Current min liquidity:", currentMinLiquidity);
        console.log("- Current max owner:", currentMaxOwner);
        console.log("- Absolute min liquidity:", absoluteMinLiquidity);
        console.log("- Absolute max owner:", absoluteMaxOwner);

        // Update ratios as admin
        vm.startPrank(admin);
        uint16 newMinLiquidity = 4000; // 40%
        uint16 newMaxOwner = 6000; // 60%

        vault.updateLiquidityRatios(newMinLiquidity, newMaxOwner);

        // Verify new ratios
        (currentMinLiquidity, currentMaxOwner, , ) = vault.getLiquidityRatios();
        assertEq(
            currentMinLiquidity,
            newMinLiquidity,
            "Min liquidity not updated"
        );
        assertEq(currentMaxOwner, newMaxOwner, "Max owner not updated");

        vm.stopPrank();
        console.log("\nUpdated ratios:");
        console.log("- New min liquidity:", currentMinLiquidity);
        console.log("- New max owner:", currentMaxOwner);
    }

    function test_RevertCantTransferShares() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User2 deposits
        vm.startPrank(user2);
        USDT.approve(address(vault), 10e6);
        uint256 shares = vault.deposit(10e6, user2, 0);
        vm.stopPrank();

        // Ensure admin has enough USDT for distribution
        vm.startPrank(admin);
        USDT.approve(address(vault), 10e6);
        vault.distributeReturns(10e6, 0);
        vm.stopPrank();

        // Check initial balances
        console.log("\nInitial state:");
        console.log("User2 shares:", vault.balanceOf(user2));
        console.log("User3 shares:", vault.balanceOf(user3));

        // User2 transfers half their shares to user3
        vm.startPrank(user2);
        address shareToken = address(vault);
        console.log("Share token address:", shareToken);

        uint256 sharesToTransfer = shares / 2;
        vm.expectRevert("Not allowed");
        IERC20(shareToken).transfer(user3, sharesToTransfer);
        vm.stopPrank();
    }

    function test_ownerAllocation() public {
        console.log("\n=== Starting owner allocation test ===");

        // Setup
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User deposit
        vm.startPrank(user1);
        uint256 depositAmount = 100e6; // 100 USDT
        USDT.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1, 0);
        vm.stopPrank();

        // Get project owner
        address projectOwner = SPModule(address(singleProjectModule.module))
            .getProjectInfo()
            .owner;

        console.log("\nProject owner details:");
        console.log("- Address:", projectOwner);

        // Fast forward time
        vm.warp(block.timestamp + 7 days);

        // Owner claims allocation
        vm.startPrank(projectOwner);
        uint256 balanceBefore = USDT.balanceOf(projectOwner);

        vault.claimOwnerAllocation();

        uint256 claimed = USDT.balanceOf(projectOwner) - balanceBefore;
        console.log("\nOwner claim results:");
        console.log("- Amount claimed:", claimed);

        vm.stopPrank();
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

        // Calculate expected splits
        uint256 expectedFee = (depositAmount * 500) / 10000; // 5% fee
        uint256 netAmount = depositAmount - expectedFee;
        uint256 expectedLiquidity = (netAmount * 3000) / 10000; // 30% liquidity
        uint256 expectedOwner = (netAmount * 7000) / 10000; // 70% owner

        console.log("Expected splits:");
        console.log("- Fee:", expectedFee);
        console.log("- Liquidity:", expectedLiquidity);
        console.log("- Owner:", expectedOwner);
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
        uint256 withdrawnAmount = vault.withdraw(withdrawShares, user2, 0);

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

    function test_UpdatePricePerShare() public {
        // Setup
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);

        // Initial price check
        uint256 initialPrice = SPModule(address(singleProjectModule.module))
            .getProjectInfo()
            .pricePerShare;

        // Update price
        uint256 newPrice = 100e6;
        SPModule(address(singleProjectModule.module)).updatePricePerShare(
            newPrice
        );

        // Verify price update
        uint256 updatedPrice = SPModule(address(singleProjectModule.module))
            .getProjectInfo()
            .pricePerShare;
        assertEq(updatedPrice, newPrice, "Price not updated correctly");
        assertNotEq(updatedPrice, initialPrice, "Price should have changed");

        vm.stopPrank();
    }

    function test_RevertUpdatePricePerShare_NonOwner() public {
        // Setup
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // Try to update price as non-owner
        vm.startPrank(user1);
        vm.expectRevert(SPModule.Unauthorized.selector);
        SPModule(address(singleProjectModule.module)).updatePricePerShare(
            100e6
        );
        vm.stopPrank();
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

    function test_RevertWhen_InsufficientLiquidity() public {
        // Setup
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        singleProjectModule.isSingleProject = true;
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User deposit
        vm.startPrank(user1);
        uint256 depositAmount = 100e6; // 100 USDT
        USDT.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1, 0);

        // Simulate liquidity drain by transferring most USDT out of vault
        // This simulates the vault investing funds elsewhere
        vm.stopPrank();
        vm.startPrank(address(vault));
        uint256 vaultBalance = USDT.balanceOf(address(vault));
        uint256 drainAmount = (vaultBalance * 95) / 100; // Leave only 5% liquidity
        USDT.transfer(address(0x1), drainAmount);
        vm.stopPrank();

        // Calculate buffer requirement
        uint256 totalAssets = vault.totalAssets();
        uint256 bufferRequired = (totalAssets * vault.BUFFER_THRESHOLD_BP()) /
            MAX_BASIS_POINTS;
        console.log("Total Assets:", totalAssets);
        console.log("Buffer Required:", bufferRequired);
        console.log("Vault Balance:", USDT.balanceOf(address(vault)));

        // Try to withdraw - should revert due to insufficient liquidity
        vm.startPrank(user1);
        vm.expectRevert("Insufficient liquidity");
        vault.withdraw(shares, user1, 0);
        vm.stopPrank();
    }

    // Add these to your existing contract
    function _deployNewVault() internal returns (MomintVault) {
        address implementation = address(new MomintVault());
        address vaultNewAddress = Clones.clone(implementation);
        return MomintVault(vaultNewAddress);
    }

    function _getDefaultInitParams() internal view returns (VaultInfo memory) {
        return
            VaultInfo({
                baseAsset: USDT,
                feeRecipient: feeRecipient,
                owner: admin,
                shareName: "Test Vault",
                symbol: "TV",
                fees: VaultFees({
                    depositFee: 500,
                    withdrawalFee: 100,
                    protocolFee: 300
                }),
                liquidityHoldBP: 3000,
                maxOwnerShareBP: 7000
            });
    }

    function test_RevertWhen_InitializeWithZeroAsset() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();
        params.baseAsset = IERC20(address(0));

        vm.expectRevert(InvalidAssetAddress.selector);
        newVault.initialize(params);
    }

    function test_RevertWhen_InitializeWithZeroFeeRecipient() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();
        params.feeRecipient = address(0);

        vm.expectRevert(InvalidFeeRecipient.selector);
        newVault.initialize(params);
    }

    function test_RevertWhen_InitializeWithLowLiquidityRatio() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();
        params.liquidityHoldBP = 500; // Below minimum

        vm.expectRevert("Liquidity ratio too low");
        newVault.initialize(params);
    }

    function test_RevertWhen_InitializeWithHighOwnerShare() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();
        params.maxOwnerShareBP = 9500; // Above maximum

        vm.expectRevert("Owner share too high");
        newVault.initialize(params);
    }

    function test_RevertWhen_ReinitializingVault() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();

        // First initialization
        newVault.initialize(params);

        // Attempt to reinitialize
        vm.expectRevert(InvalidInitialization.selector);
        newVault.initialize(params);
    }

    function test_RevertWhen_InitializeWithInvalidRatioConfig() public {
        MomintVault newVault = _deployNewVault();
        VaultInfo memory params = _getDefaultInitParams();
        params.liquidityHoldBP = 5000;
        params.maxOwnerShareBP = 6000;
        // Total exceeds MAX_BASIS_POINTS (10000)

        vm.expectRevert("Invalid ratio configuration");
        newVault.initialize(params);
    }

    function test_RevertWhen_DepositZeroAmount() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(InvalidAmount.selector);
        vault.deposit(0, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_DepositToZeroAddress() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(InvalidReceiver.selector);
        vault.deposit(100e6, address(0), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_DepositWithInvalidModuleIndex() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(stdError.indexOOBError);
        vault.deposit(100e6, user1, 999);
        vm.stopPrank();
    }

    function test_RevertWhen_DepositWhenPaused() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vault.pause();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(EnforcedPause.selector);
        vault.deposit(100e6, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_DepositExceedingAvailableShares() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 maxShares = SPModule(address(singleProjectModule.module))
            .getAvailableShares();
        uint256 tooManyShares = maxShares + 1e6;
        USDT.approve(address(vault), tooManyShares);

        vm.expectRevert(InvalidAmount.selector);
        vault.deposit(tooManyShares, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingReturnsTwice() public {
        // Setup and initial deposit
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        USDT.approve(address(vault), 100e6);
        vault.deposit(100e6, user1, 0);
        vm.stopPrank();

        // Distribute returns
        vm.startPrank(admin);
        USDT.approve(address(vault), 10e6);
        vault.distributeReturns(10e6, 0);
        vm.stopPrank();

        // First claim should succeed
        vm.startPrank(user1);
        vault.claimReturns(0, 1);

        // Second claim should fail
        vm.expectRevert(AlreadyClaimed.selector);
        vault.claimReturns(0, 1);
        vm.stopPrank();
    }

    function test_setVaultFees() public {
        vm.startPrank(admin);
        VaultFees memory newFees = VaultFees({
            depositFee: 300,
            withdrawalFee: 200,
            protocolFee: 400
        });

        vault.setVaultFees(newFees);

        VaultFees memory updatedFees = vault.getVaultFees();
        assertEq(updatedFees.depositFee, 300);
        assertEq(updatedFees.withdrawalFee, 200);
        assertEq(updatedFees.protocolFee, 400);
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerSetsVaultFees() public {
        vm.startPrank(user1);
        VaultFees memory newFees = VaultFees({
            depositFee: 300,
            withdrawalFee: 200,
            protocolFee: 400
        });

        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                user1
            )
        );
        vault.setVaultFees(newFees);
        vm.stopPrank();
    }

    function test_RevertWhen_AddingModuleWithInvalidAddress() public {
        vm.startPrank(admin);
        Module memory invalidModule = Module({
            module: IModule(address(0)),
            isSingleProject: true,
            active: true
        });

        vm.expectRevert(InvalidModuleAddress.selector);
        vault.addModule(invalidModule, false, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_ClaimingInvalidEpoch() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert(InvalidEpochId.selector);
        vault.claimReturns(0, 0);
        vm.stopPrank();
    }

    function test_MultipleEpochDistributions() public {
        // Setup initial state
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User deposits
        vm.startPrank(user1);
        USDT.approve(address(vault), 100e6);
        vault.deposit(100e6, user1, 0);
        vm.stopPrank();

        // Multiple distributions
        vm.startPrank(admin);
        USDT.approve(address(vault), 200e6);
        vault.distributeReturns(100e6, 0);
        vault.distributeReturns(100e6, 0);

        // Verify epoch data
        (uint256 id1, uint256 amount1, uint256 pending1) = vault.getEpochInfo(
            1
        );
        (uint256 id2, uint256 amount2, uint256 pending2) = vault.getEpochInfo(
            2
        );

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(amount1, 100e6);
        assertEq(amount2, 100e6);
        vm.stopPrank();
    }

    function toWei(uint256 amount) internal pure returns (uint256) {
        return amount * PRECISION;
    }

    function fromWei(uint256 amount) internal pure returns (uint256) {
        return amount / PRECISION;
    }

    // Test edge cases for deposit
    function test_deposit_ZeroShares() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        USDT.approve(address(vault), 1); // Tiny amount that would result in 0 shares
        vm.expectRevert(InvalidAmount.selector);
        vault.deposit(1, user1, 0);
        vm.stopPrank();
    }

    // Test max deposit
    function test_deposit_MaxAmount() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 maxAmount = type(uint256).max;
        USDT.approve(address(vault), maxAmount);
        vm.expectRevert(); // Should revert due to overflow
        vault.deposit(maxAmount, user1, 0);
        vm.stopPrank();
    }

    // Test withdraw edge cases
    function test_RevertWhen_Withdraw_ZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert(InvalidAmount.selector);
        vault.withdraw(0, user1, 0);
        vm.stopPrank();
    }

    // Test conversion functions
    function test_convertToShares() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        uint256 assets = 100e6;
        uint256 shares = vault.convertToShares(assets);
        assertGt(shares, 0, "Should convert to non-zero shares");
    }

    // Test preview functions
    function test_previewMint() public {
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        uint256 shares = 100e6;
        uint256 assets = vault.previewMint(shares);
        assertGt(assets, 0, "Should preview non-zero assets");
    }

    function test_emergencyWithdraw() public {
        // Setup initial state

        Module memory singleProjectModule = _createMockModule(admin);
        vm.startPrank(admin);
        vault.addModule(singleProjectModule, false, 0);

        // User deposits
        vm.startPrank(user1);
        uint256 depositAmount = 100e6; // 100 USDT
        USDT.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1, 0);
        vm.stopPrank();

        // Emergency withdrawal
        vm.startPrank(admin);
        vault.pause();

        uint256 vaultBalance = USDT.balanceOf(address(vault));
        uint256 adminInitialBalance = USDT.balanceOf(admin);

        vault.emergencyWithdraw(admin, vaultBalance);

        assertEq(
            USDT.balanceOf(admin),
            adminInitialBalance + vaultBalance,
            "Admin should receive emergency withdrawal"
        );
        assertEq(
            USDT.balanceOf(address(vault)),
            0,
            "Vault should have zero balance after emergency withdrawal"
        );
        vm.stopPrank();
    }

    function test_userTransfer() public {
        // Setup initial state

        Module memory singleProjectModule = _createMockModule(admin);
        vm.startPrank(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        // User1 deposits
        vm.startPrank(user1);
        uint256 depositAmount = 100e6; // 100 USDT
        USDT.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1, 0);

        console.log("Initial deposit shares:", shares);

        // Get initial states
        SPModule module = SPModule(address(singleProjectModule.module));
        (uint256 initialUser1Shares, uint256 initialUser1Invested, ) = module
            .getUserInvestment(user1);

        console.log("Initial User1 shares:", initialUser1Shares);
        console.log("Initial User1 invested:", initialUser1Invested);

        // Transfer half of shares to user2
        uint256 transferAmount = initialUser1Shares / 2;
        console.log("Transferring shares:", transferAmount);

        vault.userTransfer(user2, transferAmount, 0);

        // Get final states
        (uint256 finalUser1Shares, uint256 finalUser1Invested, ) = module
            .getUserInvestment(user1);
        (uint256 finalUser2Shares, uint256 finalUser2Invested, ) = module
            .getUserInvestment(user2);

        console.log("Final User1 shares:", finalUser1Shares);
        console.log("Final User1 invested:", finalUser1Invested);
        console.log("Final User2 shares:", finalUser2Shares);
        console.log("Final User2 invested:", finalUser2Invested);

        // Assertions
        assertEq(
            finalUser1Shares,
            initialUser1Shares - transferAmount,
            "User1 shares not correctly reduced"
        );

        assertEq(
            finalUser2Shares,
            transferAmount,
            "User2 shares not correctly received"
        );

        assertEq(
            finalUser1Invested,
            (initialUser1Invested * finalUser1Shares) / initialUser1Shares,
            "User1 invested amount not correctly reduced"
        );

        assertEq(
            finalUser2Invested,
            (initialUser1Invested * finalUser2Shares) / initialUser1Shares,
            "User2 invested amount not correctly calculated"
        );

        // Verify vault token balances
        assertEq(
            vault.balanceOf(user1),
            shares - transferAmount,
            "User1 vault balance not correctly reduced"
        );

        assertEq(
            vault.balanceOf(user2),
            transferAmount,
            "User2 vault balance not correctly increased"
        );

        vm.stopPrank();
    }

    function test_RevertWhen_UserTransferToZeroAddress() public {
        // Setup
        vm.startPrank(admin);
        Module memory singleProjectModule = _createMockModule(admin);
        vault.addModule(singleProjectModule, false, 0);
        vm.stopPrank();

        vm.startPrank(user1);
        USDT.approve(address(vault), 100e6);
        vault.deposit(100e6, user1, 0);

        vm.expectRevert(InvalidReceiver.selector);
        vault.userTransfer(address(0), 50e6, 0);
        vm.stopPrank();
    }
}
