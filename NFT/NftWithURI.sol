
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract MyNFT is ERC721URIStorage {
    uint256 public nextTokenId;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(string memory _uri) external {
        _safeMint(msg.sender, nextTokenId);
        _setTokenURI(nextTokenId, _uri);
        nextTokenId++;
    }
}

 