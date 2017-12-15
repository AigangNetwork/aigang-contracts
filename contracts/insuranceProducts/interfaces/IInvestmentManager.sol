pragma solidity ^0.4.15;

contract IInvestmentManager { 

  // ----- Investment logic
  function invest(address _th, uint _value) payable public returns (bool);
  // function isInvestmentPeriodEnded() constant public returns (bool);
  // function checkAvailableDividends() constant public returns (uint);
  // function transferDividends() public returns (bool);
  // function calculateDividends() constant public returns (uint);
  // function getFreeBalance() private returns (int);
  // function getInvestorProportion() private returns (uint);

   function available(address _tx) public constant returns (bool);
}