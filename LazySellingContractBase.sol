// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./LazySellingContractBaseCfg.sol";

abstract contract LazySellingContractBase is Ownable, ERC1155Holder {

    //event HighestBidIncreased(address indexed _finacialAddress, address indexed _tokenAddress, uint _totalAmount, uint _bid);
    event Bid(uint _timeStampUtc, address indexed _finacialAddress, address indexed _tokenAddress, uint _totalAmount, uint _bid);

    event IsAuctionTokenOwner(address indexed _contractAddress, uint _tokenId);
 
    event WithdrawalBid(address indexed _receiverAddress, uint _amount);
    event WithdrawalFee(address indexed _receiverAddress, uint _fee);
    event WithdrawalRevenue(address indexed _receiverAddress, uint _revenue);
    event TokenTransfer(address indexed _contractAddress, uint _tokenId, address indexed _ownerAddress, string msg);

    event AuctionEnded(address indexed win_finacialAddressner, address indexed _tokenAddress, uint amount);
    event AuctionCanceled();

    address payable public immutable feeReceiverAddress; // address for receive a fee
    uint public immutable fee; // per thousand

    uint public immutable auctionStartTime; // start auction in seconds
    uint public immutable auctionEndTime; // end auction in seconds

    // info about token
    address public immutable lnftAddress; // address of ERC1155
    uint public immutable tokenId; // token id in ERC1155
    address public immutable tokenOwnerAddress; // token owner
    IERC1155 internal immutable lnft; // instance of ERC1155

    address payable public immutable revenueAddress; // address for receive the MATIC from auction



    uint public highestOffer; // current MATIC

    // address of buyer
    address public highestOfferFinancialAddress; // finance address of offer
    address public highestOfferTokenAddress; //token address of offer
    
    bool public isAuctionTokenOwner; //check the auction is owner of token in ERC1155

    bool public isAuctionClosed;
    bool public isCanceled;

    mapping(address => uint) public pendingReturns; // accounts and amounts(bids) to return 
    uint public feeAmount;
    uint public revenueAmount;

    constructor(
        uint _auctionStartTime, //seconds
        uint _auctionEndTime, //seconds
        address _lnftAddress,
        uint256 _tokenId,
        uint _amount,
        address payable _revenueAddress
    )  {
        feeReceiverAddress = LazySellingContractBaseCfg.feeReceiverAddress;
        fee = LazySellingContractBaseCfg.fee;

        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
        lnftAddress = _lnftAddress;
        tokenId = _tokenId;
        tokenOwnerAddress = msg.sender;
        highestOffer = _amount;
        revenueAddress = _revenueAddress;

        //----------------------------
        isAuctionTokenOwner = false;
        lnft = IERC1155(_lnftAddress);
    }

/*require pokud je FALSE tak konec*/
//https://medium.com/blockchannel/the-use-of-revert-assert-and-require-in-solidity-and-the-new-revert-opcode-in-the-evm-1a3a7990e06e

    function cancel() public 
        onlyOwner 
        noCanceled 
    {
        require(
            highestOfferFinancialAddress == address(0),
            "It is not possible to cancel it. Auction has a offer."
        );

        isCanceled = true;

        emit AuctionCanceled();
    }
    
    function bid(address _offerTokenAddress) public payable virtual;

    function end() public 
        noAuctionClosed 
        noCanceled
    {
        require(
            auctionEndTime < block.timestamp, 
            "Auction not yet ended."
        );

        isAuctionClosed = true;

        emit AuctionEnded(highestOfferFinancialAddress, highestOfferTokenAddress, highestOffer);

    }

    function tokenTransfer() public virtual     
    {
        require(isCanceled || isAuctionClosed, "It is no possible to transfer token. Auction is not canceled or closed.");

        if(highestOfferFinancialAddress == address(0)) {
            _tokenTransferBackToOwner();
        }
        else {
            _tokenTransferToWinner();
        }
    }

    //https://solidity-by-example.org/sending-ether/
    function withdrawalBid() public virtual {
        uint refund  = pendingReturns[msg.sender];
        if (refund  > 0) {
            pendingReturns[msg.sender] = 0;
            (bool sent, ) = payable(msg.sender).call{value: refund }("");
            if (!sent) {
                pendingReturns[msg.sender] = refund ;
                require(false, "Transfer refund failed");
            }
            emit WithdrawalBid(msg.sender, refund);
        }
    }
    function withdrawalFee() public virtual 
        auctionClosed
    {
        (bool sent, ) = feeReceiverAddress.call{value: feeAmount}("");
        require(sent, "Transfer fee failed");
        emit WithdrawalFee(feeReceiverAddress, feeAmount);
        feeAmount = 0;
    }
    function withdrawalRevenue() public virtual 
        auctionClosed
    {
        (bool sent, ) = revenueAddress.call{value: revenueAmount}("");
        require(sent, "Transfer revenue failed");
        emit WithdrawalRevenue(revenueAddress, revenueAmount);
        revenueAmount = 0;
    }

    //--------------------
    //---------------------------------
    function _tokenTransferBackToOwner() internal {
        isAuctionTokenOwner = lnft.balanceOf(address(this), tokenId) == 1;
        if(isAuctionTokenOwner) {
            lnft.safeTransferFrom(address(this), tokenOwnerAddress, tokenId, 1, "Token was returned");
            emit TokenTransfer(lnftAddress, tokenId, tokenOwnerAddress, "Token was returned");
        }        
    } 

    function _tokenTransferToWinner() internal {
        //***** pokud bude highestBidderTokenAddress null ne 0 tak prevest na highestBidderFinancialAddress???????
        lnft.safeTransferFrom(address(this), highestOfferTokenAddress, tokenId, 1, "Token was sold");
        emit TokenTransfer(lnftAddress, tokenId, highestOfferTokenAddress, "Token was sold");        
    }

    function _bid(address payable _financialAddress, address _tokenAddress, uint _offer, uint _nbid) internal {    

        highestOfferFinancialAddress = _financialAddress;
        highestOfferTokenAddress = _tokenAddress;
        highestOffer = _offer;

        feeAmount = (highestOffer / 1000) * fee;
        revenueAmount = highestOffer - feeAmount;

        emit Bid(block.timestamp, _financialAddress, _tokenAddress, _offer, _nbid); 
    }

    function _isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //--------------------------------------------

    modifier noOwner {
        require(msg.sender != owner(),
            "Ownable: caller is the owner");
        _;
    }

    modifier auctionClosed {
        require(
            isAuctionClosed == true,
            "Auction is closed."
        );
        _;
    }
    modifier noAuctionClosed {
        require(
            isAuctionClosed == false,
            "Auction is not closed."
        );
        _;
    }

    modifier canceled {
        require(
            isCanceled == true,
            "Auction is not canceled."
        );
        _;
    }
    modifier noCanceled {
        require(
            isCanceled == false,
            "Auction is canceled."
        );
        _;
    }

    modifier onlyInAuctionTime {
        require(
            auctionStartTime <= block.timestamp && block.timestamp <= auctionEndTime,
            "Auction is not active."
        );
        _;
    }

    modifier auctionTokenOwner{
        if(!isAuctionTokenOwner){
            isAuctionTokenOwner = lnft.balanceOf(address(this), tokenId) == 1;
            emit IsAuctionTokenOwner(lnftAddress, tokenId);
        }
        require(
            isAuctionTokenOwner == true,
            "Auction is not owner of token."
        );
        _;
    }
}