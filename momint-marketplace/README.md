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

### Overview
The Momint Marketplace System is a solution for trading Real World Assets (RWA) tokens. It consists of the following three main components:

1. ERC1155 RWA Token Contract

## **Overview**
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


## Momint Vault Documentation
