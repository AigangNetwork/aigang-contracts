pragma solidity ^0.4.13;

contract IInsuranceProduct { 

  // ----- Investment logic
  function invest() payable public;
  function isInvestmentPeriodEnded() constant public returns (bool);
  function checkAvailableDividends() constant public returns (uint);
  function transferDividends() public returns (bool);
  function calculateDividends() constant public returns (uint);
  function getFreeBalance() private returns (int);
  function getInvestorProportion() private returns (uint);

  // ----- Insurance logic
  function policyPrice(string deviceBrand, string deviceYear, string wearLevel, string region) constant public returns(uint price);
  function insure(string itemId, string deviceBrand, string deviceYear, string wearLevel, string region) payable public;
  function claim(uint wearLevel) public;
  function getPolicyEndDateTimestamp() constant public returns (uint);
  function getPolicyNextPayment() constant public returns (uint);
  function claimed() constant public returns (bool);
  
}