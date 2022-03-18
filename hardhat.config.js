
require("@nomiclabs/hardhat-waffle");

const fs = require("fs");
const privateKey = fs.readFileSync(".secret").toString().trim();
const mumbai_url = "insert url endpoint here";
const mainnet_url = "insert url endpoint here";


module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337
    },
    mumbai: {
      url: mumbai_url,
      accounts: [privateKey]
    },
    //mainnet: {
      //url: mainnet_url,
      //accounts: [privateKey]
    //}
  },
  solidity: "0.8.4",
};
