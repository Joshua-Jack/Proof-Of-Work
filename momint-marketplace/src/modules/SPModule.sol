// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IModule} from "../interfaces/IModule.sol";
import {ModuleMath} from "../libraries/ModuleMath.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {console} from "forge-std/console.sol";

contract SPModule is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    AccessControl,
    Pausable,
    ERC1155Holder,
    ReentrancyGuard,
    IModule
{
    using ModuleMath for uint256;
    uint8 public constant decimalOffset = 9;

    mapping(address => UserInvestment) private _userInvestments;
    mapping(address => uint256) private _userRewardDebt;
    ProjectRewards private _projectRewards;
    ProjectInfo private _project;
    uint256 private immutable _projectId;
    bool private _initialized;
    address public vaults;

    // Errors
    error TransferAfterInitialization();
    error InvalidProjectId();
    error ProjectAlreadyInitialized();
    error Unauthorized();
    error InsufficientShares();
    error InvalidAmount();
    error InvalidAdmin();
    error InvalidVault();
    error InvalidURI();
    error InvalidTotalShares();
    error InvalidPricePerShare();
    error ProjectInactive();
    error NotVault();
    event ModuleInitialized(
        uint256 indexed projectId,
        address admin,
        address vault
    );
    event SharesMinted(
        address indexed to,
        uint256 indexed projectId,
        uint256 amount
    );

    modifier onlyVault() {
        if (msg.sender != vaults) revert Unauthorized();
        _;
    }

    constructor(
        uint256 projectId_,
        address admin,
        address vault_,
        string memory name,
        uint256 pricePerShare,
        uint256 totalShares,
        string memory uri_
    ) ERC1155(uri_) {
        _projectId = projectId_;
        _validateInitialization(
            admin,
            vault_,
            uri_,
            totalShares,
            pricePerShare
        );
        vaults = vault_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _mint(address(this), _projectId, totalShares, "");

        _project = ProjectInfo({
            id: _projectId,
            name: name,
            pricePerShare: pricePerShare,
            availableShares: totalShares,
            allocatedShares: 0,
            totalShares: totalShares,
            active: true,
            tokenURI: uri_
        });

        emit ModuleInitialized(_projectId, admin, vault_);
        emit ProjectAdded(_projectId, name, pricePerShare, totalShares, uri_);
    }

    /// Public functions
    function invest(
        uint256 amount,
        address user
    ) external onlyVault nonReentrant returns (uint256 shares, uint256 refund) {
        if (!_project.active) revert InvalidProjectId();
        if (amount == 0) revert InvalidAmount();

        shares = amount / _project.pricePerShare;

        // Calculate actual cost
        uint256 cost = shares * _project.pricePerShare;

        // Calculate refund
        refund = amount - cost;
        // Validate shares
        if (shares == 0) revert InvalidAmount();
        if (shares > _project.availableShares) revert InsufficientShares();

        // Update state with normalized values
        _updateInvestmentState(user, shares, cost);

        emit SharesAllocated(user, _projectId, shares, cost, refund);
        return (shares, refund);
    }

    function divest(
        uint256 shares,
        address user
    ) external nonReentrant returns (uint256 amount) {
        // Only vault can call this function
        if (msg.sender != vaults) revert NotVault();
        if (!_project.active) revert ProjectInactive();

        // Validate divestment
        _validateDivestment(user, shares);

        // Calculate amount to return based on share price
        amount = shares * _project.pricePerShare;

        // Update user's investment state
        _updateDivestmentState(user, shares, amount);

        // Burn the shares from the module
        _burn(address(this), _projectId, shares);

        // Update reward debt
        _updateRewardDebt(user);

        emit SharesDivested(user, _projectId, shares, amount);
        return amount;
    }

    function mintShares(uint256 amount) external onlyVault nonReentrant {
        _mint(address(this), _projectId, amount, "");
        emit SharesMinted(address(this), _projectId, amount);
    }

    function addProject(
        uint256 projectId,
        string calldata name,
        uint256 pricePerShare,
        uint256 totalShares,
        string calldata tokenURI
    ) external nonReentrant {
        // Implementation
    }

    function distributeRevenue(uint256 projectId, uint256 amount) external {
        if (projectId != _projectId) revert InvalidProjectId();
        if (amount == 0) revert InvalidAmount();
        if (_project.allocatedShares == 0) revert InsufficientShares();

        uint256 newRevenuePerShare = ModuleMath.calculateNewRevenuePerShare(
            amount,
            _project.allocatedShares
        );

        _updateRevenueState(amount, newRevenuePerShare);
        emit RevenueDistributed(projectId, amount, newRevenuePerShare);
    }

    /// View functions
    function isSingleProject() external pure returns (bool) {
        return true;
    }

    function getActiveProjectId()
        external
        pure
        override
        returns (uint256 projectId)
    {
        return projectId;
    }

    function getCheapestShares(
        uint256 maxAssets
    )
        external
        view
        override
        returns (SharePrice memory cheapestShares, bool hasShares)
    {
        return (cheapestShares, hasShares);
    }

    function nftContract() external view override returns (IERC1155) {
        return IERC1155(address(this));
    }

    function vault() external view override returns (address) {
        return vaults;
    }

    function getPendingRewards(
        address user
    ) external view override returns (uint256) {
        return 0;
    }

    function getUserInvestment(
        address user
    )
        external
        view
        returns (uint256 shares, uint256 totalInvested, uint256 rewardDebt)
    {
        UserInvestment storage investment = _userInvestments[user];
        return (
            investment.projectShares[_projectId],
            investment.totalInvested,
            _userRewardDebt[user]
        );
    }

    function getAllocatedShares() external view returns (uint256) {
        return _project.allocatedShares;
    }

    function getAvailableShares() external view returns (uint256) {
        return _project.availableShares;
    }

    function getTotalShares() external view returns (uint256) {
        return _project.totalShares;
    }

    function getUserReturns(address user) external view returns (uint256) {
        return _userRewardDebt[user];
    }

    function getUserShares(address user) external view returns (uint256) {
        return _userInvestments[user].projectShares[_projectId];
    }

    /// Internal Helper functions
    function _setupInitialState(
        address admin,
        address vault_,
        string memory name,
        uint256 pricePerShare,
        uint256 totalShares,
        string memory uri_
    ) internal {
        vaults = vault_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _mint(address(this), _projectId, totalShares, "");

        _project = ProjectInfo({
            id: _projectId,
            name: name,
            pricePerShare: pricePerShare,
            availableShares: totalShares,
            allocatedShares: 0,
            totalShares: totalShares,
            active: true,
            tokenURI: uri_
        });

        _initialized = true;
        emit ModuleInitialized(_projectId, admin, vault_);
        emit ProjectAdded(_projectId, name, pricePerShare, totalShares, uri_);
    }

    function _updateInvestmentState(
        address user,
        uint256 shares,
        uint256 cost
    ) internal {
        _project.availableShares -= shares;
        _project.allocatedShares += shares;
        _userInvestments[user].projectShares[_projectId] += shares;
        _userInvestments[user].totalShares += shares;
        _userInvestments[user].totalInvested += cost;
    }

    function _updateDivestmentState(
        address user,
        uint256 shares,
        uint256 amount
    ) internal {
        _userInvestments[user].projectShares[_projectId] -= shares;
        _userInvestments[user].totalShares -= shares;
        _userInvestments[user].totalInvested -= amount;
        _project.availableShares += shares;
        _project.allocatedShares -= shares;
    }

    function _updateRevenueState(
        uint256 amount,
        uint256 newRevenuePerShare
    ) internal {
        _projectRewards.revenuePerShare += newRevenuePerShare;
        _projectRewards.totalDistributed += amount;
        _projectRewards.lastDistributionTime = block.timestamp;
    }

    function _updateRewardDebt(address user) internal {
        uint256 shares = _userInvestments[user].projectShares[_projectId];
        _userRewardDebt[user] = ModuleMath.calculateRewardDebt(
            shares,
            _projectRewards.revenuePerShare
        );
    }

    function _validateDivestment(address user, uint256 shares) internal view {
        UserInvestment storage investment = _userInvestments[user];
        if (investment.totalShares < shares) revert InsufficientShares();
        if (investment.projectShares[_projectId] < shares)
            revert InsufficientShares();
    }

    function _validateInitialization(
        address admin,
        address vault_,
        string memory uri_,
        uint256 totalShares,
        uint256 pricePerShare
    ) internal pure {
        if (admin == address(0)) revert InvalidAdmin();
        if (vault_ == address(0)) revert InvalidVault();
        if (bytes(uri_).length == 0) revert InvalidURI();
        if (totalShares == 0) revert InvalidTotalShares();
        if (pricePerShare == 0) revert InvalidPricePerShare();
    }

    // Required overrides
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155, ERC1155Holder, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
