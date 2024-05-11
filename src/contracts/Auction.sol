// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Auction {
   
    address payable public beneficiary; // Adresa primaoca
    uint public auctionEndTime; // Vreme trajanja u sekundama
    string private secretMessage; 

    // Trenutno stanje aukcije.
    address public highestBidder; 
    uint public highestBid;

    mapping(address => uint[]) public bidsByBidder; // Mapa koja prati sve ponude svakog korisnika

    mapping(address => uint) pendingReturns;

    bool ended;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();

    constructor(
        uint biddingTime,
        address payable beneficiaryAddress,
        string memory secret // Parametar za podatke tajne poruke
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
        secretMessage = secret;
    }

    function bid() external payable {
        if (ended)
            revert AuctionAlreadyEnded();

        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        bidsByBidder[msg.sender].push(msg.value); // Čuvamo samo iznos ponude

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }

    function getSecretMessage() external view returns (string memory) {
        require(ended, "The auction has not ended yet.");
        require(msg.sender == highestBidder, "Only the auction winner can access the secret code.");
        return secretMessage;
    }

    function getBidHistoryByBidder(address bidder) external view returns (uint[] memory) {
        return bidsByBidder[bidder];
    }
}
