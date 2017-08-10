pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/insuranceProducts/BatteryProductData.sol";

contract TestBatteryInsurancePolicy {

  function testMaxPayoutShouldBeSet() {
    BatteryProductData batteryProductData = BatteryProductData(DeployedAddresses.BatteryProductData());

    uint expected = 10000000000000000;

    Assert.equal(batteryProductData.maxPayout(), expected, "MaxPayout should be set to 0.01 ETH initially");
  }
}
