pragma solidity ^0.4.15;

contract IContractManager {
	function getContract(bytes32 name) constant public returns (address contractAddress);
}