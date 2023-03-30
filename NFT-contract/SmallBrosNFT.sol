// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SmallBrosNFT is Ownable, ERC721 {
    using Strings for uint256;
    string private _baseTokenURI;
    string public uriSuffix = '.json';
    uint256 s_tokenCounter;

    constructor() ERC721("SmallBrosNFT Official", "SBNFT") {
        _baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmTGB7nUqK6i7gMcULaJHbwDjZyqohgZ2TujRwBMusbw3T/";
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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), uriSuffix))
                : "";
    }
}
