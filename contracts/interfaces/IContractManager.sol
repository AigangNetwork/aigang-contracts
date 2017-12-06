pragma solidity ^0.4.13;

contract IContractManager {
	function getContract(string name) constant public returns (address contractAddress);
}