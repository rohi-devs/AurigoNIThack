require("@nomicfoundation/hardhat-toolbox")

module.exports = {
  solidity: "0.8.28",
  networks: {
    ganache: {
      url : "http://127.0.0.1:7545",
      accounts: [
        "0xec6b1e23e3f58185a3ced64cd00818f1ed6b6174a7a36255a592b9c19814417a",
        "0x3787c7b6874b7ac8991a98de32e39840dffe7ef1c52d5a95c846b97189a95365"
      ]

    }
  }
}



