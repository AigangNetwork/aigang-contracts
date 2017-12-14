//var BatteryProductData = artifacts.require("./insuranceProducts/BatteryProductData.sol");
//var BatteryProductController = artifacts.require("./insuranceProducts/BatteryProductController.sol");
var EventEmmiter = artifacts.require("./EventEmitter.sol");

module.exports = function(deployer) {
  	deployer.deploy(EventEmmiter);
 // 	deployer.deploy(BatteryProductController);
};
