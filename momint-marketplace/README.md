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
The Momint Vault System is designed to standardize the investment process for users looking to acquire RWAs (Real-World Assets). The system consists of the following key components:

- Vault Controller
- Momint Vault
- Modules


**Vault Controller**
The Vault Controller is responsible for managing accounting, handling emergency scenarios, and deploying/storing modules, vaults, and new contracts within the system. Further the vault manages a multi-fee structure that covers various operational aspects.

## Emergency Functions
The Vault Controller has the ability to pause and unpause a single vault or all deployed vaults. Additionally, it can withdraw liquidity from a single vault or all vaults in case of emergencies.

## Deployment of Modules, Vaults, and Contracts
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



## Vault Info 
- baseAsset: The underlying liquidity token (e.g., USDC).
- symbol: The token symbol for the vault shares (e.g., $SL).
- shareName: The full name of the vault share token (e.g., $SOLAR).
- owner - The vault owner’s address.
- feeRecipient - The protocol address that will receive transaction fees.
- fees - A structured fee model, explained below.
- liquidityHoldBP - Determines the percentage of deposits held as liquid reserves in the vault (measured in basis points).
- maxOwnerShareBP - Defines the maximum percentage of funds that can be allocated to project owners (measured in basis points).

## Project Info 
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
![Uploa<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3984.0685306809382 1921.6608730906528" width="7968.1370613618765" height="3843.3217461813056"><!-- svg-source:excalidraw --><metadata></metadata><defs><style class="style-fonts">
      @font-face { font-family: Virgil; src: url(data:font/woff2;base64,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); }</style></defs><rect x="0" y="0" width="3984.0685306809382" height="1921.6608730906528" fill="#ffffff"></rect><g stroke-linecap="round" transform="translate(10 10) rotate(0 1982.0342653404691 950.8304365453264)"><path d="M32 0 C1574.77 -14.31, 3119.06 -14.74, 3932.07 0 M32 0 C1590.62 9.53, 3148.55 9.6, 3932.07 0 M3932.07 0 C3954.92 1.71, 3965.84 9.21, 3964.07 32 M3932.07 0 C3953.62 2.29, 3962.5 9.01, 3964.07 32 M3964.07 32 C3963.25 765.11, 3963 1499.46, 3964.07 1869.66 M3964.07 32 C3958.68 540.44, 3958.57 1048.79, 3964.07 1869.66 M3964.07 1869.66 C3963.03 1892.33, 3955.18 1900.69, 3932.07 1901.66 M3964.07 1869.66 C3963.31 1891.33, 3951.52 1903.37, 3932.07 1901.66 M3932.07 1901.66 C3123.72 1898.12, 2314.52 1896.92, 32 1901.66 M3932.07 1901.66 C2865.39 1903.7, 1798.95 1903.57, 32 1901.66 M32 1901.66 C12.04 1903.52, -1.28 1890.2, 0 1869.66 M32 1901.66 C12.79 1899.6, 0.18 1892.36, 0 1869.66 M0 1869.66 C-1.72 1199.45, -1.32 530.77, 0 32 M0 1869.66 C-5.45 1335.03, -5.25 800.66, 0 32 M0 32 C0.01 11.02, 12.49 -0.62, 32 0 M0 32 C-0.55 11.37, 9.6 0.59, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g stroke-linecap="round" transform="translate(580.6854067413724 204.11928732073648) rotate(0 524.1571130061559 393.1792985386205)"><path d="M32 0 C318.41 1.52, 604.51 1.43, 1016.31 0 C1041.12 2.72, 1044.98 8.91, 1048.31 32 C1043.35 294.16, 1042.45 554.74, 1048.31 754.36 C1046.44 773.11, 1037.32 783.14, 1016.31 786.36 C673.83 794.03, 334.07 794.03, 32 786.36 C7.68 786.59, -0.47 778.76, 0 754.36 C0.44 508.28, 2.35 259.16, 0 32 C0.12 12.7, 10.02 1.98, 32 0" stroke="none" stroke-width="0" fill="#ffc9c9"></path><path d="M32 0 C419.03 -1.23, 806.58 -0.58, 1016.31 0 M32 0 C267.91 -1.11, 504.27 -0.97, 1016.31 0 M1016.31 0 C1039.42 -1.46, 1048.5 12.66, 1048.31 32 M1016.31 0 C1036.08 -1.65, 1050.6 10.46, 1048.31 32 M1048.31 32 C1047.28 210.49, 1047.51 387.63, 1048.31 754.36 M1048.31 32 C1048.99 267.79, 1048.8 504.17, 1048.31 754.36 M1048.31 754.36 C1050.09 774.72, 1036.99 786.65, 1016.31 786.36 M1048.31 754.36 C1046.43 777.4, 1035.52 786.84, 1016.31 786.36 M1016.31 786.36 C747.4 788.62, 477.57 789.6, 32 786.36 M1016.31 786.36 C710.01 788.77, 403.28 789.03, 32 786.36 M32 786.36 C9.39 785.57, 1.85 773.9, 0 754.36 M32 786.36 C10.85 787.73, 1.48 776.08, 0 754.36 M0 754.36 C1.66 539.54, 1.66 324, 0 32 M0 754.36 C2.58 479.42, 2.76 204.48, 0 32 M0 32 C1.83 10.04, 10.19 0.61, 32 0 M0 32 C-1.06 11.25, 8.74 2, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g stroke-linecap="round" transform="translate(2421.7713368189998 241.8966281456378) rotate(0 270.6298141137074 303.3316626193032)"><path d="M32 0 C188.28 1.05, 342.29 1.26, 509.26 0 M32 0 C191.36 -0.65, 350.43 -1.34, 509.26 0 M509.26 0 C530.78 1.99, 539.9 9.23, 541.26 32 M509.26 0 C532.87 -0.2, 540.03 10.18, 541.26 32 M541.26 32 C539.93 164.54, 540.33 298.46, 541.26 574.66 M541.26 32 C540.95 190.82, 541.51 348.91, 541.26 574.66 M541.26 574.66 C540.6 596.29, 528.96 608.15, 509.26 606.66 M541.26 574.66 C539.13 596.48, 529.98 608.4, 509.26 606.66 M509.26 606.66 C331.02 605.46, 153.34 605.17, 32 606.66 M509.26 606.66 C338.44 607.62, 166.74 607.04, 32 606.66 M32 606.66 C12.51 604.87, 0.16 597.19, 0 574.66 M32 606.66 C12.15 607.05, -0.04 594.62, 0 574.66 M0 574.66 C0.13 442.62, 0.85 308.72, 0 32 M0 574.66 C1.01 426.8, 1.37 278.67, 0 32 M0 32 C-0.48 11.28, 9.74 0.51, 32 0 M0 32 C-1.93 12.67, 10.45 -1.93, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g stroke-linecap="round" transform="translate(2463.9210871612067 321.27266557790153) rotate(0 141.82296217182306 41.317989894325365)"><path d="M20.66 0 C85.63 0.21, 153.15 -1.38, 262.99 0 M20.66 0 C105.95 -2.32, 189.85 -0.89, 262.99 0 M262.99 0 C275.4 -1.44, 285.63 6.71, 283.65 20.66 M262.99 0 C275.53 -0.49, 282.39 5.67, 283.65 20.66 M283.65 20.66 C284.08 35.46, 283.39 49.21, 283.65 61.98 M283.65 20.66 C284.32 30.94, 283.1 42.33, 283.65 61.98 M283.65 61.98 C282.01 77.24, 274.91 83.06, 262.99 82.64 M283.65 61.98 C283.04 77.49, 278.44 83.64, 262.99 82.64 M262.99 82.64 C209.11 83.79, 155.83 85.02, 20.66 82.64 M262.99 82.64 C183.43 84.17, 105.7 83.76, 20.66 82.64 M20.66 82.64 C7.04 83.82, 1.29 76.09, 0 61.98 M20.66 82.64 C6.85 81.26, -1.28 75.53, 0 61.98 M0 61.98 C1.65 44.36, -0.51 29.64, 0 20.66 M0 61.98 C0.91 48.9, -0.24 36.75, 0 20.66 M0 20.66 C-0.93 7.4, 5.21 1.74, 20.66 0 M0 20.66 C-0.22 4.96, 6.53 0.82, 20.66 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g stroke-linecap="round" transform="translate(2083.364165492925 216.56286490682487) rotate(0 58.168307066995794 155.2790985471156)"><path d="M29.08 0 C50.34 -0.82, 71.24 1.07, 87.25 0 M29.08 0 C51.6 1.42, 73.24 -0.29, 87.25 0 M87.25 0 C108.63 -0.18, 115.27 9.27, 116.34 29.08 M87.25 0 C105.38 -1.21, 117.41 9.16, 116.34 29.08 M116.34 29.08 C116.76 85.91, 116.24 142.04, 116.34 281.47 M116.34 29.08 C117.89 121.82, 117.5 214.92, 116.34 281.47 M116.34 281.47 C114.48 301.29, 106.11 312.07, 87.25 310.56 M116.34 281.47 C118.02 301.87, 104.87 309.95, 87.25 310.56 M87.25 310.56 C68.28 312.39, 47.49 312.01, 29.08 310.56 M87.25 310.56 C65.33 309.43, 41.64 310.92, 29.08 310.56 M29.08 310.56 C10.98 310.9, -0.03 299.66, 0 281.47 M29.08 310.56 C8.41 310.34, 1.84 300.65, 0 281.47 M0 281.47 C-2.1 187.6, -1.51 95.25, 0 29.08 M0 281.47 C-2.07 201.54, -2.25 121.32, 0 29.08 M0 29.08 C-1.68 11.44, 9.5 -1.68, 29.08 0 M0 29.08 C-0.36 10.52, 10.36 1.14, 29.08 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(622.2228121438975 155.42003516842487) rotate(0 113.11196899414062 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Momint Vault</text></g><g mask="url(#mask-KPul2f0sZw9s3TFndA0BQ)" stroke-linecap="round"><g transform="translate(1565.3167569183015 320.7473820670448) rotate(0 253.99991930946044 7.172076571015168)"><path d="M0.91 1.03 C85.79 3.17, 424.53 11.05, 509.07 13.47 M-0.07 0.52 C84.77 2.74, 424.1 12.33, 508.68 14.54" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1565.3167569183015 320.7473820670448) rotate(0 253.99991930946044 7.172076571015168)"><path d="M484.96 22.45 C493.32 21.82, 496.83 18, 508.68 14.54 M484.96 22.45 C495.48 19.37, 503.44 16.09, 508.68 14.54" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1565.3167569183015 320.7473820670448) rotate(0 253.99991930946044 7.172076571015168)"><path d="M485.43 5.35 C493.74 9.54, 497.12 10.55, 508.68 14.54 M485.43 5.35 C495.65 9.11, 503.41 12.65, 508.68 14.54" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-KPul2f0sZw9s3TFndA0BQ"><rect x="0" y="0" fill="#fff" width="2173.3165955372224" height="435.0915352090751"></rect><rect x="1659.8547316476838" y="282.91945863805995" fill="#000" width="318.92388916015625" height="90" opacity="1"></rect></mask><g transform="translate(1659.8547316476838 282.91945863805995) rotate(0 159.96123505655208 45.35916927882499)"><text x="159.46194458007812" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Get Module From </text><text x="159.46194458007812" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Storage</text></g><g transform="translate(2522.1461204402167 343.51100563810996) rotate(0 78.44397735595703 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Project 1</text></g><g transform="translate(2444.9923017701867 186.60924418688592) rotate(0 124.01995849609375 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Vault Modules</text></g><g transform="translate(60.37438975066107 545.6918448549395) rotate(0 39.53518855571747 21.380800980371532)"><text x="0" y="30.138377061931653" font-family="Virgil, Segoe UI Emoji" font-size="34.209281568594385px" fill="#000000" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">User</text></g><g stroke-linecap="round"><g transform="translate(55.60694895273082 529.1808616631306) rotate(0 42.136787151707495 -37.521598857520985)" fill-rule="evenodd"><path d="M15.88 -59.07 C15.88 -59.07, 15.88 -59.07, 15.88 -59.07 M15.88 -59.07 C15.88 -59.07, 15.88 -59.07, 15.88 -59.07 M4.86 -34.2 C15.57 -46.52, 26.28 -58.83, 39.63 -74.2 M4.86 -34.2 C14.96 -45.82, 25.06 -57.44, 39.63 -74.2 M3.03 -19.89 C14.83 -33.48, 26.64 -47.06, 49.61 -73.48 M3.03 -19.89 C18.42 -37.6, 33.81 -55.31, 49.61 -73.48 M0.54 -4.83 C16.58 -23.3, 32.63 -41.76, 56.96 -69.74 M0.54 -4.83 C12.23 -18.29, 23.93 -31.74, 56.96 -69.74 M6.57 0.41 C18.15 -12.91, 29.73 -26.23, 62.99 -64.49 M6.57 0.41 C27.68 -23.87, 48.79 -48.15, 62.99 -64.49 M17.2 0.38 C32.89 -17.66, 48.57 -35.71, 68.38 -58.49 M17.2 0.38 C36.14 -21.4, 55.07 -43.18, 68.38 -58.49 M27.83 0.34 C40.29 -13.99, 52.75 -28.32, 73.76 -52.48 M27.83 0.34 C37.63 -10.92, 47.42 -22.19, 73.76 -52.48 M38.46 0.31 C49.54 -12.43, 60.61 -25.16, 77.83 -44.97 M38.46 0.31 C54.04 -17.61, 69.62 -35.53, 77.83 -44.97 M49.09 0.28 C59.69 -11.91, 70.28 -24.1, 81.9 -37.46 M49.09 0.28 C58.15 -10.14, 67.2 -20.55, 81.9 -37.46 M59.72 0.24 C67.24 -8.41, 74.76 -17.06, 85.31 -29.19 M59.72 0.24 C66.72 -7.81, 73.72 -15.86, 85.31 -29.19 M71.67 -1.3 C76.74 -7.14, 81.81 -12.97, 88.07 -20.17 M71.67 -1.3 C75.97 -6.25, 80.27 -11.2, 88.07 -20.17 M0 0 C0 0, 0 0, 0 0 M0 0 C0 0, 0 0, 0 0 M12.04 -0.13 C9.32 -2.5, 6.59 -4.87, 1.47 -9.32 M12.04 -0.13 C8.41 -3.29, 4.78 -6.45, 1.47 -9.32 M24.84 0.39 C19.05 -4.64, 13.27 -9.66, 2.95 -18.64 M24.84 0.39 C20.44 -3.43, 16.05 -7.25, 2.95 -18.64 M36.88 0.26 C27.78 -7.65, 18.68 -15.57, 3.67 -28.61 M36.88 0.26 C24.78 -10.26, 12.68 -20.78, 3.67 -28.61 M48.92 0.12 C36.53 -10.64, 24.14 -21.41, 5.14 -37.93 M48.92 0.12 C36.33 -10.82, 23.75 -21.76, 5.14 -37.93 M60.2 -0.67 C42.42 -16.13, 24.63 -31.59, 8.13 -45.93 M60.2 -0.67 C47.73 -11.51, 35.25 -22.36, 8.13 -45.93 M71.49 -1.45 C55.89 -15.02, 40.29 -28.58, 11.87 -53.28 M71.49 -1.45 C53.54 -17.06, 35.58 -32.67, 11.87 -53.28 M81.27 -3.56 C60.35 -21.74, 39.44 -39.92, 16.36 -59.98 M81.27 -3.56 C58.1 -23.69, 34.93 -43.83, 16.36 -59.98 M87.27 -8.94 C62.86 -30.16, 38.45 -51.38, 22.37 -65.36 M87.27 -8.94 C68.44 -25.3, 49.62 -41.67, 22.37 -65.36 M87.99 -18.91 C67.04 -37.12, 46.09 -55.33, 29.12 -70.08 M87.99 -18.91 C65.88 -38.13, 43.77 -57.36, 29.12 -70.08 M82.67 -34.13 C65.17 -49.35, 47.66 -64.57, 36.64 -74.15 M82.67 -34.13 C70.04 -45.12, 57.4 -56.1, 36.64 -74.15 M73.58 -52.64 C67.09 -58.28, 60.61 -63.92, 48.68 -74.29 M73.58 -52.64 C67.93 -57.55, 62.28 -62.46, 48.68 -74.29" stroke="#ced4da" stroke-width="1" fill="none"></path><path d="M0 0 C1.57 -8.29, 2.7 -37.22, 9.44 -49.73 C16.18 -62.23, 30.11 -74.14, 40.45 -75.04 C50.79 -75.95, 64.16 -66.8, 71.46 -55.15 C78.77 -43.51, 96.18 -14.36, 84.27 -5.16 C72.36 4.03, 14.05 -0.86, 0 0 M0 0 C1.57 -8.29, 2.7 -37.22, 9.44 -49.73 C16.18 -62.23, 30.11 -74.14, 40.45 -75.04 C50.79 -75.95, 64.16 -66.8, 71.46 -55.15 C78.77 -43.51, 96.18 -14.36, 84.27 -5.16 C72.36 4.03, 14.05 -0.86, 0 0" stroke="#000000" stroke-width="2" fill="none"></path></g></g><mask></mask><g stroke-linecap="round" transform="translate(76.90884765565261 415.1082200725823) rotate(0 21.574035021674263 18.877280643964696)"><path d="M4.9 6.91 C4.9 6.91, 4.9 6.91, 4.9 6.91 M4.9 6.91 C4.9 6.91, 4.9 6.91, 4.9 6.91 M1.1 23.48 C7.47 16.15, 13.84 8.82, 21.44 0.08 M1.1 23.48 C6.39 17.39, 11.69 11.29, 21.44 0.08 M5.17 30.99 C12.6 22.44, 20.04 13.88, 30.1 2.31 M5.17 30.99 C14.66 20.08, 24.15 9.16, 30.1 2.31 M11.21 36.24 C21.47 24.43, 31.74 12.62, 37.45 6.05 M11.21 36.24 C21.37 24.55, 31.53 12.87, 37.45 6.05 M20.52 37.72 C27.51 29.67, 34.5 21.63, 42.17 12.81 M20.52 37.72 C27.92 29.21, 35.31 20.7, 42.17 12.81 M33.12 35.42 C35.6 32.56, 38.08 29.71, 41.65 25.61 M33.12 35.42 C35.76 32.38, 38.41 29.34, 41.65 25.61 M7.94 33.54 C7.94 33.54, 7.94 33.54, 7.94 33.54 M7.94 33.54 C7.94 33.54, 7.94 33.54, 7.94 33.54 M24.51 37.35 C17.22 31, 9.92 24.66, 0.36 16.35 M24.51 37.35 C16.35 30.25, 8.19 23.16, 0.36 16.35 M33.53 34.59 C26.46 28.44, 19.4 22.3, 3.34 8.35 M33.53 34.59 C24.6 26.82, 15.66 19.05, 3.34 8.35 M39.54 29.21 C27.68 18.9, 15.81 8.59, 9.35 2.96 M39.54 29.21 C31.91 22.58, 24.29 15.96, 9.35 2.96 M43.28 21.86 C35.63 15.21, 27.99 8.57, 18.37 0.21 M43.28 21.86 C38.24 17.48, 33.21 13.11, 18.37 0.21 M40.98 9.26 C39.24 7.75, 37.5 6.24, 32.67 2.04 M40.98 9.26 C38.43 7.05, 35.89 4.83, 32.67 2.04" stroke="#ced4da" stroke-width="1" fill="none"></path><path d="M43.15 18.88 C43.15 19.97, 43.04 21.08, 42.82 22.16 C42.6 23.23, 42.27 24.31, 41.85 25.33 C41.42 26.36, 40.88 27.37, 40.26 28.32 C39.63 29.26, 38.9 30.17, 38.1 31.01 C37.3 31.85, 36.4 32.64, 35.44 33.34 C34.48 34.04, 33.44 34.68, 32.36 35.23 C31.28 35.77, 30.13 36.24, 28.95 36.62 C27.78 36.99, 26.55 37.28, 25.32 37.47 C24.09 37.66, 22.82 37.75, 21.57 37.75 C20.33 37.75, 19.06 37.66, 17.83 37.47 C16.6 37.28, 15.37 36.99, 14.2 36.62 C13.02 36.24, 11.87 35.77, 10.79 35.23 C9.71 34.68, 8.66 34.04, 7.71 33.34 C6.75 32.64, 5.85 31.85, 5.05 31.01 C4.24 30.17, 3.51 29.26, 2.89 28.32 C2.27 27.37, 1.73 26.36, 1.3 25.33 C0.87 24.31, 0.54 23.23, 0.33 22.16 C0.11 21.08, 0 19.97, 0 18.88 C0 17.78, 0.11 16.68, 0.33 15.6 C0.54 14.52, 0.87 13.45, 1.3 12.42 C1.73 11.39, 2.27 10.38, 2.89 9.44 C3.51 8.49, 4.24 7.58, 5.05 6.74 C5.85 5.91, 6.75 5.12, 7.71 4.42 C8.66 3.71, 9.71 3.08, 10.79 2.53 C11.87 1.98, 13.02 1.51, 14.2 1.14 C15.37 0.76, 16.6 0.48, 17.83 0.29 C19.06 0.1, 20.33 0, 21.57 0 C22.82 0, 24.09 0.1, 25.32 0.29 C26.55 0.48, 27.78 0.76, 28.95 1.14 C30.13 1.51, 31.28 1.98, 32.36 2.53 C33.44 3.08, 34.48 3.71, 35.44 4.42 C36.4 5.12, 37.3 5.91, 38.1 6.74 C38.9 7.58, 39.63 8.49, 40.26 9.44 C40.88 10.38, 41.42 11.39, 41.85 12.42 C42.27 13.45, 42.6 14.52, 42.82 15.6 C43.04 16.68, 43.09 18.33, 43.15 18.88 C43.2 19.42, 43.2 18.33, 43.15 18.88" stroke="#000000" stroke-width="2" fill="none"></path></g><g mask="url(#mask-MDhAQNb6sj43wrqSP4hIw)" stroke-linecap="round"><g transform="translate(161.92831449392725 479.7664403465142) rotate(0 245.10451791012292 12.622495358014021)"><path d="M-0.39 0.18 C80.97 4.63, 407.65 21.92, 489.23 26.14 M1.6 -0.78 C83.23 3.4, 409.79 19.86, 491.43 24.48" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(161.92831449392725 479.7664403465142) rotate(0 245.10451791012292 12.622495358014021)"><path d="M467.51 31.78 C477.14 27.38, 487.64 24.33, 491.43 24.48 M467.51 31.78 C475.94 29.69, 482.12 26.65, 491.43 24.48" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(161.92831449392725 479.7664403465142) rotate(0 245.10451791012292 12.622495358014021)"><path d="M468.42 14.7 C477.61 16.95, 487.75 20.53, 491.43 24.48 M468.42 14.7 C476.51 18.1, 482.4 20.54, 491.43 24.48" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-MDhAQNb6sj43wrqSP4hIw"><rect x="0" y="0" fill="#fff" width="752.1373503141731" height="605.0114310625422"></rect><rect x="279.6108887394994" y="424.8889357045264" fill="#000" width="254.84388732910156" height="135" opacity="1"></rect></mask><g transform="translate(279.6108887394994 424.8889357045264) rotate(0 127.83322864640036 67.55812791605058)"><text x="127.42194366455078" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Deposits 1000</text><text x="127.42194366455078" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Usdc</text><text x="127.42194366455078" y="121.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Into Project 1</text></g><g stroke-linecap="round"><g transform="translate(2148.643019287064 528.1210620010561) rotate(0 76.63347228463391 -167.09061016098076)"><path d="M0.88 0.52 C26.32 -5.64, 129.5 19.66, 152.34 -36.1 C175.18 -91.86, 140.39 -284.48, 137.92 -334.04 M-0.12 -0.25 C25.72 -6.32, 131.64 20.67, 154.57 -34.73 C177.5 -90.13, 140.23 -282.5, 137.44 -332.65" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2148.643019287064 528.1210620010561) rotate(0 76.63347228463391 -167.09061016098076)"><path d="M148.77 -310.37 C146.38 -317.92, 141.88 -321.55, 137.44 -332.65 M148.77 -310.37 C146.09 -316.98, 142.37 -323.26, 137.44 -332.65" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2148.643019287064 528.1210620010561) rotate(0 76.63347228463391 -167.09061016098076)"><path d="M131.8 -308.3 C134.03 -316.54, 134.17 -320.74, 137.44 -332.65 M131.8 -308.3 C134.4 -315.66, 135.97 -322.58, 137.44 -332.65" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask></mask><g transform="translate(1863.765052758827 141.02385724003216) rotate(0 256.71594969928265 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Active Vault Module Storage</text></g><g transform="translate(2977.52461389205 273.6222300902955) rotate(0 386.7066345214844 181.8011410734639)"><text x="0" y="32.033361057144354" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    name: "School Solar Project",</text><text x="0" y="77.48364632551035" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    pricePerShare: 100 USDC,</text><text x="0" y="122.93393159387634" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    availableShares: 1000,</text><text x="0" y="168.38421686224234" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    allocatedShares: 0,</text><text x="0" y="213.83450213060834" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    totalShares: 1000,</text><text x="0" y="259.28478739897434" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    active: true,</text><text x="0" y="304.7350726673403" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    tokenURI: "ipfs://school-metadata",</text><text x="0" y="350.18535793570635" font-family="Virgil, Segoe UI Emoji" font-size="36.360228214692796px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">    owner: schoolOwnerAddress</text></g><g mask="url(#mask-aM9MYJOqSL_JKS9I0Eli6)" stroke-linecap="round"><g transform="translate(1556.6107655537521 751.1657914785292) rotate(0 431.9085716152763 5.710708602567138)"><path d="M0.16 0.7 C144.21 2.64, 720.79 9.76, 864.87 11.73 M-1.21 0.03 C142.72 1.57, 720.22 7.98, 864.47 9.78" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1556.6107655537521 751.1657914785292) rotate(0 431.9085716152763 5.710708602567138)"><path d="M840.88 18.05 C850.21 16.91, 857.73 13.67, 864.47 9.78 M840.88 18.05 C851.13 14, 859.55 12.24, 864.47 9.78" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1556.6107655537521 751.1657914785292) rotate(0 431.9085716152763 5.710708602567138)"><path d="M841.08 0.95 C850.36 5.73, 857.81 8.41, 864.47 9.78 M841.08 0.95 C851.14 3.61, 859.48 8.57, 864.47 9.78" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-aM9MYJOqSL_JKS9I0Eli6"><rect x="0" y="0" fill="#fff" width="2520.4279087843047" height="862.5872086836634"></rect><rect x="1931.0993618882667" y="711.8765000810963" fill="#000" width="114.83995056152344" height="90" opacity="1"></rect></mask><g transform="translate(1931.0993618882671 711.8765000810981) rotate(0 57.338947531613485 45.1695208673591)"><text x="57.41997528076172" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Calls </text><text x="57.41997528076172" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Invest</text></g><g transform="translate(2436.825014970782 579.5326895111039) rotate(0 255.08663940429688 49.185018382489034)"><text x="0" y="23.110400637318662" font-family="Virgil, Segoe UI Emoji" font-size="26.232009803993943px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">- Calculates shares: </text><text x="0" y="55.90041289231109" font-family="Virgil, Segoe UI Emoji" font-size="26.232009803993943px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">1000 USDC / 100 USDC = 10 shares</text><text x="0" y="88.69042514730351" font-family="Virgil, Segoe UI Emoji" font-size="26.232009803993943px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">- Updates project allocated shares: 10</text></g><g transform="translate(614.2771770494055 234.7833858502936) rotate(0 137.60386885076196 17.971463994266742)"><text x="0" y="25.33257564631822" font-family="Virgil, Segoe UI Emoji" font-size="28.75434239082658px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">name: "Solar Vault",</text></g><g transform="translate(614.4799053131842 285.02032605260956) rotate(0 240.3808217415483 13.904493891077436)"><text x="0" y="19.599774588863184" font-family="Virgil, Segoe UI Emoji" font-size="22.247190225724385px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">baseAsset: USDC</text></g><g transform="translate(617.3763412518942 327.75483986785093) rotate(0 94.52788013319173 17.808573866744155)"><text x="0" y="25.102965722562477" font-family="Virgil, Segoe UI Emoji" font-size="28.49371818679055px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">symbol: "$SL",</text></g><g transform="translate(615.1704380296906 376.25139653785754) rotate(0 121.11961681866933 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">shareName: "$SOLAR",</text></g><g transform="translate(2278.5229510286117 1414.6119804524324) rotate(0 173.0929067253602 21.937157235251107)"><text x="0" y="15.46130841940474" font-family="Virgil, Segoe UI Emoji" font-size="17.54972578820061px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">liquidityHoldBP: 2000,  // 20% held as</text><text x="0" y="37.3984656546555" font-family="Virgil, Segoe UI Emoji" font-size="17.54972578820061px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">liquid reserves</text></g><g stroke-linecap="round" transform="translate(1244.2243267431277 290.75640888513317) rotate(0 156.07670532157374 98.05564007918565)"><path d="M32 0 C128.65 0.18, 216.84 -0.34, 280.15 0 C301.34 -2.65, 313.96 11.57, 312.15 32 C308.77 77.95, 310.29 128.97, 312.15 164.11 C309.48 187.07, 298.79 198.64, 280.15 196.11 C210.22 196.42, 141.82 198.43, 32 196.11 C8.73 199.63, -1.7 185.65, 0 164.11 C0.13 129.77, 1.66 88.42, 0 32 C-3.06 14.17, 10.45 3.49, 32 0" stroke="none" stroke-width="0" fill="#b2f2bb"></path><path d="M32 0 C112.76 -0.98, 195.9 0.38, 280.15 0 M32 0 C126.84 0.08, 222.15 1, 280.15 0 M280.15 0 C301.59 -1.42, 312.78 11.97, 312.15 32 M280.15 0 C302.69 -1.97, 314.4 12.33, 312.15 32 M312.15 32 C310.61 77.23, 310.82 121.23, 312.15 164.11 M312.15 32 C312.72 62.82, 312.43 92.84, 312.15 164.11 M312.15 164.11 C310.78 186.45, 303.37 194.49, 280.15 196.11 M312.15 164.11 C311.62 183.64, 301.75 195.76, 280.15 196.11 M280.15 196.11 C218.22 197.77, 155.62 197.34, 32 196.11 M280.15 196.11 C191.15 196.07, 102.48 195.43, 32 196.11 M32 196.11 C11.38 195, -1.69 186.65, 0 164.11 M32 196.11 C9.49 196.09, 1.51 186.04, 0 164.11 M0 164.11 C1.37 126.36, 1.29 87, 0 32 M0 164.11 C-0.67 122.93, 0.77 80.28, 0 32 M0 32 C-0.18 12.15, 9.24 0.98, 32 0 M0 32 C-0.12 12.38, 8.62 -0.97, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1297.4670621438277 343.8120489643179) rotate(0 102.83396992087364 45)"><text x="102.83396992087364" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Get Module</text><text x="102.83396992087364" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Address</text></g><g mask="url(#mask-at_xNNXvVNtqqTPjFw9LC)" stroke-linecap="round"><g transform="translate(2081.3507110617934 451.9618721527795) rotate(0 -263.5855063976318 -15.414147522701569)"><path d="M0.71 -0.94 C-87.3 -6.15, -439.6 -25.39, -527.42 -30.35 M-0.38 1.18 C-88.63 -4.47, -440.82 -27.13, -528.5 -32.22" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2081.3507110617934 451.9618721527795) rotate(0 -263.5855063976318 -15.414147522701569)"><path d="M-504.53 -39.3 C-514.57 -37.06, -520.72 -32.51, -528.5 -32.22 M-504.53 -39.3 C-511.1 -36.5, -518.51 -34.22, -528.5 -32.22" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2081.3507110617934 451.9618721527795) rotate(0 -263.5855063976318 -15.414147522701569)"><path d="M-505.58 -22.24 C-515.37 -26.07, -521.15 -27.59, -528.5 -32.22 M-505.58 -22.24 C-511.79 -24.72, -518.87 -27.73, -528.5 -32.22" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-at_xNNXvVNtqqTPjFw9LC"><rect x="0" y="0" fill="#fff" width="2708.5217238570567" height="582.7901671981826"></rect><rect x="1748.3212276211289" y="391.54772463007794" fill="#000" width="138.8879540860653" height="90" opacity="1"></rect></mask><g transform="translate(1748.3212276211289 391.54772463007794) rotate(0 69.13399972160818 44.89448736165741)"><text x="69.44397704303265" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Module </text><text x="69.44397704303265" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Address</text></g><g mask="url(#mask-cuZJ_p7cOb2IGnK_GEhsb)" stroke-linecap="round"><g transform="translate(1392.5282560470532 484.00864540586645) rotate(0 1.2148968841479473 113.57393558564036)"><path d="M-0.81 -0.18 C-0.68 37.54, 0.95 188.37, 1.61 226.35 M0.96 -1.32 C1.41 36.53, 3.6 189.64, 3.9 227.47" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1392.5282560470532 484.00864540586645) rotate(0 1.2148968841479473 113.57393558564036)"><path d="M-4.92 204.07 C-1.97 211.35, 0.23 222.48, 3.9 227.47 M-4.92 204.07 C-0.79 211.63, 0.7 219.24, 3.9 227.47" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1392.5282560470532 484.00864540586645) rotate(0 1.2148968841479473 113.57393558564036)"><path d="M12.18 203.88 C8.86 211.11, 4.78 222.31, 3.9 227.47 M12.18 203.88 C10.39 211.62, 5.95 219.3, 3.9 227.47" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-cuZJ_p7cOb2IGnK_GEhsb"><rect x="0" y="0" fill="#fff" width="1494.958049815349" height="811.1565165771472"></rect><rect x="1198.2992137222168" y="575.0825809915077" fill="#000" width="390.88787841796875" height="45" opacity="1"></rect></mask><g transform="translate(1198.2992137222168 575.0825809915059) rotate(0 195.77184871870554 22.000465841972982)"><text x="195.44393920898438" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Sends Module Address</text></g><g stroke-linecap="round" transform="translate(1228.2278040106673 716.3410087285056) rotate(0 163.65038359286757 46.32208166664623)"><path d="M23.16 0 C137.04 3.98, 248.02 1.02, 304.14 0 C319.13 2.1, 324.07 4.85, 327.3 23.16 C328.55 40.29, 330.55 58.63, 327.3 69.48 C329.1 81.36, 321.61 90.98, 304.14 92.64 C228.96 94.8, 151.25 94.46, 23.16 92.64 C5.88 95.01, 2.26 85.11, 0 69.48 C-2.98 60.09, -1.34 47.37, 0 23.16 C-0.58 5.52, 4.15 0.77, 23.16 0" stroke="none" stroke-width="0" fill="#b2f2bb"></path><path d="M23.16 0 C115.41 0.56, 210.54 1.85, 304.14 0 M23.16 0 C125.81 -1.85, 229.28 -1.9, 304.14 0 M304.14 0 C320.88 -1.41, 328.24 6.33, 327.3 23.16 M304.14 0 C321.08 -0.04, 327.33 7.16, 327.3 23.16 M327.3 23.16 C328.8 37.89, 325.34 48.77, 327.3 69.48 M327.3 23.16 C327.25 33.52, 327.7 44.03, 327.3 69.48 M327.3 69.48 C325.31 85.78, 320.3 91.77, 304.14 92.64 M327.3 69.48 C329.39 87, 317.33 91.44, 304.14 92.64 M304.14 92.64 C227.78 91.89, 154.56 89.79, 23.16 92.64 M304.14 92.64 C222.94 91.31, 140.76 90.81, 23.16 92.64 M23.16 92.64 C9 91.96, -1.56 84.71, 0 69.48 M23.16 92.64 C6.01 90.7, 1.71 84.96, 0 69.48 M0 69.48 C-1.21 51.57, -1.35 38.52, 0 23.16 M0 69.48 C0.1 53.95, -1 37.82, 0 23.16 M0 23.16 C-1.25 7.75, 7.9 -1.98, 23.16 0 M0 23.16 C1.5 6.46, 9.41 0.87, 23.16 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1280.800231303306 740.1630903951509) rotate(0 111.07795630022883 22.5)"><text x="111.07795630022883" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Calls Module</text></g><g mask="url(#mask--_OkinBUsCn0YZGxah_Fn)" stroke-linecap="round"><g transform="translate(2727.1242176638557 849.6606535852343) rotate(0 -0.9168404111317727 170.1751668601837)"><path d="M-0.93 1.19 C-1.38 57.99, -1.71 283.18, -1.71 339.78 M0.78 0.76 C0.09 57.81, -2.25 284.71, -2.59 341.02" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2727.1242176638557 849.6606535852343) rotate(0 -0.9168404111317727 170.1751668601837)"><path d="M-10.94 317.46 C-5.96 326.79, -5.67 337.13, -2.59 341.02 M-10.94 317.46 C-7.85 325.87, -6.21 333.15, -2.59 341.02" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2727.1242176638557 849.6606535852343) rotate(0 -0.9168404111317727 170.1751668601837)"><path d="M6.16 317.61 C4.57 326.75, -1.71 337.03, -2.59 341.02 M6.16 317.61 C3.51 325.97, -0.6 333.2, -2.59 341.02" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask--_OkinBUsCn0YZGxah_Fn"><rect x="0" y="0" fill="#fff" width="2828.957898486119" height="1290.0109873056017"></rect><rect x="2563.41544610038" y="974.8358204454162" fill="#000" width="325.5838623046875" height="90" opacity="1"></rect></mask><g transform="translate(2563.41544610038 974.8358204454162) rotate(0 162.80661756849847 45.71799420484422)"><text x="162.79193115234375" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Sends Back</text><text x="162.79193115234375" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Calcualted Shares</text></g><g stroke-linecap="round" transform="translate(2254.236637263146 1193.434704366001) rotate(0 524.1571130061559 345.53856027360416)"><path d="M32 0 C420.98 6, 811.3 4.82, 1016.31 0 C1036.37 -3.13, 1046.43 7.25, 1048.31 32 C1051.28 158.86, 1050.7 285.09, 1048.31 659.08 C1051.9 680.3, 1040.9 691.56, 1016.31 691.08 C691.12 684.77, 364.09 684.76, 32 691.08 C12.21 691.79, 3.17 681.09, 0 659.08 C1.33 454.29, 1.93 247.97, 0 32 C2 10.93, 12.62 -3.12, 32 0" stroke="none" stroke-width="0" fill="#ffc9c9"></path><path d="M32 0 C389.6 3.07, 748.05 3.2, 1016.31 0 M32 0 C251.68 -2.51, 471.33 -2.63, 1016.31 0 M1016.31 0 C1038.8 0.66, 1049.66 9.38, 1048.31 32 M1016.31 0 C1037.18 0.68, 1047.74 10.04, 1048.31 32 M1048.31 32 C1045.41 278.85, 1046.41 526.33, 1048.31 659.08 M1048.31 32 C1046.03 187.72, 1046.11 344.07, 1048.31 659.08 M1048.31 659.08 C1048.78 679.99, 1039.14 692.22, 1016.31 691.08 M1048.31 659.08 C1049.15 678.73, 1038.82 691.11, 1016.31 691.08 M1016.31 691.08 C780.49 693.24, 542.76 693.91, 32 691.08 M1016.31 691.08 C753.16 692.72, 490.85 692.81, 32 691.08 M32 691.08 C10.27 692.78, -0.83 680.61, 0 659.08 M32 691.08 C12.21 693.1, 0.38 679.91, 0 659.08 M0 659.08 C-0.36 460.94, -0.42 262.8, 0 32 M0 659.08 C-1.84 420, -2.35 181.24, 0 32 M0 32 C-0.54 10.42, 11.51 -1.13, 32 0 M0 32 C-1.31 10.74, 9.75 -0.73, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2295.779180852478 1145.3107134864958) rotate(0 113.11196899414062 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Momint Vault</text></g><g transform="translate(2287.833545757986 1224.6740641683655) rotate(0 137.60386885076184 17.971463994266742)"><text x="0" y="25.33257564631822" font-family="Virgil, Segoe UI Emoji" font-size="28.75434239082658px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">name: "Solar Vault",</text></g><g transform="translate(2288.0362740217643 1274.9110043706796) rotate(0 240.38082174154826 13.904493891077436)"><text x="0" y="19.599774588863184" font-family="Virgil, Segoe UI Emoji" font-size="22.247190225724385px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">baseAsset: USDC</text></g><g transform="translate(2290.9327099604743 1317.6455181859246) rotate(0 94.52788013319167 17.808573866744155)"><text x="0" y="25.102965722562477" font-family="Virgil, Segoe UI Emoji" font-size="28.49371818679055px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">symbol: "$SL",</text></g><g transform="translate(2288.726806738271 1365.8235072738926) rotate(0 121.0655746459961 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">shareName: "$SOLAR",</text></g><g stroke-linecap="round" transform="translate(2691.9158198733553 1551.4926951883745) rotate(0 156.07670532157374 98.05564007918565)"><path d="M32 0 C117.07 -1.89, 200.84 -0.64, 280.15 0 C301.38 3.25, 312.63 11.78, 312.15 32 C309.51 67.97, 309.49 110.28, 312.15 164.11 C312.87 188.61, 302.17 197.1, 280.15 196.11 C212.54 198.69, 141.8 198.51, 32 196.11 C10.93 198.06, -3.12 187.77, 0 164.11 C4.4 129.57, -0.01 101.95, 0 32 C-2.73 9.27, 12.29 -0.84, 32 0" stroke="none" stroke-width="0" fill="#a5d8ff"></path><path d="M32 0 C100.54 -0.07, 166.95 -1.5, 280.15 0 M32 0 C114.53 -0.18, 196.31 -0.12, 280.15 0 M280.15 0 C299.76 0.83, 310.25 9.64, 312.15 32 M280.15 0 C299.6 -0.79, 310.82 8.92, 312.15 32 M312.15 32 C311.79 68.27, 313.35 102.27, 312.15 164.11 M312.15 32 C312.23 62.6, 313.45 92.93, 312.15 164.11 M312.15 164.11 C311.47 184.4, 302.47 195.45, 280.15 196.11 M312.15 164.11 C312.51 186.32, 299.81 196.9, 280.15 196.11 M280.15 196.11 C191.17 195.03, 99.57 196.81, 32 196.11 M280.15 196.11 C184.01 195.58, 87.84 195.03, 32 196.11 M32 196.11 C11.26 194.39, 1.16 187.07, 0 164.11 M32 196.11 C12.5 195.29, 0.86 184.78, 0 164.11 M0 164.11 C-0.53 137.02, -1.41 107.09, 0 32 M0 164.11 C1.49 123.74, -0.21 83.1, 0 32 M0 32 C1.11 8.97, 10.13 -0.71, 32 0 M0 32 C-2 9.46, 8.48 -2.28, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2698.430574511335 1582.0483352675592) rotate(0 149.56195068359375 67.5)"><text x="149.56195068359375" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Vault Calculates</text><text x="149.56195068359375" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Liquidity AND</text><text x="149.56195068359375" y="121.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">mints shares</text></g><g transform="translate(2287.5915332427985 1403.8678007838835) rotate(0 155.25102281570435 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">20% held as liquid reserves</text></g><g transform="translate(2287.5350131879213 1448.2052147418626) rotate(0 155.78432220220566 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">80% max to project owners</text></g><g transform="translate(944.331340896043 843.2025975122478) rotate(0 84.44703834503889 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">1% Deposit Fee</text></g><g transform="translate(942.2686917983724 800.7994436107883) rotate(0 94.32384538650513 13.893692864988225)"><text x="0" y="19.584549462487615" font-family="Virgil, Segoe UI Emoji" font-size="22.229908583981402px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">2% Portocol Fee</text></g><g stroke-linecap="round" transform="translate(796.6785405509086 1132.3223334206696) rotate(0 399.321874161747 351.84974018315734)"><path d="M224.1 35.52 C244.11 20.37, 274.11 16.88, 300.03 11.14 C325.95 5.41, 352.95 2.25, 379.62 1.12 C406.29 -0.02, 433.65 1.03, 460.07 4.33 C486.49 7.63, 513 12.84, 538.14 20.91 C563.27 28.98, 588.18 39.91, 610.87 52.73 C633.55 65.55, 654.74 81.46, 674.25 97.83 C693.77 114.19, 712.67 131.57, 727.95 150.92 C743.23 170.26, 755.4 192.32, 765.93 213.9 C776.46 235.48, 785.76 257.33, 791.12 280.39 C796.48 303.45, 798.34 328.62, 798.07 352.25 C797.8 375.88, 794.69 399.18, 789.51 422.16 C784.32 445.14, 777.33 468.47, 766.95 490.14 C756.57 511.8, 742.55 532.73, 727.23 552.14 C711.91 571.55, 694.34 590.13, 675.04 606.6 C655.73 623.06, 634.21 638.34, 611.4 650.92 C588.59 663.5, 563.33 674.06, 538.17 682.09 C513.02 690.12, 486.98 695.54, 460.47 699.12 C433.97 702.7, 406.02 704.75, 379.14 703.56 C352.25 702.37, 325 697.85, 299.15 691.99 C273.31 686.13, 248.19 678.62, 224.08 668.41 C199.96 658.2, 175.76 645.27, 154.47 630.71 C133.18 616.15, 113.81 599.13, 96.32 581.04 C78.83 562.95, 62.53 542.7, 49.53 522.19 C36.52 501.67, 26.27 480.4, 18.31 457.94 C10.34 435.47, 4.41 411.17, 1.73 387.41 C-0.95 363.65, -0.51 338.85, 2.21 315.39 C4.93 291.93, 10.08 269.17, 18.04 246.65 C25.99 224.12, 37 201.04, 49.94 180.24 C62.88 159.45, 78.23 139.55, 95.68 121.87 C113.14 104.19, 131.79 89.36, 154.68 74.17 C177.56 58.99, 217.37 37.29, 232.99 30.75 C248.6 24.22, 245.38 29.41, 248.35 34.99 M309.83 8.47 C333.25 -1.81, 363.82 0.94, 391.04 0.44 C418.26 -0.06, 446.71 1.48, 473.16 5.47 C499.61 9.46, 524.9 15.26, 549.74 24.38 C574.57 33.5, 600.04 46.92, 622.18 60.19 C644.32 73.46, 663.7 87.39, 682.58 104.01 C701.47 120.64, 720.64 140.28, 735.48 159.94 C750.32 179.59, 762.08 199.79, 771.6 221.95 C781.13 244.11, 788.42 269.66, 792.65 292.89 C796.87 316.13, 797.52 338.07, 796.95 361.38 C796.39 384.7, 795.36 409.66, 789.24 432.79 C783.12 455.93, 771.71 478.94, 760.22 500.2 C748.74 521.46, 736.32 541.28, 720.31 560.36 C704.3 579.43, 684 598.87, 664.16 614.65 C644.33 630.43, 624.22 643.14, 601.31 655.03 C578.4 666.92, 552.21 678.25, 526.7 685.97 C501.19 693.69, 474.97 698.45, 448.26 701.35 C421.55 704.25, 393.36 705.53, 366.42 703.38 C339.48 701.22, 312.56 695.17, 286.64 688.43 C260.72 681.69, 234.64 673.81, 210.92 662.92 C187.21 652.04, 164.57 637.96, 144.35 623.13 C124.13 608.3, 106.25 592.52, 89.61 573.96 C72.98 555.39, 57.03 533.07, 44.54 511.76 C32.05 490.44, 21.78 468.63, 14.66 446.06 C7.55 423.49, 3.48 399.9, 1.83 376.34 C0.17 352.78, 1.27 327.99, 4.75 304.71 C8.23 281.44, 14.14 258.67, 22.7 236.7 C31.26 214.74, 42.51 193.08, 56.12 172.95 C69.72 152.81, 85.98 133.46, 104.34 115.91 C122.7 98.36, 144.47 81.88, 166.28 67.66 C188.09 53.43, 211.01 40.49, 235.2 30.56 C259.39 20.63, 298.5 10.67, 311.42 8.09 C324.34 5.5, 311.06 9.02, 312.7 15.03" stroke="none" stroke-width="0" fill="#ffec99"></path><path d="M550.26 25.75 C576.24 28.68, 598.62 45.61, 620.8 58.66 C642.99 71.71, 664.45 87.12, 683.39 104.05 C702.33 120.98, 719.68 140.33, 734.45 160.23 C749.22 180.13, 762.36 201.42, 772 223.46 C781.64 245.49, 787.88 269.2, 792.28 292.46 C796.68 315.71, 799.3 339.33, 798.4 362.98 C797.5 386.63, 793.24 411.18, 786.91 434.36 C780.57 457.53, 771.54 480.74, 760.39 502.04 C749.24 523.35, 736.06 543.5, 719.99 562.19 C703.92 580.87, 683.94 598.34, 663.96 614.17 C643.99 629.99, 623.06 645.07, 600.12 657.14 C577.19 669.2, 551.87 679.3, 526.35 686.56 C500.83 693.82, 473.83 697.95, 447.02 700.71 C420.2 703.47, 392.23 705.06, 365.45 703.14 C338.68 701.22, 311.89 695.98, 286.36 689.18 C260.82 682.38, 235.99 673.42, 212.23 662.35 C188.47 651.29, 164.42 637.91, 143.79 622.79 C123.17 607.68, 104.97 590.21, 88.46 571.65 C71.95 553.09, 57.02 532.31, 44.73 511.44 C32.45 490.57, 22.08 469.17, 14.73 446.42 C7.38 423.66, 2.54 398.37, 0.61 374.91 C-1.31 351.44, -0.45 328.77, 3.16 305.62 C6.76 282.47, 13.2 258.51, 22.25 235.99 C31.3 213.46, 43.73 190.65, 57.48 170.47 C71.22 150.29, 86.84 132.17, 104.71 114.88 C122.59 97.59, 142.88 80.62, 164.74 66.72 C186.6 52.83, 211.23 41.11, 235.89 31.52 C260.56 21.92, 286.59 14.36, 312.72 9.17 C338.85 3.98, 365.99 0.73, 392.66 0.35 C419.34 -0.03, 445.16 2.09, 472.76 6.89 C500.35 11.69, 543.24 23.83, 558.24 29.14 C573.24 34.44, 565.26 33.26, 562.74 38.7 M271.87 19.03 C294.08 5.94, 324.16 4.49, 350.33 1.64 C376.5 -1.21, 402.46 0.06, 428.89 1.92 C455.32 3.77, 482.84 6.32, 508.91 12.75 C534.99 19.18, 561.25 29.49, 585.35 40.5 C609.44 51.5, 632.75 63.8, 653.49 78.81 C674.22 93.81, 693.26 111.9, 709.76 130.54 C726.26 149.19, 740.34 169.73, 752.49 190.68 C764.64 211.62, 774.97 233.47, 782.67 256.22 C790.36 278.97, 796.79 303.96, 798.67 327.17 C800.55 350.37, 797.77 372.16, 793.95 395.45 C790.13 418.74, 784.45 444.11, 775.74 466.9 C767.04 489.69, 755.08 511.87, 741.72 532.2 C728.36 552.52, 713.25 571.53, 695.58 588.86 C677.9 606.2, 657.51 622.14, 635.68 636.18 C613.86 650.23, 588.94 663.62, 564.62 673.16 C540.3 682.7, 515.73 688.26, 489.75 693.42 C463.78 698.59, 435.69 703.56, 408.77 704.15 C381.84 704.74, 354.33 701.19, 328.2 696.95 C302.06 692.71, 276.85 687.29, 251.95 678.7 C227.06 670.11, 201.64 658.35, 178.82 645.4 C156 632.45, 133.88 617.53, 115.03 600.98 C96.18 584.43, 79.97 565.94, 65.73 546.08 C51.5 526.22, 39.67 503.91, 29.62 481.82 C19.56 459.74, 10.1 436.77, 5.42 413.57 C0.75 390.38, 0.85 366.07, 1.57 342.67 C2.3 319.26, 4.09 296.34, 9.78 273.13 C15.46 249.93, 24.22 225.26, 35.68 203.44 C47.14 181.61, 62.5 160.95, 78.54 142.19 C94.58 123.44, 112.27 106.65, 131.92 90.89 C151.56 75.14, 173.16 59.48, 196.41 47.67 C219.65 35.85, 258.52 23.91, 271.39 20 C284.26 16.09, 271.49 19.05, 273.63 24.2" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(3793.484856490804 1584.619598993936) rotate(0 39.53518855571747 21.380800980371532)"><text x="0" y="30.138377061931653" font-family="Virgil, Segoe UI Emoji" font-size="34.209281568594385px" fill="#000000" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">User</text></g><g stroke-linecap="round"><g transform="translate(3788.7174156928736 1568.1086158021271) rotate(0 42.13678715170755 -37.521598857520985)" fill-rule="evenodd"><path d="M15.88 -59.07 C15.88 -59.07, 15.88 -59.07, 15.88 -59.07 M15.88 -59.07 C15.88 -59.07, 15.88 -59.07, 15.88 -59.07 M4.86 -34.2 C12.49 -42.98, 20.13 -51.76, 39.63 -74.2 M4.86 -34.2 C14.63 -45.44, 24.4 -56.67, 39.63 -74.2 M3.03 -19.89 C20.32 -39.78, 37.61 -59.67, 49.61 -73.48 M3.03 -19.89 C20.3 -39.76, 37.57 -59.63, 49.61 -73.48 M0.54 -4.83 C17.38 -24.21, 34.22 -43.58, 56.96 -69.74 M0.54 -4.83 C12.86 -19.01, 25.18 -33.19, 56.96 -69.74 M6.57 0.41 C23.62 -19.19, 40.66 -38.8, 62.99 -64.49 M6.57 0.41 C20.31 -15.39, 34.06 -31.2, 62.99 -64.49 M17.2 0.38 C29.67 -13.97, 42.14 -28.31, 68.38 -58.49 M17.2 0.38 C31.35 -15.9, 45.5 -32.18, 68.38 -58.49 M27.83 0.34 C39.42 -12.99, 51.01 -26.32, 73.76 -52.48 M27.83 0.34 C44.01 -18.26, 60.18 -36.86, 73.76 -52.48 M38.46 0.31 C47.55 -10.14, 56.64 -20.6, 77.83 -44.97 M38.46 0.31 C50.41 -13.44, 62.37 -27.19, 77.83 -44.97 M49.09 0.28 C60.96 -13.38, 72.83 -27.03, 81.9 -37.46 M49.09 0.28 C60.77 -13.15, 72.44 -26.59, 81.9 -37.46 M59.72 0.24 C65.2 -6.06, 70.68 -12.36, 85.31 -29.19 M59.72 0.24 C67.91 -9.18, 76.1 -18.59, 85.31 -29.19 M71.67 -1.3 C75.74 -5.99, 79.82 -10.68, 88.07 -20.17 M71.67 -1.3 C78 -8.59, 84.33 -15.87, 88.07 -20.17 M0 0 C0 0, 0 0, 0 0 M0 0 C0 0, 0 0, 0 0 M12.04 -0.13 C9.84 -2.05, 7.63 -3.97, 1.47 -9.32 M12.04 -0.13 C9.45 -2.39, 6.85 -4.64, 1.47 -9.32 M24.84 0.39 C18.82 -4.84, 12.81 -10.07, 2.95 -18.64 M24.84 0.39 C19.13 -4.57, 13.42 -9.54, 2.95 -18.64 M36.88 0.26 C29.69 -6, 22.49 -12.25, 3.67 -28.61 M36.88 0.26 C29.92 -5.79, 22.97 -11.84, 3.67 -28.61 M48.92 0.12 C33.56 -13.23, 18.2 -26.58, 5.14 -37.93 M48.92 0.12 C36.43 -10.73, 23.94 -21.59, 5.14 -37.93 M60.2 -0.67 C43.31 -15.35, 26.41 -30.04, 8.13 -45.93 M60.2 -0.67 C48.51 -10.83, 36.82 -21, 8.13 -45.93 M71.49 -1.45 C58.37 -12.86, 45.25 -24.26, 11.87 -53.28 M71.49 -1.45 C53.67 -16.95, 35.85 -32.44, 11.87 -53.28 M81.27 -3.56 C64.2 -18.39, 47.14 -33.22, 16.36 -59.98 M81.27 -3.56 C61.17 -21.02, 41.08 -38.49, 16.36 -59.98 M87.27 -8.94 C66.06 -27.38, 44.85 -45.82, 22.37 -65.36 M87.27 -8.94 C62.53 -30.44, 37.79 -51.95, 22.37 -65.36 M87.99 -18.91 C73.83 -31.22, 59.67 -43.53, 29.12 -70.08 M87.99 -18.91 C67.09 -37.08, 46.19 -55.25, 29.12 -70.08 M82.67 -34.13 C69.14 -45.9, 55.61 -57.66, 36.64 -74.15 M82.67 -34.13 C65.01 -49.49, 47.35 -64.84, 36.64 -74.15 M73.58 -52.64 C65.01 -60.09, 56.44 -67.54, 48.68 -74.29 M73.58 -52.64 C65.53 -59.64, 57.47 -66.64, 48.68 -74.29" stroke="#ced4da" stroke-width="1" fill="none"></path><path d="M0 0 C1.57 -8.29, 2.7 -37.22, 9.44 -49.73 C16.18 -62.23, 30.11 -74.14, 40.45 -75.04 C50.79 -75.95, 64.16 -66.8, 71.46 -55.15 C78.77 -43.51, 96.18 -14.36, 84.27 -5.16 C72.36 4.03, 14.05 -0.86, 0 0 M0 0 C1.57 -8.29, 2.7 -37.22, 9.44 -49.73 C16.18 -62.23, 30.11 -74.14, 40.45 -75.04 C50.79 -75.95, 64.16 -66.8, 71.46 -55.15 C78.77 -43.51, 96.18 -14.36, 84.27 -5.16 C72.36 4.03, 14.05 -0.86, 0 0" stroke="#000000" stroke-width="2" fill="none"></path></g></g><mask></mask><g stroke-linecap="round" transform="translate(3810.0193143957954 1454.0359742115825) rotate(0 21.574035021674263 18.877280643964696)"><path d="M4.9 6.91 C4.9 6.91, 4.9 6.91, 4.9 6.91 M4.9 6.91 C4.9 6.91, 4.9 6.91, 4.9 6.91 M1.1 23.48 C6.73 17, 12.36 10.53, 21.44 0.08 M1.1 23.48 C7.58 16.03, 14.06 8.57, 21.44 0.08 M5.17 30.99 C12.03 23.09, 18.9 15.2, 30.1 2.31 M5.17 30.99 C12.42 22.65, 19.67 14.31, 30.1 2.31 M11.21 36.24 C21.61 24.27, 32.02 12.29, 37.45 6.05 M11.21 36.24 C20.62 25.42, 30.03 14.59, 37.45 6.05 M20.52 37.72 C25.76 31.69, 31 25.66, 42.17 12.81 M20.52 37.72 C28.64 28.38, 36.76 19.04, 42.17 12.81 M33.12 35.42 C36.15 31.93, 39.19 28.44, 41.65 25.61 M33.12 35.42 C35.87 32.25, 38.62 29.09, 41.65 25.61 M7.94 33.54 C7.94 33.54, 7.94 33.54, 7.94 33.54 M7.94 33.54 C7.94 33.54, 7.94 33.54, 7.94 33.54 M24.51 37.35 C16.97 30.79, 9.42 24.23, 0.36 16.35 M24.51 37.35 C16.04 29.98, 7.57 22.62, 0.36 16.35 M33.53 34.59 C24.12 26.41, 14.71 18.23, 3.34 8.35 M33.53 34.59 C21.83 24.41, 10.12 14.24, 3.34 8.35 M39.54 29.21 C30.37 21.24, 21.19 13.26, 9.35 2.96 M39.54 29.21 C31.81 22.49, 24.09 15.78, 9.35 2.96 M43.28 21.86 C34.85 14.53, 26.43 7.21, 18.37 0.21 M43.28 21.86 C36.02 15.55, 28.77 9.25, 18.37 0.21 M40.98 9.26 C38.95 7.49, 36.92 5.73, 32.67 2.04 M40.98 9.26 C38.3 6.93, 35.63 4.61, 32.67 2.04" stroke="#ced4da" stroke-width="1" fill="none"></path><path d="M43.15 18.88 C43.15 19.97, 43.04 21.08, 42.82 22.16 C42.6 23.23, 42.27 24.31, 41.85 25.33 C41.42 26.36, 40.88 27.37, 40.26 28.32 C39.63 29.26, 38.9 30.17, 38.1 31.01 C37.3 31.85, 36.4 32.64, 35.44 33.34 C34.48 34.04, 33.44 34.68, 32.36 35.23 C31.28 35.77, 30.13 36.24, 28.95 36.62 C27.78 36.99, 26.55 37.28, 25.32 37.47 C24.09 37.66, 22.82 37.75, 21.57 37.75 C20.33 37.75, 19.06 37.66, 17.83 37.47 C16.6 37.28, 15.37 36.99, 14.2 36.62 C13.02 36.24, 11.87 35.77, 10.79 35.23 C9.71 34.68, 8.66 34.04, 7.71 33.34 C6.75 32.64, 5.85 31.85, 5.05 31.01 C4.24 30.17, 3.51 29.26, 2.89 28.32 C2.27 27.37, 1.73 26.36, 1.3 25.33 C0.87 24.31, 0.54 23.23, 0.33 22.16 C0.11 21.08, 0 19.97, 0 18.88 C0 17.78, 0.11 16.68, 0.33 15.6 C0.54 14.52, 0.87 13.45, 1.3 12.42 C1.73 11.39, 2.27 10.38, 2.89 9.44 C3.51 8.49, 4.24 7.58, 5.05 6.74 C5.85 5.91, 6.75 5.12, 7.71 4.42 C8.66 3.71, 9.71 3.08, 10.79 2.53 C11.87 1.98, 13.02 1.51, 14.2 1.14 C15.37 0.76, 16.6 0.48, 17.83 0.29 C19.06 0.1, 20.33 0, 21.57 0 C22.82 0, 24.09 0.1, 25.32 0.29 C26.55 0.48, 27.78 0.76, 28.95 1.14 C30.13 1.51, 31.28 1.98, 32.36 2.53 C33.44 3.08, 34.48 3.71, 35.44 4.42 C36.4 5.12, 37.3 5.91, 38.1 6.74 C38.9 7.58, 39.63 8.49, 40.26 9.44 C40.88 10.38, 41.42 11.39, 41.85 12.42 C42.27 13.45, 42.6 14.52, 42.82 15.6 C43.04 16.68, 43.09 18.33, 43.15 18.88 C43.2 19.42, 43.2 18.33, 43.15 18.88" stroke="#000000" stroke-width="2" fill="none"></path></g><g mask="url(#mask-u9TxbFot0Rew-nVRalO1h)" stroke-linecap="round"><g transform="translate(3302.2426634173307 1549.7713598999244) rotate(0 243.6812530180332 2.0055177973772516)"><path d="M-0.81 0.75 C80.54 1.68, 406.3 4.32, 487.63 4.7 M0.96 0.1 C82.22 0.76, 405.93 2.31, 486.83 2.95" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(3302.2426634173307 1549.7713598999244) rotate(0 243.6812530180332 2.0055177973772516)"><path d="M463.28 11.35 C470.76 9.76, 476.84 6.85, 486.83 2.95 M463.28 11.35 C468.8 10.05, 473.89 8.18, 486.83 2.95" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(3302.2426634173307 1549.7713598999244) rotate(0 243.6812530180332 2.0055177973772516)"><path d="M463.39 -5.75 C470.71 -2.86, 476.76 -1.29, 486.83 2.95 M463.39 -5.75 C468.86 -3.25, 473.92 -1.32, 486.83 2.95" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-u9TxbFot0Rew-nVRalO1h"><rect x="0" y="0" fill="#fff" width="3889.605169453397" height="1653.782395494679"></rect><rect x="3422.137977278355" y="1506.7768776973007" fill="#000" width="247.57187831401825" height="90" opacity="1"></rect></mask><g transform="translate(3422.137977278355 1506.7768776973007) rotate(0 123.51548117026687 45.396939872992334)"><text x="123.78593915700912" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">User Receives</text><text x="123.78593915700912" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">10 Shares</text></g><g mask="url(#mask-XtWPATxfHUPtSfz7eWW3S)" stroke-linecap="round"><g transform="translate(2244.2398798887184 1550.822901663957) rotate(0 -323.06202933567647 -3.420383124836917)"><path d="M0.75 0.61 C-106.95 -0.46, -538.48 -6.45, -646.15 -7.6 M-0.32 -0.12 C-108.19 -0.94, -539.56 -5.09, -647.11 -6.46" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2244.2398798887184 1550.822901663957) rotate(0 -323.06202933567647 -3.420383124836917)"><path d="M-623.52 -14.75 C-629.8 -12.11, -639.28 -8.1, -647.11 -6.46 M-623.52 -14.75 C-630.94 -12.59, -639.04 -8.72, -647.11 -6.46" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(2244.2398798887184 1550.822901663957) rotate(0 -323.06202933567647 -3.420383124836917)"><path d="M-623.71 2.35 C-629.76 -0.23, -639.18 -1.45, -647.11 -6.46 M-623.71 2.35 C-631.21 -1.41, -639.25 -3.46, -647.11 -6.46" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-XtWPATxfHUPtSfz7eWW3S"><rect x="0" y="0" fill="#fff" width="2990.3639385600713" height="1657.663667913631"></rect><rect x="1801.2978990759912" y="1524.9025185391183" fill="#000" width="239.75990295410156" height="45" opacity="1"></rect></mask><g transform="translate(1801.2978990759912 1524.9025185391183) rotate(0 119.76248314877506 22.426001521200305)"><text x="119.87995147705078" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Liquidity Sent</text></g><g stroke-linecap="round"><g transform="translate(1199.448046018057 1132.3292915259944) rotate(0 -1.3269871085543627 354.1250487082325)"><path d="M0.66 0.78 C0.2 118.68, -1.23 589.3, -1.85 707.17 M-0.45 0.14 C-1.09 118.17, -1.77 589.97, -2.38 708.14" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask></mask><g transform="translate(887.576803733316 1292.1336655252899) rotate(0 142.99195861816406 45)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">2O% Of the </text><text x="0" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">deposit amount </text></g><g transform="translate(1230.2426123297653 1299.315482117564) rotate(0 142.99195861816406 45)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">8O% Of the </text><text x="0" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">deposit amount </text></g><g transform="translate(862.9791980017758 1563.5704599260525) rotate(0 135.95394897460938 22.5)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Vault Liquidity </text></g><g transform="translate(1234.050681774184 1571.6948668185041) rotate(0 124.66796332597733 45)"><text x="0" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Project Owner</text><text x="0" y="76.71600000000001" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="start" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Allocation</text></g><g stroke-linecap="round" transform="translate(674.0117991482025 431.0595277714192) rotate(0 214.38346030570972 88.30825408575856)"><path d="M32 0 C148.81 0.13, 269.98 -0.51, 396.77 0 C419.56 2.18, 428.53 14.01, 428.77 32 C425.59 63.02, 428.83 95.81, 428.77 144.62 C425.24 167.01, 414.98 174.8, 396.77 176.62 C319.11 171.69, 244.26 174.5, 32 176.62 C9.38 178.43, 2.95 165.79, 0 144.62 C-2.97 99.99, -1.56 58.57, 0 32 C-0.79 9.81, 12.16 -2.49, 32 0" stroke="none" stroke-width="0" fill="#a5d8ff"></path><path d="M32 0 C144.34 3.06, 257.05 3.15, 396.77 0 M32 0 C152.35 1.64, 272.92 2.32, 396.77 0 M396.77 0 C419.97 1.45, 430.54 11.32, 428.77 32 M396.77 0 C419.19 2.08, 430.05 12.53, 428.77 32 M428.77 32 C428.45 64.87, 428.24 97.41, 428.77 144.62 M428.77 32 C428.17 58.69, 428.7 84.06, 428.77 144.62 M428.77 144.62 C428.77 164.93, 416.74 175.72, 396.77 176.62 M428.77 144.62 C428.29 166.38, 416.96 178.6, 396.77 176.62 M396.77 176.62 C312.34 175.5, 230.58 174.09, 32 176.62 M396.77 176.62 C267.98 177.92, 138.62 177.8, 32 176.62 M32 176.62 C10.43 175.68, 1.41 166.11, 0 144.62 M32 176.62 C11.5 175.27, -2.07 166.39, 0 144.62 M0 144.62 C0.69 103.1, -2 59.46, 0 32 M0 144.62 C-0.2 104.97, -1.59 66.54, 0 32 M0 32 C-0.99 10.05, 9.22 -1.92, 32 0 M0 32 C0.06 12.28, 8.61 1.33, 32 0" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(690.4493366023498 496.86778185717685) rotate(0 197.9459228515625 22.5)"><text x="197.9459228515625" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Calls Deposit Function</text></g><g stroke-linecap="round"><g transform="translate(1103.778719759622 475.60017392851023) rotate(0 66.93528632892196 -21.236827469414493)"><path d="M0.33 -0.53 C22.46 -7.9, 110.64 -36.37, 132.75 -43.35 M-0.96 1.8 C21.53 -5.51, 112.15 -35.13, 134.87 -42.28" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1103.778719759622 475.60017392851023) rotate(0 66.93528632892196 -21.236827469414493)"><path d="M115.12 -26.95 C119.98 -33.42, 125.25 -37.66, 134.87 -42.28 M115.12 -26.95 C122.01 -31.26, 126.67 -36.2, 134.87 -42.28" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(1103.778719759622 475.60017392851023) rotate(0 66.93528632892196 -21.236827469414493)"><path d="M109.88 -43.23 C116.41 -44.89, 123.23 -44.3, 134.87 -42.28 M109.88 -43.23 C118.34 -42.56, 124.6 -42.54, 134.87 -42.28" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask></mask><g mask="url(#mask-BjX0Ra9kQovbwlmKb1HvJ)" stroke-linecap="round"><g transform="translate(854.4965368712651 613.1587938331058) rotate(0 -0.2761189097109309 72.06314405884314)"><path d="M-0.51 -0.68 C-0.42 23.48, 0.39 119.71, 0.45 143.86 M1.42 1.58 C1.44 26.01, 0.38 121.25, 0.02 145.26" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(854.4965368712651 613.1587938331058) rotate(0 -0.2761189097109309 72.06314405884314)"><path d="M-8.23 121.66 C-7.16 130.28, -4.05 136.15, 0.02 145.26 M-8.23 121.66 C-6.69 129.15, -3.29 137.16, 0.02 145.26" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g><g transform="translate(854.4965368712651 613.1587938331058) rotate(0 -0.2761189097109309 72.06314405884314)"><path d="M8.87 121.87 C4.93 130.36, 3.02 136.16, 0.02 145.26 M8.87 121.87 C5.1 129.4, 3.21 137.35, 0.02 145.26" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></g><mask id="mask-BjX0Ra9kQovbwlmKb1HvJ"><rect x="0" y="0" fill="#fff" width="955.048774690687" height="857.2850819507921"></rect><rect x="756.2824551314875" y="662.721937891949" fill="#000" width="195.87592566013336" height="45" opacity="1"></rect></mask><g transform="translate(756.2824551314875 662.7219378919472) rotate(0 98.66816094077944 22.725897868896027)"><text x="97.93796283006668" y="31.716" font-family="Virgil, Segoe UI Emoji" font-size="36px" fill="#1e1e1e" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Sends Fess</text></g><g stroke-linecap="round" transform="translate(773.378881423946 774.2814683458992) rotate(0 77.72629283628703 69.09583227647181)"><path d="M59.01 1.76 C69.43 -1.48, 84.22 -0.43, 95.34 1.88 C106.47 4.2, 117.21 9.48, 125.75 15.65 C134.3 21.82, 141.66 30, 146.62 38.91 C151.58 47.82, 155.2 59.13, 155.51 69.12 C155.81 79.1, 153.25 89.78, 148.45 98.83 C143.65 107.88, 135.63 117.09, 126.71 123.44 C117.78 129.79, 105.92 134.61, 94.91 136.93 C83.9 139.25, 71.52 139.51, 60.65 137.35 C49.79 135.19, 38.63 130.23, 29.71 123.97 C20.79 117.7, 12.02 108.84, 7.14 99.77 C2.26 90.7, 0.43 79.59, 0.45 69.56 C0.46 59.53, 2.42 48.69, 7.22 39.58 C12.02 30.46, 19.94 21.13, 29.24 14.85 C38.53 8.57, 56.65 4.01, 62.97 1.92 C69.29 -0.18, 66.72 1.13, 67.15 2.29 M110.97 6.02 C121.26 8.94, 131.88 17.99, 138.84 25.53 C145.8 33.08, 150.03 41.55, 152.74 51.28 C155.46 61.01, 157.38 73.98, 155.13 83.91 C152.87 93.84, 146.09 102.81, 139.19 110.85 C132.3 118.89, 123.7 127.59, 113.76 132.15 C103.82 136.71, 91.18 138.19, 79.55 138.22 C67.91 138.24, 54.27 136.43, 43.95 132.28 C33.63 128.14, 24.62 121.13, 17.61 113.32 C10.61 105.52, 4.72 95.2, 1.91 85.47 C-0.91 75.75, -1.42 64.76, 0.7 54.96 C2.82 45.16, 7.76 34.73, 14.61 26.68 C21.46 18.63, 31.5 11.34, 41.79 6.65 C52.09 1.96, 64.95 -1.45, 76.37 -1.45 C87.79 -1.46, 104.62 5.28, 110.3 6.63 C115.98 7.99, 111.16 5.76, 110.43 6.67" stroke="none" stroke-width="0" fill="#ffec99"></path><path d="M91.09 1.14 C101.8 1.81, 114.03 7.97, 123.14 13.94 C132.26 19.92, 140.33 28.45, 145.78 36.98 C151.24 45.51, 155.23 55.23, 155.88 65.12 C156.52 75.01, 154.05 86.95, 149.65 96.3 C145.25 105.65, 138.07 114.75, 129.47 121.23 C120.88 127.7, 108.96 132.46, 98.08 135.16 C87.21 137.86, 75.26 139.19, 64.22 137.43 C53.19 135.66, 41.02 130.31, 31.89 124.57 C22.75 118.83, 14.61 111.57, 9.39 102.97 C4.18 94.37, 1.09 83.04, 0.59 72.95 C0.09 62.86, 2.01 51.53, 6.38 42.42 C10.74 33.3, 18.58 25.04, 26.79 18.27 C35.01 11.5, 44.32 4.71, 55.66 1.79 C67.01 -1.14, 88.05 0.48, 94.88 0.71 C101.71 0.95, 96.9 1.81, 96.65 3.19 M84.65 -0.44 C95.66 -0.26, 110.51 5.3, 120.16 10.86 C129.81 16.42, 136.61 24.73, 142.57 32.92 C148.53 41.1, 154.26 50.07, 155.92 59.97 C157.57 69.86, 156.46 82.79, 152.53 92.28 C148.59 101.78, 140.49 110.05, 132.33 116.96 C124.16 123.87, 113.79 130.12, 103.54 133.75 C93.28 137.39, 81.75 139.61, 70.8 138.79 C59.86 137.97, 47.49 134.45, 37.88 128.85 C28.27 123.24, 19.44 113.86, 13.15 105.16 C6.86 96.47, 1.77 86.23, 0.16 76.68 C-1.44 67.13, -0.33 57.11, 3.53 47.89 C7.39 38.66, 15.06 28.79, 23.31 21.3 C31.55 13.82, 42.36 6.68, 52.98 2.97 C63.6 -0.75, 81.36 -0.67, 87.04 -0.97 C92.72 -1.27, 87.54 -0.41, 87.07 1.17" stroke="#1e1e1e" stroke-width="4" fill="none"></path></g></svg>ding MomintDepo.svg…]()


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
