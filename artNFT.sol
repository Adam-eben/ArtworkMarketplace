// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./artNFTtoken.sol";

contract ArtMarketplace {
    ArtToken private token;

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }
    uint256 items;

    mapping(uint256 => ItemForSale) itemsForSale;
    mapping(uint256 => bool) public activeItems; // tokenId => bool onSale

    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
    event itemSold(uint256 id, address buyer, uint256 price);

    constructor(ArtToken _token) {
        token = _token;
    }

    modifier OnlyItemOwner(uint256 tokenId) {
        require(
            token.ownerOf(tokenId) == msg.sender,
            "Sender does not own the item"
        );
        _;
    }

    modifier HasTransferApproval(uint256 tokenId) {
        require(
            token.getApproved(tokenId) == address(this),
            "Market is not approved"
        );
        _;
    }

    modifier ItemExists(uint256 id) {
        require(
            id < items && itemsForSale[id].id == id,
            "Could not find item"
        );
        _;
    }

    modifier IsForSale(uint256 id) {
        require(!itemsForSale[id].isSold, "Item is already sold");
        _;
    }

    function putItemForSale(uint256 tokenId, uint256 price)
        external
        OnlyItemOwner(tokenId)
        HasTransferApproval(tokenId)
        returns (uint256)
    {
        require(!activeItems[tokenId], "Token is already up for sale");
        require(price > 0, "Invalid price");
        uint id = items;
        items++;
        itemsForSale[items] = ItemForSale(
            id,
            tokenId,
            payable(msg.sender),
            price,
            false
        );
        activeItems[tokenId] = true;

        require(itemsForSale[items].id == id, "Failed to create item");
        
        emit itemAddedForSale(id, tokenId, price);
        return id;
    }

    function buyItem(uint256 id)
        external
        payable
        ItemExists(id)
        IsForSale(id)
        HasTransferApproval(itemsForSale[id].tokenId)
    {
        require(msg.value == itemsForSale[id].price, "Not enough funds sent");
        require(
            msg.sender != itemsForSale[id].seller,
            "Seller can't buy his own item"
        );

        itemsForSale[id].isSold = true;
        address payable seller = itemsForSale[id].seller;
        itemsForSale[id].seller = payable(msg.sender);
        activeItems[itemsForSale[id].tokenId] = false;
        token.safeTransferFrom(
            itemsForSale[id].seller,
            msg.sender,
            itemsForSale[id].tokenId
        );

        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Payment failed");

        emit itemSold(id, msg.sender, itemsForSale[id].price);
    }

    // removes an item from sale
    function removeItemFromSale(uint256 id)
        external
        OnlyItemOwner(itemsForSale[id].tokenId)
        ItemExists(id)
        IsForSale(id)
    {
        uint256 tokenId = itemsForSale[id].tokenId;
        require(activeItems[tokenId], "Token isn't up for sale");
        activeItems[tokenId] = false;
        token.approve(address(0), tokenId); // approval is removed for marketplace
    }

    // relist an existing item with updated price to be on sale
    function relistItem(uint256 id, uint256 _price)
        public
        ItemExists(id)
        OnlyItemOwner(itemsForSale[id].tokenId)
        HasTransferApproval(itemsForSale[id].tokenId)
    {
        uint256 tokenId = itemsForSale[id].tokenId;
        require(!activeItems[tokenId], "Item is already up for sale");
        require(_price > 0, "Invalid price");
        activeItems[tokenId] = true;
        itemsForSale[id].price = _price;
    }

    function totalItemsForSale() public view returns (uint256) {
        return items;
    }
}
