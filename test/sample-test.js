const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("Should create and execute market sales", async function () {

    // deploy NFT marketplace contract 
    const Market = await ethers.getContractFactory("NFTMarket")
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress = market.address


    // deploy NFT contract
    const NFT = await ethers.getContractFactory("NFT")
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address

    // set listing price
    let listingPrice = await market.getListingPrice()
    listingPrice = listingPrice.toString()

    // utilts.parseUnits lets us work with full ether rather than wei, and yes this is still actually MATIC
    const auctionPrice = ethers.utils.parseUnits('100', 'ether')

    // creating two NFTs
    await nft.createToken("https://www.mytokenlocation.com")
    await nft.createToken("https://www.mytokenlocation2.com")


    // putting two NFTs up for sale
    // "{ value: listingPrice }" is how you pass ethereum value into the contract txn aka msg.value
    await market.createMarketItem(nftContractAddress, 1, auctionPrice, { value: listingPrice })
    await market.createMarketItem(nftContractAddress, 2, auctionPrice, { value: listingPrice })

    // allows you to create test accounts for testing using ethers. seller represented by the "_," who we are trying to skip
    const [_, buyerAddress] = await ethers.getSigners()

    // selling the first NFT to someone else
    await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, {value: auctionPrice})

    // test query functions
    let items = await market.fetchMarketItems()

    // updating the return value of item so that our test spits out human readable values
    items = await Promise.all(items.map(async i => {
      const tokenUri = await nft.tokenURI(i.tokenId)
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item
    }))

    console.log('items: ', items)

  });
});
