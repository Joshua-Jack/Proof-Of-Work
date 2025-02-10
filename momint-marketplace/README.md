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

## **The Momint Vault System** 
The momint vault system is designed to standardize the investment process for users wanting to aqurie RWA's. The system is made up of the following key components 

- Vault Controlle
- Momint Vault 
- Modules 


**Vault Controller**
The vault controller is created to manage accounting,emergency scenrios, deploying and storing of modules, vaults and new contracts we want to add to the system. Part of the accounting the vault manages is the multi fee structure managing various operational aspects

### Fee Types

 **Deposit Fee**
    - Charged on deposit
    - Default: 5% (500 basis points)
    - Calculation: `depositAmount * (depositFee / 10000)`
    - Adjustable by governance
 **Withdrawal Fee**
    - Charged on withdrawal
    - Default: 1% (100 basis points)
    - Calculation: `withdrawAmount * (withdrawalFee / 10000)`
    - Adjustable by governance
 **Protocol Fee**
    - Platform operation fee
    - Default: 3% (300 basis points)
    - Applied to returns
    - Adjustable by governance

The emergency functions the controller has access it is the ability to pause and unpause a single vault or all vaults deployed. Further this contract has the ability to withdraw the liqudity in a single vault or in all vaults deployed. 

The deploying of modules, vaults and contracts. The vault controller when it comes to deployment of vaults and modules works as the following. First we will deploy a contract this contract can be either a module or a vault. This will get stored inside the contract storage. The contract storage allows us to put as many vault versions and module versions we would like so we can use them for deployment. Once we have the contracts inside the contract storage we can then move to deployment of a module or a vault. Note the reason we will deploy a contract first and store it is so that we can create once and clone as many times as we like. Example of this we have currently an ERC1155 module and this module is used specifically for projects now once we deploy that and its stored we can clone it for as many projects as we want. Now moving on to deploying a new vault and adding a module. The contract storage contract will use a unique identifier when a contract is store we will use the following function with the same unique id that we used to store the contract to get the contract address and clone it. 

```solidity
function deployVault(bytes32 id_, bytes calldata data_) external; 
```

We will follow this same pattern with the modules. 

```soldity
function deployModule(bytes32 id_, bytes calldata data_) external;
```

Now once we have our vault and module deployed we can call the final function which is to add the module to the vault. 

```solidity
function addModule(address vault_, uint256 index_, bytes32 moduleId_)
```

Note each module and vault will have their own information attached to it. What this means is that when a vault is deployed we set the name of the vault and its new vault tokens name and symbol inside of a vault struct. We can simply get this information by call the function 

```solidity 
function getVaultInfo();
```

The same will go for every module that is deployed all modules will follow a standard and part of that standard is that we know what the module is. The information we set for our current module we have is the following. 

```solidity
struct ProjectInfo {
        uint256 id;
        string name;
        uint256 pricePerShare;
        uint256 availableShares;
        uint256 allocatedShares;
        uint256 totalShares;
        bool active;
        string tokenURI;
        address owner;
    }
```

We can again simply get this information by calling the following function 

```solidity
function getProjectInfo 
```

**Momint Vault**
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
When a user deposits inside of the momint vault they will use the following function 

```solidity 
function deposit(
        uint256 assets_,
        uint256 index_
    ) external
```

This function takes the assets and a specific project index. This means that when index 1 is passed all calculations will be handled on that project. The deposit function will first go and calculate all the fee's and automatically send them to where they should be distrubuted to. After this the function will grab a the contract address at the index that was passed. This contract that the function is grabbing is a module address which again is a project. We will call the invest function inside of the module note this is also part of the module standard. The invest function will go to the module and the module itself will have its own calculations on how an investment works and how many shares should be giving to the user and if there needs to be any assets refunded. After the module sends back the calulation of share amounts we then will mint that amount back to the user. Note inside the system we follow a 1:1 approach meaning you need to buy at whole. There will not be 0.5 share it has to be 1 share minimum.


**Withdraw**
When a user wants to get their underlying assets back they will use the following function 

```solidity
 function withdraw(
        uint256 shares,
        uint256 index_
    ) external
```

This function takes the shares they want to burn and the specific project index. This function will follow the same method of grabing the address from the index as per the deposit function. The withdraw function will check all common check exmaple balance of the user to ensure they have shares. Now we will be calling the divest function inside of the module and again this is also part of the module standard. The divest function will go to the module and the module itself will handle all divestments calculations so when we get the amount back we can perform the proper calculations inside the vault. We will be checking to ensure we have enough liqudity inside the vault to ensure we can make the withdraw if there is no liqudity the user will have to come back when liqudity is available. After we made this check we move onto burning of the shares and transfering the underlying assets back to the user. 

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

This function will first go to the project and get the needed accounting functions. These function will be utilized inside the vault to calculate the distrubution and ensure we follow the 1:1 buy at whole. After this we will create a returns epoch. The epochs are created to ensure fair distribution of returns based on when users held shares, tracks and manage distributions in a organized way, represents a distinct period of returns/revenue distribution. Once the epoch is created users are able to claim on the epoch. The users will use the following function to claim their returns. 

```solidity
 function claimReturns(
        uint256 index_,
        uint256 epochId_
    ) external
```

This function will take the epoch id in which the user wants to claim from and the project in which the epoch belongs to. From here the function will check to ensure that the user hasnt already claimed from this epoch, holds shares inside the project and ensures it follows our dust controll. Once the checks pass the user will receive the underlying asset in the vault as their reward. 

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
