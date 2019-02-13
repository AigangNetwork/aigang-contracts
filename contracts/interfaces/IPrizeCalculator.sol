pragma solidity ^0.4.23;

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _totalTokens, uint _winnersPoolTotalTokens, uint _yourTokens)
        pure
        external
        returns (uint);
}