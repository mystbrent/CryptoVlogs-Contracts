const CryptoVlogs = artifacts.require("ERC1155Mintable");

module.exports = function(deployer) {
  deployer.deploy(CryptoVlogs);
};
