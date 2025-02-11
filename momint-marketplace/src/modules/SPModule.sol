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

    // State variables
    mapping(address => UserInvestment) private _userInvestments;
    mapping(address => uint256) private _userRewardDebt;
    ProjectRewards private _projectRewards;
    ProjectInfo private _project;
    uint256 private _projectId;
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
    error InvalidOwner();
    error InvalidName();
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
    event PricePerShareUpdated(
        uint256 indexed projectId,
        uint256 pricePerShare,
        uint256 oldPricePerShare
    );

    enum UpdateType {
        NAME,
        PRICE_PER_SHARE,
        TOTAL_SHARES,
        URI,
        OWNER
    }

    modifier onlyVault() {
        if (msg.sender != vaults) revert Unauthorized();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != _project.owner) revert Unauthorized();
        _;
    }

    /// @notice The constructor is kept minimal for the implementation.
    constructor() ERC1155("") {
        // No initialization logic here – clones will call initialize()
    }

    /**
     * @notice Initializes a clone with the desired parameters.
     * Can only be called once.
     */
    function initialize(
        address admin,
        address vault_,
        string memory name,
        uint256 pricePerShare,
        uint256 totalShares,
        string memory uri_,
        address owner
    ) external {
        if (_initialized) revert ProjectAlreadyInitialized();
        if (totalShares == 0) revert InvalidTotalShares();
        if (pricePerShare == 0) revert InvalidPricePerShare();
        if (bytes(uri_).length == 0) revert InvalidURI();
        if (admin == address(0)) revert InvalidAdmin();
        if (vault_ == address(0)) revert InvalidVault();
        if (owner == address(0)) revert InvalidOwner();
        if (bytes(name).length == 0) revert InvalidName();

        _projectId = 1;
        _validateInitialization(
            admin,
            vault_,
            uri_,
            totalShares,
            pricePerShare
        );
        vaults = vault_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        //  manually set the URI.
        _setURI(uri_);

        // Mint the total shares to this contract
        _mint(address(this), _projectId, totalShares, "");

        _project = ProjectInfo({
            id: _projectId,
            name: name,
            pricePerShare: pricePerShare,
            availableShares: totalShares,
            allocatedShares: 0,
            totalShares: totalShares,
            active: true,
            tokenURI: uri_,
            owner: owner
        });

        _initialized = true;
        emit ModuleInitialized(_projectId, admin, vault_);
        emit ProjectAdded(_projectId, name, pricePerShare, totalShares, uri_);
    }

    // === Public functions ===

    function invest(
        uint256 amount,
        address user
    ) external onlyVault nonReentrant returns (uint256 shares, uint256 refund) {
        if (!_project.active) revert InvalidProjectId();
        if (amount == 0) revert InvalidAmount();

        // Calculate shares based on the provided amount.
        shares = amount / _project.pricePerShare;
        uint256 cost = shares * _project.pricePerShare;
        refund = amount - cost;

        if (shares == 0) revert InvalidAmount();
        if (shares > _project.availableShares) revert InsufficientShares();

        _updateInvestmentState(user, shares, cost);
        emit SharesAllocated(user, _projectId, shares, cost, refund);
        return (shares, refund);
    }

    function divest(
        uint256 shares,
        address user
    ) external onlyVault nonReentrant returns (uint256 amount) {
        if (msg.sender != vaults) revert NotVault();
        if (!_project.active) revert ProjectInactive();

        _validateDivestment(user, shares);
        amount = shares * _project.pricePerShare;
        emit SharesDivested(user, _projectId, shares, amount);

        _updateDivestmentState(user, shares, amount);
        _updateRewardDebt(user);
        return amount;
    }

    function distributeRevenue(
        uint256 projectId,
        uint256 amount
    ) external onlyVault {
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

    function updatePricePerShare(uint256 pricePerShare) external onlyOwner {
        ProjectInfo memory project = getProjectInfo();
        emit PricePerShareUpdated(
            project.id,
            pricePerShare,
            project.pricePerShare
        );
        _project = ProjectInfo({
            id: project.id,
            name: project.name,
            pricePerShare: pricePerShare,
            availableShares: project.totalShares,
            allocatedShares: project.allocatedShares,
            totalShares: project.totalShares,
            active: project.active,
            tokenURI: project.tokenURI,
            owner: project.owner
        });
    }

    // === View functions ===

    function isSingleProject() external pure returns (bool) {
        return true;
    }

    function getActiveProjectId() external view override returns (uint256) {
        return _projectId;
    }

    function nftContract() external view override returns (IERC1155) {
        return IERC1155(address(this));
    }

    function vault() external view override returns (address) {
        return vaults;
    }

    function getProjectInfo() public view returns (ProjectInfo memory) {
        return _project;
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

    // === Internal Helper functions ===

    function _setupInitialState(
        address admin,
        address vault_,
        string memory name,
        uint256 pricePerShare,
        uint256 totalShares,
        string memory uri_,
        address owner
    ) internal {
        vaults = vault_;
        _project = ProjectInfo({
            id: _projectId,
            name: name,
            pricePerShare: pricePerShare,
            availableShares: totalShares,
            allocatedShares: 0,
            totalShares: totalShares,
            active: true,
            tokenURI: uri_,
            owner: owner
        });

        _initialized = true;
        emit ModuleInitialized(_projectId, admin, vault_);
        emit ProjectAdded(_projectId, name, pricePerShare, totalShares, uri_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _mint(address(this), _projectId, totalShares, "");
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

    // === Overrides ===

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
