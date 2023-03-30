// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CoolMonkesNFT is Ownable, ERC721 {
    string private _baseTokenURI;
    uint256 s_tokenCounter;
    
    constructor() ERC721("Cool Monkes", "CMNKS") {
        _baseTokenURI = 'https://www.coolmonkes.io/api/metadata/genesis/';
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
}