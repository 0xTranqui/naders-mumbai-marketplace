// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // VARIABLES

    address payable owner;
    // you can use ether here to represent MATIC, which works similarly and also ahs 18 decimals
    uint256 listingPrice = 0.025 ether;

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }

    // idToMarketItem is the name of the mapping that stores ids mapped to marketitem structs
    mapping(uint => MarketItem) private idToMarketItem;

    // EVENTS
    // this event is triggered anytime a new item is listed
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold
    );

    constructor() {
        owner = payable(msg.sender);
    }

    // FUNCTIONS

    // 1. WRITE FUNCTIONS 

    // retrieves listing price for lister
    function getListingPrice() public view returns (uint) {
        return listingPrice;
    }

    // creates listing of market item. price will get passed in on front end
    function createMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    )   public payable nonReentrant {
        // again, techincally the wei here is referring to corresponding decimals of MATIC
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemIds.increment();
        uint itemId = _itemIds.current();

        // updating mapping for market items upon listing
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            // person selling NFT is the msg.sender
            payable(msg.sender),
            // empty 0 address listed since we don't know who the buyer will be yet
            payable(address(0)),
            price,
            false
        );

        // IERC721.transferFrom transfers ownership from current owner of NFT to the marketplace contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    } 
    
    // facilitates buy/sell of NFT. price doesn't need to be passed in because it is set in the listing
    function createMarketSale(
        address nftContract,
        uint itemId
        ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        // transfer price paid for NFT to the seller
        idToMarketItem[itemId].seller.transfer(msg.value);
        // transfer ownership of token from NFT marketplace to the buyer of the NFT. address(this) represents the contract address of the NFT marketplace
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        // transfers value of listingPrice that was originally sent to NFT marketplace contract address to the owner of the NFT marketplace contract
        payable(owner).transfer(listingPrice);
    }

    // 2. READ FUNCTIONS
    
    // retrieve all market items currently unsold aka for sale
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        // local variable to keep track of loop index
        uint currentIndex = 0;

        // creating an array with length of the number of unsold items
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    // retrieve all market items that user has purchased themselves
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        // local variable to keep track of loop index
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    // retrieve all market items that user has created themselves
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        // local variable to keep track of loop index
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

}