pragma solidity ^0.4.13;

contract ContractManager {
	mapping (string => address) contracts;

	function addContract(string name, address contractAddress) {
		require(contracts[name] == 0);

		contracts[name] = contractAddress;
	}

	function removeContract(string name) {
		require(contracts[name] != 0);

		contracts[name] = 0;
	}

	function updateContract(string name, address contractAddress) {
		require(contracts[name] != 0);

		contracts[name] = contractAddress;
	}

	function getContract(string name) returns (address contractAddress) {
		require(contracts[name] != 0);

		return contracts[name];
	}
}