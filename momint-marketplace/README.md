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

## **Marketplace Controller Contract**
## Momint Vault Documentation

The Momint Vault System is designed to manage real-world asset investments through a modular architecture. The system consists of several key components:

1. Core Vault Contract
2. Module System
3. Controller Framework
4. Storage Architecture

### Key Features
- Modular investment modules
- Multi-token support
- Automated returns distribution
- Liquidity management

## System Architecture

### 1. Core Vault (MomintVault)

The vault serves as the primary entry point for user interactions and liqudity management.

#### Key Components:

**Asset Management**
Assets inside the 
```solidity
function deposit(uint256 assets, address receiver, uint256 moduleIndex)
external
returns (uint256 shares)
```
```solidity 
function withdraw(uint256 shares, address receiver)
external
returns (uint256 assets)
```

**Returns Distribution**

### Overview
The returns distribution system manages how investment returns are distributed to projects through a structured epoch-based mechanism.

#### Epoch Creation
1. When returns are received from investments the admins will have the ability to call the following function for share holders to claim :
   - A new epoch is created with a unique ID
   - The total return amount is recorded
   - The system calculates per-share distribution

2. **Claim Process**
   - Users claim their portion based on share ownership of a project 
   - System verifies:
     - User's share ownership at epoch time
     - No previous claims for this epoch
     - Valid epoch ID

**Liquidity Control System**

### Overview
The liquidity control system ensures the vault maintains sufficient liquidity for withdrawals while maximizing efficiency.

#### Liquidity Ratios
- **Minimum Liquidity Hold (minLiquidityHoldBP)**
  - Percentage of deposits kept as liquid reserves
  - Default: 30% (3000 basis points)
  - Adjustable by governance 

- **Maximum Owner Share (maxOwnerShareBP)**
  - Maximum allocation to project owners
  - Default: 70% (7000 basis points)
  - Adjustable by governance

**Fee Management System**

### Overview
Multi Fee structure managing various operational aspects.

### Fee Types

1. **Deposit Fee**
   - Charged on deposit
   - Default: 5% (500 basis points)
   - Calculation: `depositAmount * (depositFee / 10000)`
   - - Adjustable by governance

2. **Withdrawal Fee**
   - Charged on withdrawal
   - Default: 1% (100 basis points)
   - Calculation: `withdrawAmount * (withdrawalFee / 10000)`
   - - Adjustable by governance

3. **Protocol Fee**
   - Platform operation fee
   - Default: 3% (300 basis points)
   - Applied to returns
   - - Adjustable by governance


### 2. Module System

Modules are pluggable components that implement specific recipes.

## **Core Relationship**

The Vault and Module system operates on a "Parent-Child" architecture where:

### **Vault (Parent)**

- Acts as the primary entry point for all user interactions
- Holds and manages all actual assets (e.g., USDT)
- Controls access to funds
- Maintains the source of truth for total shares and assets
- Coordinates all module activities

### **Modules (Child)**

- Handle investment state tracking
- Calculate share allocations
- Track user positions
- Never directly handle assets
- Operate as "bookkeepers" for specific recipes(Projects)

## **Key Interaction Flows**

### **1. Investment Process**
- **User Entry**
- User interacts only with the vault
- Sends assets to vault
- Specifies which module (Project) to use

- **Vault Processing**
- Receives and holds assets
- Calculates and deducts fees
- Requests share calculation from module

- **Module Role**
- Calculates appropriate share allocation
- Updates internal state to track investment
- Returns share calculation to vault
  
- **Completion**
- Vault mints shares to user
- Assets remain in vault
- Module maintains record of position

 ### **Returns Distribution**

- **Initial Return Receipt**
- Returns are sent to vault
- Vault creates new distribution epoch for module(Project)
  
- **Claim Process**
- Users request claims through vault
- Vault checks with module for share verification
- Module confirms user's position
- Vault handles actual distribution of returns

### **Withdrawal Process**

- **User Request**
- User requests withdrawal from vault
- Specifies share amount to withdraw
  
- **Validation**
- Vault checks with module for position verification
- Module confirms user's share ownership
- Vault verifies sufficient liquidity
  
- **Execution**
- Module updates state to reflect withdrawal
- Vault burns shares
- Vault transfers assets to user

