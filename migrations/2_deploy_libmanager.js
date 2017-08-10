var ContractManager = artifacts.require("./ContractManager.sol");

module.exports = function(deployer) {
  	deployer.deploy(ContractManager);
};
