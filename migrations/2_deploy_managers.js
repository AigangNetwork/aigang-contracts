var ContractManager = artifacts.require("./ContractManager.sol");
var ProductManager = artifacts.require("./ProductManager.sol");

module.exports = function(deployer) {
  	deployer.deploy(ContractManager);
  	deployer.deploy(ProductManager);
};
