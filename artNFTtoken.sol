// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtToken is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    address public marketplace;
    address contractOwner;

    struct Item {
        uint256 id;
        address creator;
        string uri; //metadata url
    }

    mapping(uint256 => Item) public Items; //id => Item

    constructor() ERC721("ArtToken", "ARTK") {
        contractOwner = msg.sender;
    }

    function mint(string memory uri) public returns (uint256) {
        require(bytes(uri).length > 7, "Invalid uri"); // uri using ipfs starts with ipfs://
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, newItemId);
        approve(marketplace, newItemId);

        Items[newItemId] = Item({id: newItemId, creator: msg.sender, uri: uri});

        return newItemId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return Items[tokenId].uri;
    }

    function setMarketplace(address market) public {
        require(msg.sender == contractOwner, "Unauthorized user");
        require(market != address(0), "Invalid address");
        marketplace = market;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from, 
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
