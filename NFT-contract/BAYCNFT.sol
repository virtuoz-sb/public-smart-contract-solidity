// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BAYCNFT is Ownable, ERC721 {
    string private _baseTokenURI;
    uint256 s_tokenCounter;

    constructor() ERC721("BoredApeYachtClub", "BAYC") {
        _baseTokenURI = "https://ipfs.io/ipfs/QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
        s_tokenCounter = 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(address to) public {
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(to, newTokenId);
    }

    function batchMint(address to, uint256 cnt) public {
        uint256 newTokenId = s_tokenCounter;
        for (uint256 i = 0; i < cnt; i++) {
            _safeMint(to, newTokenId);
            newTokenId = newTokenId + 1;
        }
        s_tokenCounter = s_tokenCounter + cnt;
    }
}
