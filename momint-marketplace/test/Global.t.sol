// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Global {
    address admin = 0x8907C46657c18C7E12efCe6aE7E820cC12Ee2d61;
    address feeRecipient = 0xbAd85cBDD525D0144f8bCcaF73c249A56507a459;
    address user1 = 0x07aE8551Be970cB1cCa11Dd7a11F47Ae82e70E67;
    address user2 = 0x380ab40B520C99d40ADA7630e4aAdAb2D12A12bD;
    address user3 = 0x3bDB03ad7363152DFBc185Ee23eBC93F0CF93fd1;
    address usdtWhale = 0x18Eb25a15eC48Db3C42A0F41EC0a716Ba6b54514;
    IERC20 public USDT = IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);

    address public implementation;
}
