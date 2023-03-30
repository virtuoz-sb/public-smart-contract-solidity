// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Raffle.sol";
import "./interfaces/IRaffleFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RaffleFactory is Ownable, IRaffleFactory {
    event CreatedRaffle(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed raffleAddress
    );

    event BoughtRaffleTicket(
        address indexed raffleAddress,
        address indexed buyer,
        uint256 indexed tickets
    );

    constructor() {}

    function createRaffle(address nftAddress, uint256 tokenId)
        external
        override
        onlyOwner
        returns (address raffleAddress)
    {
        Raffle raffleContract = new Raffle(nftAddress, tokenId);
        raffleAddress = address(raffleContract);
        emit CreatedRaffle(nftAddress, tokenId, raffleAddress);
        return raffleAddress;
    }

    function buyRaffleTickets(
        address raffleAddress,
        address buyer,
        uint256 tickets
    ) external override onlyOwner {
        Raffle raffleContract = Raffle(raffleAddress);
        raffleContract.batchMint(buyer, tickets);
        emit BoughtRaffleTicket(raffleAddress, buyer, tickets);
    }

    function ownerOfTicket(address raffleAddress, uint256 ticketId)
        external
        override
        view
        returns (address)
    {
        Raffle raffleContract = Raffle(raffleAddress);
        address owner = raffleContract.ownerOf(ticketId);
        return owner;
    }
}
