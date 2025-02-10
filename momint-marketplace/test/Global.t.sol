// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Global {
    address admin = 0x8907C46657c18C7E12efCe6aE7E820cC12Ee2d61;
    address feeRecipient = 0xbAd85cBDD525D0144f8bCcaF73c249A56507a459;
    address minter = 0x4c968f6bEecf1906710b08e8B472b8Ba6E75F957;
    address pauser = 0xDbA6C5c1693B1EC52098cd419787fe5b0c9DBc19;
    address royaltyManager = 0xF474Ff07E0b2f8Da55cD3a364231F8802021430A;
    address LISK_WHALE = 0xC8CFB2922414DcD4Eb61380A8b59bB8166c225f1; // We'll need a whale address
    address seller = 0xC20e318fe1830DE929bB8eE57F6209a89F0ab00F;
    address buyer = 0xC287129dcB73bd7065C3fB97f7FB7981f59166EB;
    address user1 = 0x07aE8551Be970cB1cCa11Dd7a11F47Ae82e70E67;
    address user2 = 0x380ab40B520C99d40ADA7630e4aAdAb2D12A12bD;
    address user3 = 0x3bDB03ad7363152DFBc185Ee23eBC93F0CF93fd1;
    address usdtWhale = 0x18Eb25a15eC48Db3C42A0F41EC0a716Ba6b54514;
    IERC20 public USDT = IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);
    IERC20 public LISK_TOKEN =
        IERC20(0xac485391EB2d7D88253a7F1eF18C37f4242D1A24);

    address public implementation;
}
