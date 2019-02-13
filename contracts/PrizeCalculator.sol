pragma solidity ^0.4.23;

import "./utils/SafeMath.sol";
import "./interfaces/IPrizeCalculator.sol";


contract PrizeCalculator is IPrizeCalculator {
    using SafeMath for uint;
     
    function calculatePrizeAmount(uint _totalTokens, uint _winnersPoolTotalTokens, uint _yourTokens)        
        public
        pure
        returns (uint)
    {
        require (_totalTokens > 0, "Not valid total tokens");
        require (_winnersPoolTotalTokens > 0, "Not valid winnersPool total tokens");
        require (_yourTokens > 0, "Not valid your tokens");
        
        uint returnValue = 0;
        
        returnValue = _yourTokens.mul(_totalTokens).div(_winnersPoolTotalTokens);
        
        return returnValue;
    }
}