pragma solidity ^0.4.13;

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _totalTokens, uint _winnersPoolTotalTokens, uint _yourTokens)
        pure
        external
        returns (uint);
}

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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

