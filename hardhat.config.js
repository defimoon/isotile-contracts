/*
  Verify on Etherscan
*/

require("dotenv").config();
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  networks: {
    mainnet: {
      url: `${process.env.WEB3_HTTP_PROVIDER}`
    }
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`
  },
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};