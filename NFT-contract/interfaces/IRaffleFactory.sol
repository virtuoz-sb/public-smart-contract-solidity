// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRaffleFactory {
    function createRaffle(address nftAddress, uint256 tokenId)
        external
        returns (address);

    function buyRaffleTickets(
        address raffleAddress,
        address to,
        uint256 tickets
    ) external;

    function ownerOfTicket(address raffleAddress, uint256 ticketId) external view returns (address);
}
