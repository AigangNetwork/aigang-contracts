pragma solidity ^0.4.13;

contract ContractManager {
	mapping (name => address) contracts;
	string[] productNames;

	function addContract(string name, address contractAddress) {
		require(contracts[name] == 0);

		contracts[name] = contractAddress;
	}

	function removeContract(string name) {
		require(contracts[name] != 0);

		contracts[name] = 0;
	}

	function updateContract(string name, address contractAddress) {
		
	}

	function getContract(string name) {

	}

	function addProduct(string name) {

	}

	function removeProduct(string name) {

	}

}