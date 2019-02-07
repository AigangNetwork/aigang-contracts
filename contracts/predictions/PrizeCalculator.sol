pragma solidity ^0.4.23;

import "./../utils/SafeMath.sol";
import "./../interfaces/IPrizeCalculator.sol";


contract PrizeCalculator is IPrizeCalculator {
    using SafeMath for uint;
     
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)        
        public
        pure
        returns (uint)
    {
        require (_predictionTotalTokens > 0, "Not valid prediction tokens");
        require (_winOutputTotalTokens > 0, "Not valid output tokens");
        require (_forecastTokens > 0, "Not valid forecast tokens");
        
        uint returnValue = 0;
        
        returnValue = _forecastTokens.mul(_predictionTotalTokens).div(_winOutputTotalTokens);
        
        return returnValue;
    }
}