var mnemonic = process.env.mnemonic;
var apiKey = process.env.apiKey;

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 0xfffffffff,
      gasPrice: 10000000000
    },
    testnet: {
      host: "localhost",
      port: 8545,
      gas: 4612388,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/" + apiKey);
      },
      network_id: 3,
      gas: 0xfffffffff,
      gasPrice: 10000000000
    }
  },

};
