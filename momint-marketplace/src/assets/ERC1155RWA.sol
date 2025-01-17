// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title ERC1155RWA
 * @dev Implementation of a Real World Asset (RWA) token using ERC1155 standard with royalty support
 * Metadata and regulatory information is stored on IPFS
 */
contract ERC1155RWA is 
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IERC2981   
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");

    uint256 private _nextTokenId;

    struct RoyaltyInfo {
        address[] recipients;
        uint256[] shares;      // Basis points (100 = 1%)
        uint256 totalShares;   // Total should be <= 10000 (100%)
    }
    
    struct Asset {
        uint256 totalSupply;
        string metadataURI;    // IPFS hash containing all metadata and regulatory info
        RoyaltyInfo royalties;
    }
    
    mapping(uint256 => Asset) public assets;
    
    event AssetCreated(uint256 indexed tokenId, uint256 supply, string metadataURI);
    event MetadataURIUpdated(uint256 indexed tokenId, string newUri);
    event RoyaltiesUpdated(uint256 indexed tokenId, address[] recipients, uint256[] shares);
    event BatchAssetsCreated(uint256[] tokenIds, uint256[] supplies, string[] metadataURIs);
    
   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        string memory uri_
    ) public initializer {
        require(admin != address(0), "Invalid admin address");
        require(bytes(uri_).length > 0, "Invalid URI");

        __ERC1155_init(uri_);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __AccessControl_init();
        __Pausable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(ROYALTY_ROLE, admin);

        _nextTokenId = 0;
    }

    function mint(
        uint256 initialSupply,
        string memory metadataURI,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyShares
    ) external onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        
        uint256 tokenId = _nextTokenId++;
        
        Asset storage newAsset = assets[tokenId];
        newAsset.totalSupply = initialSupply;
        newAsset.metadataURI = metadataURI;
        
        if(royaltyRecipients.length > 0) {
            setRoyalties(tokenId, royaltyRecipients, royaltyShares);
        }
        
        _mint(msg.sender, tokenId, initialSupply, "");
        
        emit AssetCreated(tokenId, initialSupply, metadataURI);
        return tokenId;
    }

    function batchMint(
        uint256[] memory initialSupplies,
        string[] memory metadataURIs,
        address[][] memory royaltyRecipients,
        uint256[][] memory royaltyShares
    ) external onlyRole(MINTER_ROLE) whenNotPaused returns (uint256[] memory) {
        require(
            initialSupplies.length == metadataURIs.length &&
            initialSupplies.length == royaltyRecipients.length &&
            initialSupplies.length == royaltyShares.length,
            "Array lengths must match"
        );

        uint256[] memory tokenIds = new uint256[](initialSupplies.length);

        for(uint256 i = 0; i < initialSupplies.length; i++) {
            require(bytes(metadataURIs[i]).length > 0, "Metadata URI cannot be empty");
            
            tokenIds[i] = _nextTokenId++;
            
            Asset storage newAsset = assets[tokenIds[i]];
            newAsset.totalSupply = initialSupplies[i];
            newAsset.metadataURI = metadataURIs[i];
            
            if(royaltyRecipients[i].length > 0) {
                setRoyalties(tokenIds[i], royaltyRecipients[i], royaltyShares[i]);
            }
            
            _mint(msg.sender, tokenIds[i], initialSupplies[i], "");
        }
        
        emit BatchAssetsCreated(tokenIds, initialSupplies, metadataURIs);
        return tokenIds;
    }

    function setRoyalties(
        uint256 tokenId,
        address[] memory recipients,
        uint256[] memory shares
    ) public {
        require(
            hasRole(ROYALTY_ROLE, msg.sender) || 
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must have royalty role"
        );
        require(recipients.length == shares.length, "Arrays length mismatch");
        require(_exists(tokenId), "Token does not exist");
        
        uint256 totalShares = 0;
        for(uint256 i = 0; i < shares.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            totalShares += shares[i];
        }
        require(totalShares <= 10000, "Total royalties cannot exceed 100%");

        Asset storage asset = assets[tokenId];
        asset.royalties.recipients = recipients;
        asset.royalties.shares = shares;
        asset.royalties.totalShares = totalShares;

        emit RoyaltiesUpdated(tokenId, recipients, shares);
    }

    function updateMetadataURI(uint256 tokenId, string memory newUri) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_exists(tokenId), "Token does not exist");
        require(bytes(newUri).length > 0, "URI cannot be empty");
        assets[tokenId].metadataURI = newUri;
        emit MetadataURIUpdated(tokenId, newUri);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        Asset storage asset = assets[tokenId];
        
        if (asset.royalties.recipients.length > 0) {
            receiver = asset.royalties.recipients[0];
            royaltyAmount = (salePrice * asset.royalties.totalShares) / 10000;
        }
    }

    function getRoyaltyDetails(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (
            address[] memory recipients,
            uint256[] memory amounts
        )
    {
        require(_exists(tokenId), "Token does not exist");
        Asset storage asset = assets[tokenId];
        
        recipients = asset.royalties.recipients;
        amounts = new uint256[](recipients.length);
        
        for(uint256 i = 0; i < recipients.length; i++) {
            amounts[i] = (salePrice * asset.royalties.shares[i]) / 10000;
        }
        
        return (recipients, amounts);
    }

    function getOwnerTokens(address owner) 
        external 
        view 
        returns (uint256[] memory tokenIds, uint256[] memory balances) 
    {
        uint256 count = 0;
        uint256[] memory tempTokenIds = new uint256[](1000); // Limit to 1000 tokens
        uint256[] memory tempBalances = new uint256[](1000);
        
        for(uint256 i = 0; i < _nextTokenId && i < 1000; i++) {
            if (_exists(i) && balanceOf(owner, i) > 0) {
                tempTokenIds[count] = i;
                tempBalances[count] = balanceOf(owner, i);
                count++;
            }
        }
        
        tokenIds = new uint256[](count);
        balances = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            tokenIds[i] = tempTokenIds[i];
            balances[i] = tempBalances[i];
        }
    }

    function getAssetInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 totalSupply,
            string memory metadataURI,
            address[] memory royaltyRecipients,
            uint256[] memory royaltyShares
        )
    {
        require(_exists(tokenId), "Token does not exist");
        Asset storage asset = assets[tokenId];
        return (
            asset.totalSupply,
            asset.metadataURI,
            asset.royalties.recipients,
            asset.royalties.shares
        );
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _nextTokenId && assets[tokenId].totalSupply > 0;
    }

    function uri(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return assets[tokenId].metadataURI;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Hook that is called before any token transfer
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) whenNotPaused {
        super._update(from, to, ids, values);
    }


function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlUpgradeable, IERC165)
    returns (bool)
{
    return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
}
}