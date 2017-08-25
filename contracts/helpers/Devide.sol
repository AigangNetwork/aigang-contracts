pragma solidity 0.4.15;

contract Divide {

  function percent(uint numerator, uint denominator, uint precision) public 

  constant returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }
}