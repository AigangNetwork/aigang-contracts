pragma solidity ^0.4.13;

// import "./PolicyInvestable.sol";

contract BatteryProductData {//is PolicyInvestable { 

  // Investment data
  mapping (address => uint) public investors;
  uint public totalInvestorsCount;
  uint public totalInvestedAmount;
  uint public totalInsurers;
  uint public totalClaimsPaid;
  uint public maxInvestmentCap;

  // Insurance data
  mapping (address => PolicyData) insurancePolicies;
  mapping (string => mapping(string => uint) ) insuranceParameters;
  uint public basePremium;
  uint public maxPayout;
  uint public loading;

  // Controller is used for updating value
  address controller = 0x2033d81c062dE642976300c6eabCbA149e4372BE;
  // Insurance Controller contract, that has a right modify data; Should be taken from LibManager
  address insuranceController = 0x0;
  // Asset Controller contract, that has a right modify data; Should be taken from LibManager
  address assetController = 0x0;

  struct PolicyData {
    uint endDateTimestamp;
    uint nextPaymentTimestamp;
    uint monthlyPayment;
    uint maxPayout;
    uint totalPrice;
    string itemId;
    bool claimed;
    bool confirmed;
  }

  function addInvestment(address investor) payable {
    require(maxInvestmentCap > (totalInvestedAmount + msg.value));

    investors[investor] = investors[investor] + msg.value;
    totalInvestorsCount++;
    totalInvestedAmount = totalInvestedAmount + msg.value;
  }

  // Function is long because solidity does not support passing structs
  function addPolicy(address policyHolder, uint endDateTimestamp, uint nextPaymentTimestamp,
                     uint monthlyPayment, uint maxPayout, uint totalPrice, string itemId, 
                     bool claimed, bool confirmed) payable {

    require(msg.value < monthlyPayment);

    insurancePolicies[policyHolder] = PolicyData(endDateTimestamp, nextPaymentTimestamp, monthlyPayment, 
                                                 maxPayout, totalPrice, itemId, claimed, confirmed);

    totalInsurers = totalInsurers + 1;
  }

  function getPolicyData(address policyHolder) returns (uint, bool, bool, uint) {
    var policy = insurancePolicies[policyHolder];

    return (policy.endDateTimestamp, policy.claimed, policy.confirmed, policy.maxPayout);
  }

  function confirmPolicy(address policyHolder) {
    insurancePolicies[policyHolder].confirmed = true;
  }

  function claim(address policyHolder, uint payout) {
    require(this.balance > payout);

    var policy = insurancePolicies[policyHolder];
    policy.claimed = true;
    policy.endDateTimestamp = now;
    policy.nextPaymentTimestamp = 0;

    totalClaimsPaid = totalClaimsPaid + payout;

    policyHolder.transfer(payout);
  }

  function BatteryProductData() payable {
    setInitialInsuranceParameters();
  }

  function setInitialInsuranceParameters() internal {
    // Device brand
    insuranceParameters['deviceBrand']['apple'] = 100;
    insuranceParameters['deviceBrand']['samsung'] = 110;
    insuranceParameters['deviceBrand']['default'] = 120;

    // Device year
    insuranceParameters['deviceYear']['2014'] = 120;
    insuranceParameters['deviceYear']['2015'] = 110;
    insuranceParameters['deviceYear']['2016'] = 100;
    insuranceParameters['deviceYear']['2017'] = 100;
    insuranceParameters['deviceYear']['default'] = 140;

    // Battery wear level upper than
    insuranceParameters['wearLevel']['50'] = 150;
    insuranceParameters['wearLevel']['60'] = 140;
    insuranceParameters['wearLevel']['70'] = 120;
    insuranceParameters['wearLevel']['80'] = 110;
    insuranceParameters['wearLevel']['90'] = 100;

    // Region
    insuranceParameters['region']['usa'] = 100;
    insuranceParameters['region']['europe'] = 100;
    insuranceParameters['region']['africa'] = 120;
    insuranceParameters['region']['default'] = 130;

    // Base premium (0.001 ETH)
    basePremium = 1000000000000000;

    // Max payout (0.01 ETH)
    maxPayout = 10000000000000000;

    // Loading percentage (expenses, etc)
    loading = 50;
  }

  function getInsuranceParameter(string parameter, string key) returns (uint value) {
    return insuranceParameters[parameter][key];
  }

}