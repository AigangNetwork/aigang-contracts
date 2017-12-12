var BatteryProductData = artifacts.require("./insuranceProducts/BatteryProductData.sol");
//var BatteryProductController = artifacts.require("./insuranceProducts/BatteryProductController.sol");


module.exports = function(deployer) {
  	deployer.deploy(BatteryProductData);
 // 	deployer.deploy(BatteryProductController);
};
