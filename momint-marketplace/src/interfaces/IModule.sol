// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IModule {
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

    struct SharePrice {
        uint256 projectId;
        uint256 pricePerShare;
        uint256 availableShares;
    }

    struct UserInvestment {
        mapping(uint256 => uint256) projectShares; // projectId => shares
        uint256 totalShares;
        uint256 totalInvested;
    }

    struct ProjectRewards {
        uint256 revenuePerShare;
        uint256 totalDistributed;
        uint256 lastDistributionTime;
    }

    // Core view functions
    function isSingleProject() external view returns (bool);

    function getActiveProjectId() external view returns (uint256);

    function nftContract() external view returns (IERC1155);

    function vault() external view returns (address);

    // Investment functions
    function invest(
        uint256 amount,
        address user
    ) external returns (uint256 sharesIssued, uint256 refund);

    function divest(
        uint256 shares,
        address user
    ) external returns (uint256 amount);

    // Rewards
    function distributeRevenue(uint256 projectId, uint256 amount) external;

    function getUserReturns(address user) external view returns (uint256);

    function getUserShares(address user) external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getAvailableShares() external view returns (uint256);

    function getAllocatedShares() external view returns (uint256);

    function getProjectInfo() external view returns (ProjectInfo memory);

    // Events
    event SharesAllocated(
        address indexed user,
        uint256 indexed projectId,
        uint256 shares,
        uint256 invested,
        uint256 refunded
    );

    event SharesDivested(
        address indexed user,
        uint256 indexed projectId,
        uint256 shares,
        uint256 amount
    );

    event RevenueDistributed(
        uint256 indexed projectId,
        uint256 amount,
        uint256 newRevenuePerShare
    );

    event ProjectAdded(
        uint256 indexed projectId,
        string name,
        uint256 pricePerShare,
        uint256 totalShares,
        string tokenURI
    );
}
