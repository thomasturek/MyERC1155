// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./utils/LazySellingContractBase.sol";

contract LazyAuction1 is LazySellingContractBase {

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

    function bid(address _offerTokenAddress) public payable override
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


        uint offer = pendingReturns[msg.sender] + msg.value;
        require(
            offer > highestOffer,
            "There already is a higher offer."
        );

        if (highestOffer != 0){
            pendingReturns[highestOfferFinancialAddress] = highestOffer;
        }
        
        pendingReturns[msg.sender] = 0;

        _bid(payable(msg.sender), _offerTokenAddress, offer, msg.value);

    }

}