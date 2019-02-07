pragma solidity ^0.4.23;

interface IResultStorage {
    function getResult(bytes32 _predictionId) external returns (uint8);
}