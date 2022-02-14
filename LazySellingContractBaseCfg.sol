// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

library LazySellingContractBaseCfg {
    
    // address for receive a fee
    address payable public constant feeReceiverAddress = payable(0xD0d896F4E701054D3F5ed64a5FF470D227eE5D16); // U3
    

    // fee from auction per thousand
    uint public constant fee = 30; // = 3%

}