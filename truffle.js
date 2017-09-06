const LightWalletProvider = require('@digix/truffle-lightwallet-provider');
const pass = 'azerty';
// kovan 0xe2e8d89c9435a92eedfade8c94e14118a3156f09

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    kovan: {
      provider: new LightWalletProvider({
        keystore: './sigmate-v3-deploysc.json',
        password: pass,
        rpcUrl: 'https://kovan.infura.io/v604Wu8pXGoPC41ARh0B',
        // debug: true, // optional, show JSON-RPC logs
      }),
      network_id: 42,
    },
    // ropsten: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: 3,
    //   from: "0xe070b23860FA281252aC4ABB8d3E120f088d1Fb1",
    // },
    kovanManual: {
      host: "localhost",
      port: 8545,
      network_id: 42,
      from: "0x00816fD686EAa5C1B80463b7cb6cB8D76A505268",
    },
    mainnet: {
      host: 'localhost',
      port: 8545,
      network_id: 1,
    },
  }
};