// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    mapping(uint256 => uint256) private _itemPrices;
    mapping(uint256 => address) private _itemOwners;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _royaltyFee;

    event ItemListed(uint256 indexed itemId, uint256 price, address owner, address creator, uint256 royaltyFee);
    event ItemSold(uint256 indexed itemId, uint256 price, address buyer, address owner, address creator, uint256 royaltyFee);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function listItem(uint256 price, uint256 royaltyFee) external {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        _mint(msg.sender, itemId);
        _itemPrices[itemId] = price;
        _itemOwners[itemId] = msg.sender;
        _creators[itemId] = msg.sender;
        _royaltyFee[itemId] = royaltyFee;
        emit ItemListed(itemId, price, msg.sender, msg.sender, royaltyFee);
    }

    function buyItem(uint256 itemId) external payable {
        require(_exists(itemId), "Item does not exist");
        require(msg.value >= _itemPrices[itemId], "Insufficient funds");

        address owner = ownerOf(itemId);
        address creator = _creators[itemId];
        uint256 royaltyAmount = (msg.value * _royaltyFee[itemId]) / 100; // Calculate royalty amount

        payable(owner).transfer(msg.value - royaltyAmount);
        payable(creator).transfer(royaltyAmount);

        _transfer(owner, msg.sender, itemId);
        _itemsSold.increment();

        emit ItemSold(itemId, _itemPrices[itemId], msg.sender, owner, creator, _royaltyFee[itemId]);
    }

    function getItemPrice(uint256 itemId) external view returns (uint256) {
        require(_exists(itemId), "Item does not exist");
        return _itemPrices[itemId];
    }

    function getItemOwner(uint256 itemId) external view returns (address) {
        require(_exists(itemId), "Item does not exist");
        return _itemOwners[itemId];
    }

    function getTotalItems() external view returns (uint256) {
        return _itemIds.current();
    }

    function getTotalItemsSold() external view returns (uint256) {
        return _itemsSold.current();
    }
}