// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IMarketplace {
    function setFeeRecipient(address newRecipient) external;

    function setProtocolFee(uint256 newFee) external;

    function setAcceptedToken(address token, bool accepted) external;

    function pause() external;

    function unpause() external;
}
