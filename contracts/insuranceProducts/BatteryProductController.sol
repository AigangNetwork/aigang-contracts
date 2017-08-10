pragma solidity ^0.4.13;

import "./BatteryProductData.sol";

contract BatteryProductController { 

  // Controller is used for updating value
  address controllerAddress = 0x2033d81c062dE642976300c6eabCbA149e4372BE;
  // Insurance Data contract. Should be taken from LibManager
  address productDataAddress = 0x0;
  BatteryProductData batteryProductData = BatteryProductData(productDataAddress);

  event Insured(string deviceName, uint insurancePrice);
  event Claimed(uint payout); 
  event Invested(uint amount);

  // ----- Investment logic
  function invest() payable {
    require(msg.value > 0);

    batteryProductData.addInvestment.value(msg.value)(msg.sender);

    Invested(msg.value);
  }


  // ----- Insurance logic
  function policyPrice(string deviceBrand, string deviceYear, string wearLevel, string region) constant returns(uint price) {
    // set defaults
    uint deviceBrandMultiplier = batteryProductData.getInsuranceParameter('deviceBrand', 'default');
    uint deviceYearMultiplier = batteryProductData.getInsuranceParameter('deviceYear', 'default');
    uint batteryWearLevelMultiplier = batteryProductData.getInsuranceParameter('wearLevel', 'default');
    uint regionMultiplier = batteryProductData.getInsuranceParameter('region', 'default');

    if(batteryProductData.getInsuranceParameter('deviceBrand', deviceBrand) != 0) {
      deviceBrandMultiplier = batteryProductData.getInsuranceParameter('deviceBrand', deviceBrand);
    }
    if(batteryProductData.getInsuranceParameter('deviceYear', deviceYear) != 0) {
      deviceYearMultiplier = batteryProductData.getInsuranceParameter('deviceYear', deviceYear);
    }
    if(batteryProductData.getInsuranceParameter('wearLevel', wearLevel) != 0) {
      batteryWearLevelMultiplier = batteryProductData.getInsuranceParameter('wearLevel', wearLevel);
    }
    if(batteryProductData.getInsuranceParameter('region', region) != 0) {
      deviceBrandMultiplier = batteryProductData.getInsuranceParameter('region', region);
    }

    // / 100 is due to Solidity not supporting doubles
    uint riskPremium = batteryProductData.basePremium() * deviceBrandMultiplier / 100 * deviceYearMultiplier / 100 
                        * batteryWearLevelMultiplier / 100 * regionMultiplier / 100;

    uint officePremium = riskPremium / (100 - batteryProductData.loading()) * 100; 
    return officePremium;
  }


  function insure(string itemId, string deviceBrand, string deviceYear, string wearLevel, string region) payable {
    uint totalPrice = policyPrice(deviceBrand, deviceYear, wearLevel, region);
    uint monthlyPayment = totalPrice / 12;

    require(msg.value < monthlyPayment);

    batteryProductData.addPolicy.value(msg.value)(msg.sender, now + 1 years, now + 30 days, monthlyPayment, batteryProductData.maxPayout(), totalPrice, itemId, false, false);

    Insured(deviceBrand, msg.value);
  }

  function confirmPolicy(address policyHolder) {
    require(controllerAddress == msg.sender);

    batteryProductData.confirmPolicy(policyHolder);
  }

  function claim(uint wearLevel) {
    var (endDateTimestamp, claimed, confirmed, maxPayout) = batteryProductData.getPolicyData(msg.sender);

    require(wearLevel < 70);
    require(endDateTimestamp != 0);
    require(!claimed); 
    require(endDateTimestamp > now);
    require(confirmed);

    batteryProductData.claim(msg.sender, maxPayout);

    Claimed(maxPayout);

  }

  function getPolicyEndDateTimestamp() constant returns (uint) {
    var (endDateTimestamp,,,) = batteryProductData.getPolicyData(msg.sender);
    return endDateTimestamp;
  }

  function claimed() constant returns (bool) {
    var (, claimed,,) = batteryProductData.getPolicyData(msg.sender);
    return claimed;
  }
}