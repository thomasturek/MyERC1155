// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

import "./utils/LazySellingContractBase.sol";

contract LazyFixPrice1 is LazySellingContractBase {

    /*constructor()
    LazySellingContractBase(
            1642764555,
            1642775355,
            address(0x7813D367C5E4E5f4eC0a8a3D76C05dD4e2F46a51),
            3,
            100000000000000000,
            payable(0xf7eE84771c06a4c51C632A18E3025B09C91E4d42)
        ) 
    {
         //buyerAddress = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    }*/

    constructor(
        uint _auctionStartTime,
        uint _auctionEndTime,
        address _lnftAddress,
        uint _tokenId,
        uint _amount,
        address payable _revenueAddress
    ) 
        LazySellingContractBase(
            _auctionStartTime,
            _auctionEndTime,
            _lnftAddress,
            _tokenId,
            _amount,
            _revenueAddress
        ) 
    {

    }

    function bid(address _offerTokenAddress) payable public override 
        noOwner
        noAuctionClosed
        noCanceled
        onlyInAuctionTime
        auctionTokenOwner
    {
        require(
            _offerTokenAddress != address(0),
            "Address for token is empty."
        );

        require(
            _isContract(_offerTokenAddress) == false,
            "Address for token is contract."
        );

        require(
            highestOfferFinancialAddress == address(0),
            "It is not possible to bid. Auction has a buyer."
        );
        require(
            msg.value == highestOffer,
            "Your amount is different from auction amount."
        );

        _bid(payable(msg.sender), _offerTokenAddress, msg.value, msg.value);
    }

}