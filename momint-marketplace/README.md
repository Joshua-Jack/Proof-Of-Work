## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
## RWA Marketplace Documentation

## Contract Addresses 
  - ERC1155RWA Implementation: 0x9bd61Df3B2bCa7f403F0eA59c86c8E6b032fbAf9
  - Proxy Admin: 0x378c2DD48f2c8EC91734c036a6227aAdD0016f58
  - ERC1155RWA Proxy: 0x592b312ef9fE0602463588117E3039a3907118C3
  - Marketplace Implementation: 0x0e7471096704c969dB48e747a8f265194A0054AA
  - Proxy Admin: 0xc2Ff2e91A4A80e8b88C2eFf08f2B76790FFDa85C
  - Marketplace Proxy: 0xFb70098882BEf5198fE3294fBd3D026741E1B59F
  - MarketplaceController deployed at: 0x239dF500874530EF5C8EBc795b188472dFbe8E7d
  - Admin address: 0x5C614f5e552295365D0Df72091b727301e5f231D
  - VaultStorage: 0x76f1f533aEd5b309d4dA315B30c28f89466EcD2a
  - ModuleStorage: 0x949bD1f9cAE7e33aF989094C83DA0145B0403e8A
  - ContractStorage: 0x1a10eAD27d7E74b4D1Bf6AEeCE7bCe590888C893
  - Factory: 0x98C69E5F6d3F518524936d3929FC9a1ae17b6319
  - Momint Vault Implementation: 0x5203A46A57F34c0644d1F1b87328C36ffE3E68F2
  - ModuleImplementation SPModule: 0x0f8296EEe6446047Da99Aab5191e793c7bcB109D
  - VaultController: 0xEAAe80ED7FEA4957aF97D6cfc06Efda02D125aE3

### Overview
The Momint Marketplace System is a solution for trading Real World Assets (RWA) tokens. It consists of the following three main components:

## **ERC1155 RWA Token Contract**
The ERC1155RWA contract is desinged for tokenizing real-world assets (RWAs) with built-in royalty support. This contract enables efficient multi-asset management while ensuring royalty distribution.

## **Key Features**
- **Multi-Token Support**: One contract can manage multiple asset types.
- **Royalty Mechanism**: Integrates ERC-2981 for royalty management.
- **Upgradeable Design**: Ensures future-proofing and contract enhancements.
- **Role-Based Access Control**: Provides secure function calling.
- **Pausable Functionality**: Enables emergency stop mechanisms.
- **Supply Tracking**: Keeps record of token issuance.

## **Minting Tokens**
To mint a new token:
```solidity
mint(
    uint256 amount,
    string memory uri,
    address[] memory royaltyRecipients,
    uint256[] memory shares
);
```
- Creates a new token with unique metadata and tokenId.
- Assigns royalties to specified recipients.
- Defines royalty share percentages.

## **Batch Operations**
The contract also supports batch operations:
```solidity
batchMint();
```
- Allows multiple tokens to be minted in a single transaction.
- Reduces gas costs and improves scalability.

## **Security Considerations**
### **Access Control**
- Only authorized users can mint tokens.
- Admins have control over fee configurations.
- Only accepted payment tokens are allowed to be used as the buy token.

### **Safety Mechanisms**
- Emergency stop functionality.
- Reentrancy protection to prevent exploits.
- Non-Zero checks to ensure outcome is what we intend

## **RWA Royalty System**
The royalty system is designed for efficent payment distribution upon sales.

### **Royalty Configuration**
```solidity
struct RoyaltyInfo {
    address[] recipients;  // Royalty receivers
    uint256[] shares;      // Shares in basis points (1 BP = 0.01%)
}
```
- Total basis points = 10000 (100%).
- Example allocations:
  - 5% royalty = 500 basis points.
  - 2.5% royalty = 250 basis points.

### **Setting Royalties During Minting**
Example configuration for multiple recipients:
```solidity
address[] memory recipients = new address[](2);
recipients[0] = address1;
recipients[1] = address2;

uint256[] memory shares = new uint256[](2);
shares[0] = 500; // 5%
shares[1] = 300; // 3%

uint256 tokenId = rwaToken.mint(
    1000,           // Amount
    "ipfs://...",  // Metadata URI
    recipients,     // Recipients
    shares          // Shares
);
```

### **Updating Existing Royalties**
```solidity
function setRoyalties(
    uint256 tokenId,
    address[] memory recipients,
    uint256[] memory shares
) external;
```
- Allows modifications to royalty allocations.

## **Royalty Distribution Process**
### **1. Sale Price Calculation**
For a sale price of **100 USDT**, with:
- 5% primary royalty
- 3% secondary royalty
- 2.5% protocol fee

**Distribution:**
1. Protocol Fee: **2.5 USDT**
2. Primary Royalty: **5 USDT**
3. Secondary Royalty: **3 USDT**
4. Seller Receives: **89.5 USDT**

### **2. Payment Flow**
```solidity
function _handlePayment(
    uint256 listingId,
    uint256 amount,
    address buyer
) internal returns (uint256 totalPrice);
```
- Calculates total price.
- Deducts protocol fees.
- Distributes royalties before finalizing transaction and sending the seller the remaining assets.

## **Implementation Example**
Creating a new RWA token with royalties:
```solidity
function createTokenWithRoyalties() external {
    address[] memory recipients = new address[](3);
    recipients[0] = projectOwner;
    recipients[1] = artistAddress;
    recipients[2] = platformWallet;

    uint256[] memory shares = new uint256[](3);
    shares[0] = 500; // 5% to project owner
    shares[1] = 300; // 3% to artist
    shares[2] = 200; // 2% to platform

    uint256 tokenId = rwaToken.mint(
        initialSupply,
        metadataUri,
        recipients,
        shares
    );
}
```

## **Royalty Validation and Safety Checks**
1. **Array Consistency**: Recipients and shares arrays must match in length.
2. **Non-Zero Addresses**: Recipients cannot be the zero address.
3. **Total Shares Cap**: Cannot exceed 10000 (100%).
4. **Valid Share Values**: Each share must be greater than zero.

## **Querying Royalty Information**
To retrieve royalty details for a specific token and sale price:
```solidity
function getRoyaltyDetails(
    uint256 tokenId,
    uint256 salePrice
) external view returns (
    address[] memory recipients,
    uint256[] memory amounts
);
```
- Returns the recipients and their respective payout amounts.
- Helps marketplaces ensure proper royalty distribution.

## **Marketplace Contract**
Overview
The RWA Marketplace enables users to trade tokenized real-world assets seamlessly. It integrates directly with the ERC1155RWA token contract to ensure automated royalty distributions and supports various payment tokens for transactions.

## **Key Features**
- **Multi-Payment Support**: Accepts multiple ERC20 tokens for purchases (LISK, USDT, etc.).
- **Secure Escrow System**: Holds tokens in custody during active listings with automated return mechanisms.
- **Automated Fee Distribution**: Handles protocol fees and royalty payments with configurable fee structures.
- **Batch Operations**: Supports purchasing from multiple listings in one transaction for gas efficiency.
- **Emergency Controls**: Includes pause and emergency withdrawal functionality for risk management.
- **Listing Management**: Complete control over listing creation, cancellation, and updates.


## **Listing Structure**
Each listing in the marketplace is defined by the following structure to ensure proper listing managment:

seller: The address of the token owner initiating the sale.
tokenId: The unique identifier of the RWA token being listed.
amount: The number of tokens available for sale.
pricePerToken: The selling price for each token unit.
paymentToken: The type of payment token accepted (e.g., USDT, LISK).
active: Indicates whether the listing is currently active.

## **Creating a Listing**
To list RWA tokens for sale, the following function is used:

```solidity
function createListing(
    uint256 tokenId,
    uint256 amount,
    uint256 pricePerToken,
    address paymentToken
) external;
```
Process:
- Token Transfer: Transfers the specified amount of tokens from the seller to the marketplace's custody.
- Listing Details: Sets all details needed for the listing structure.
- Unique ID Generation: Generates a unique identifier for the new listing.
- Active Listing: Listing becomes active and will be ready for purchases. 

## **Purchasing an RWA Share**
To purchase RWA tokens for sale, the following function is used:

```solidity 
 function buyTokens(
        uint256 listingId,
        uint256 amount
    ) external;
```
Process:
1. Validation:
- Confirms the listing is active.
- Verifies the amount of shares is available.
2. Payment Processing
  - Calculates and deducts protocol fees.
  - Distributes royalties to entitled recipients.
  - Transfers the remaining payment to the seller.
3. Token Transfer and Listing Updates
  - Transfers the purchased shares from the marketplace's custody to the buyer.
  - Adjusts the balance of shares for the RWA if applicable the listing will be set to deactive.
 
## **Canceling a Listing**
To cancel the listing of an RWA that is currently listed, the following function is used:

```solidity 
 function cancelListing(
        uint256 listingId
    ) external;
```
1. Validation:
 - Listing exists and is active
 - Caller is the original seller
2. State Updates
 - Marks listing as inactive
3. Token Transfer
  - Transfer tokens back to seller

 ## **Buy Multiple RWA'S from multiple listings**  
 To purchase multiple RWA's for sale, the following function is used:
```solidity 
 function batchBuyTokens(
        uint256[] calldata listingIds,
        uint256[] calldata amounts
    ) external;
```
The batch minting process mirrors the same process of purchasing from a single listing, with the main difference being that the system will handle multiple real-world assets (RWAs) the user intends to buy. All associated fees and royalties will be distributed as intended.

## The Momint Vault System 
The Momint Vault System is designed to standardize the investment process for users looking to acquire RWAs (Real-World Assets). The system consists of the following key components:

- Vault Controller
- Momint Vault
- Modules


### Vault Controller
The Vault Controller is responsible for managing accounting, handling emergency scenarios, and deploying/storing modules, vaults, and new contracts within the system. Further the vault manages a multi-fee structure that covers various operational aspects.

### Emergency Functions
The Vault Controller has the ability to pause and unpause a single vault or all deployed vaults. Additionally, it can withdraw liquidity from a single vault or all vaults in case of emergencies.

### Deployment of Modules, Vaults, and Contracts
When deploying vaults and modules inside the Vault Controller follows these steps:

- Contract Deployment: First, a contract is deployed, which can be either a module or a vault.
- Storage: The deployed contract is stored inside the contract storage. This allows multiple versions of vaults and modules to be stored for later deployment.
- Cloning: Instead of deploying a new contract every time, stored contracts can be cloned for reuse. Example: If an ERC-1155 module is deployed and stored, it can be cloned and used for multiple projects.

To deploy a vault, the following function is used:
```solidity
function deployVault(bytes32 id_, bytes calldata data_) external; 
```
To deploy a module, the following function is used:
```soldity
function deployModule(bytes32 id_, bytes calldata data_) external;
```

Once a vault and module are deployed, the final step is to link them using:

```solidity
function addModule(address vault_, uint256 index_, bytes32 moduleId_)
```



### Vault Info 
- baseAsset: The underlying liquidity token (e.g., USDC).
- symbol: The token symbol for the vault shares (e.g., $SL).
- shareName: The full name of the vault share token (e.g., $SOLAR).
- owner - The vault owner’s address.
- feeRecipient - The protocol address that will receive transaction fees.
- fees - A structured fee model, explained below.
- liquidityHoldBP - Determines the percentage of deposits held as liquid reserves in the vault (measured in basis points).
- maxOwnerShareBP - Defines the maximum percentage of funds that can be allocated to project owners (measured in basis points).

To retrive this information we call the following function inside the module  

```solidity 
function getVaultInfo();
```

### Project Info 
Each module created will have its own distinct project details. 

- id - The token ID of the projects real world assets
- name – The name of the project.
- pricePerShare – The price of one share in the project.
- availableShares – The number of shares that are still available for purchase.
- allocatedShares – The number of shares that have already been bought by users.
- totalShares – The total number of shares minted when the project was created (e.g., if the project represents solar panels, this is the total number of panels).
- tokenURI – A link to metadata associated with the project
- owner – The address of the project owner, who has administrative control over the project.

To retrive this information we call the following function inside the module  

```solidity
function getProjectInfo 
```

### **Fee Types**

1. **Deposit Fee**  
   - **Charged on deposit**  
   - **Default:** 5% (500 basis points)  
   - **Calculation:** `depositAmount * (depositFee / 10000)`  
   - **Adjustable by governance**  

2. **Withdrawal Fee**  
   - **Charged on withdrawal**  
   - **Default:** 1% (100 basis points)  
   - **Calculation:** `withdrawAmount * (withdrawalFee / 10000)`  
   - **Adjustable by governance**  

3. **Protocol Fee**  
   - **Platform operation fee**  
   - **Default:** 3% (300 basis points)  
   - **Applied to returns**  
   - **Adjustable by governance**  

### Momint Vault
The momint vault is an erc4626 vault designed to handle erc20 managment for users and project owners. This vault gives users the following abilities: 

- Deposit
   The users can deposit the underlying token inside the vault and will recive the vault token which are shares based on the module that was used.
- Withdraw 
  The users can sell back there vault token(share token) back to the vault to recive back their underlying asset they origanlly deposited 
- Redeem 
  The users will have the ability to claim their part of the revenue generated by projects 

The vault will give the project owners the following abilities: 

- DistributeReturns - 
  The project owners will have the ability to deposit into the vault the ROI from the projects.

- ClaimOwnerAllocation -
  The project owners will have the ability to get their share of the liqudity inside the vault meaning what they have sold. 


Now that we understand the main features we can dive into the main flows of the momint vault and how it connects with the modules. The main flows we have are the following 

- Deposit 
- Withdraw 
- Distribute and Claim 
- Project Owner Allocation 

**Deposit** 
![MomintDepo](https://github.com/user-attachments/assets/0e6641a5-50c7-47b8-8c81-da3bc7b900ad)


When a user deposits inside of the momint vault they will use the following function 

```solidity 
function deposit(
        uint256 assets_,
        uint256 index_
    ) external
```

This function accepts the share amount and a specific project index. When a user provides an index (e.g., index 1), all calculations and operations will be applied to that particular project.

Fee Calculation & Distribution:

The function first calculates all applicable fees.
Fees are automatically deducted and sent to their respective destinations.

Retrieving the Project Module:

The function retrieves the contract address associated with the given project index from storage.
This contract corresponds to a module, which represents the project.

Calling the Investment Function:

The function then calls the invest function on the module.

Each module follows a standardized structure and containing its own logic for handling investments.

Processing Shares & Refunds:

The module determines how the investment should be processed.
It calculates the number of shares to allocate to the user.
If necessary, it also calculates any refunds.

Minting Shares:
Once the module returns the calculated share amount, the vault mints the shares and the module updates the state and assigns the shares to the user.

Automated Liquidity Partitions:
The liquidity generated from a sale will be automatically allocated to the appropriate destinations.

**Withdraw**
When a user wants to get their underlying assets back they will use the following function 

```solidity
 function withdraw(
        uint256 shares,
        uint256 index_
    ) external
```

This function allows users to burn their shares from a project and withdraw their underlying vault liquidty token.

Retrieving the Project Module:

The function takes the number of shares the user wants to burn and the project index.
It retrieves the corresponding contract address for the project, just as in the deposit function.

Validation Checks:
The function verifies that the user has enough shares to withdraw this is checking the module.

Calling the Divest Function:
The function calls the divest function on the module.
Each module follows a standardized structure and manages its own divestment calculations.

Processing the Withdrawal:
The module determines the amount of underlying liqudity tokens to return.
Once the vault receives this information, it performs the final calculations.

Liquidity Check:
The vault ensures that there is enough available liquidity to process the withdrawal.
If there isn’t sufficient liquidity, the user must wait until more funds become available.

Finalizing the Transaction:
If liquidity is available, the function burns the user’s shares.
The corresponding amount of the underlying liquity token is then transferred back to the user.

**Shares Explination**
In the system, each project is allocated a specific number of shares on creation of their project. For example, if a project is assigned 100 shares, only those 100 share tokens can be sold. When a user invests in that project, they can acquire up to the available 100 shares. This structure renders the total number of shares in the vault irrelevant because, although the vault may contain 300 minted shares, these shares must originate from a project. Therefore, a user can only obtain shares after a project's allocation has been determined.


**Distribute and Claim**
The distribution system manages how investment returns are distributed to projects through a structured epoch-based mechanism. When an project owner wants to distrubute returns to their share holders they will use the following function 

```solidity
function distributeReturns(
        uint256 amount,
        uint256 index_
    ) external
```

This function ensures that investment returns are fairly distributed based on share ownership during a specific period.

Retrieving Project Accounting Data:

The function first retrieves the necessary accounting details from the project.
This data is used inside the vault to calculate distributions while ensuring adherence to the 1:1 whole-share model (only whole shares can be bought or sold).
Creating a Returns Epoch:

A returns epoch is established to manage and track revenue distribution.
The epoch ensures fair distribution based on when users held shares.
It organizes distributions into distinct time periods for structured revenue allocation.
Claiming Returns:

Once an epoch is created, users become eligible to claim their share of the returns.
To do so, they use the designated claim function, which verifies eligibility before distributing funds.

```solidity
 function claimReturns(
        uint256 index_,
        uint256 epochId_
    ) external
```

This function allows users to claim their share of returns from a specific project and epoch.

Selecting the Epoch and Project:

The function takes the epoch ID (the specific distribution period) and the project it belongs to.
Validation Checks:

Ensures the user has not already claimed from the selected epoch.
Verifies that the user holds shares in the project.
Applies dust control measures to prevent insignificant or unnecessary claims.
Reward Distribution:

If all checks pass, the function releases the user's share of the underlying asset stored in the vault.

**Project Owner Allocation** 
The vault is designed to autonomously manage its liquidity through multiple channels. One of these channels are deposits. When users deposit funds, these assets increase the vault's liquidity. Now when the vault gets this liqudity it will be partitioned. X percent to the vaults liqudity and X percent allocated to the project owner. Now project owners can claim their sales from the following function. 

```solidity
 function claimOwnerAllocation()
```

This function performs several checks and calculations:
  
  1. Allocation Check:
    - Confirms if the caller has any unclaimed allocation.
    - Ensures the total allocated amount is greater than what has already been released.

  2. Release Calculation:
    - Calculates the time elapsed since the last release.
    - Calculates the release amount based on:
    - Total allocated amount
    - Time elapsed
    - Release period
    - Number of release portions

   3. Amount Validation:
    - Caps the release to the remaining unclaimed balance.
    - Ensures the vault has enough liquidity to process the claim.

**Key Points About Vesting:**

- Vesting follows a linear release over the RELEASE_PERIOD.
- The total allocation is split into RELEASE_PORTIONS.
- Each claim calculates the amount that can be released based on elapsed time.
- A project owner cannot claim more than the available liquidity in the vault.
- Keeps track of released amounts to prevent double claims.

**Why This Matters**
This system balances liquidity and ownership distribution:

- Project owners receive their share progressively over time.
- The vault ensures there’s always enough liquidity for withdrawals.
- User deposits are properly split between liquidity reserves and project owner allocations.



**Liqudity Utility Functions**
Inside the vault their are function that are used as utility this will allow vault admins to deposit into the vault incase there needs to be more liqudity added. This will be done from the following function 

```solidity
function depositLiqudity(
        uint256 assets_,
        uint256 index_
    ) external
```

This function will record how much liqudity has been added by the vault owner. 







##**Addressing the Core Problem**

  1. Problem: Complex buyer journey and limited liquidity
  2. Solution: Our system implements:
A marketplace for easy trading of RWA tokens
Batch buying functionality for multiple assets
Standardized pricing and trading interface
Support for multiple payment tokens (USDT, LISK)

**Technical Implementation Benefits**
ERC1155 RWA Token:
Efficiently handles multiple assets under one contract
Supports detailed metadata for each asset
Enables fractional ownership while preserving asset specificity

**Marketplace System:**
Simplifies the buying/selling process
Provides liquidity through an organized marketplace
Supports batch operations for efficient trading
Implements automated royalty and fee distribution

**Vault System Advantages**
The Momint Vault system particularly addresses the problem by:
Standardizing The Investment Process:
Users can deposit assets and receive standardized vault shares
Maintains 1:1 relationship between shares and underlying assets
Simplifies the investment process while maintaining asset specificity

**Liquidity Management:**
Automated liquidity provision through the vault system
Project owner allocations managed systematically
Built-in mechanisms for distributing returns

**Modular Architecture:**
Supports different types of RWAs through modules
Each project can have its own specific implementation
Built for scalability

**Hybrid Functionality:**
Combines NFT benefits with ERC20-like trading experience
Supports both individual asset tracking and pooled investments
Enables complex revenue distribution through epochs

**Compliance:**
Maintains clear ownership records
Supports royalty distribution
Includes emergency controls and pause mechanisms

**Future-Proofing**
The system is designed for extensibility through:
Upgradeable contracts
Modular architecture
Flexible fee structures
Support for multiple payment tokens
Ability to add new features through modules
