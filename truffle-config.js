module.exports = {
  compilers: {
    solc: {
      version: "0.8.0"
    }
  },
  networks: {
    ganache: { // Ganache local test RPC blockchain
      network_id: "5777",
      host: "localhost",
      port: 7545,
      gas: 6721975
    }
  }
};