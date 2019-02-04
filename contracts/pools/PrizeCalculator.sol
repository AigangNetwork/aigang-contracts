pragma solidity ^0.4.23;

import "./../utils/SafeMath.sol";
import "./../interfaces/IPrizeCalculator.sol";


contract PrizeCalculator is IPrizeCalculator {
    using SafeMath for uint;
     
    function calculatePrizeAmount(uint _distributeTotalTokens, uint _collectedTotalTokens, uint _contributionTokens)        
        public
        pure
        returns (uint)
    {
        require (_distributeTotalTokens > 0, "Not valid 1 param");
        require (_collectedTotalTokens > 0, "Not valid 2 param");
        require (_contributionTokens > 0, "Not valid  3 param");
        
        uint returnValue = 0;
        
        returnValue = _contributionTokens.mul(_distributeTotalTokens).div(_collectedTotalTokens);
        
        return returnValue;
    }
}