// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error Goobig__NotCreator();

contract Raffle is ERC721 {
    /* immutable variables */
    address public immutable i_nftAddress;
    uint256 public immutable i_tokenId;
    address public immutable i_creator;

    uint256 s_tokenCounter;

    modifier onlyCreator() {
        if (msg.sender != i_creator) {
            revert Goobig__NotCreator();
        }
        _;
    }
    constructor (address nftAddress, uint256 tokenId) ERC721("Goobig Ticket", "GOOTICKET") 
    {
        i_nftAddress = nftAddress;
        i_tokenId = tokenId;
        i_creator = msg.sender;
    }

    function mint(address to) external onlyCreator {
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(to, newTokenId);
    }

    function batchMint(address to, uint256 amount) external onlyCreator {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, s_tokenCounter);
            s_tokenCounter = s_tokenCounter + 1;
            
        }
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return super.ownerOf(tokenId);
    }
}