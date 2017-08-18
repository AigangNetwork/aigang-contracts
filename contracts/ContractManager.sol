pragma solidity ^0.4.13;

import "./helpers/Ownable.sol";

// Ownable sets the contract creator as Owner. Ownership can be transferred.
contract ContractManager is Ownable {
	mapping (string => address) contracts;

	function addContract(string name, address contractAddress) onlyOwner {
		require(contracts[name] == 0);

		contracts[name] = contractAddress;
	}

	function removeContract(string name) onlyOwner {
		require(contracts[name] != 0);

		contracts[name] = 0;
	}

	function updateContract(string name, address contractAddress) onlyOwner {
		require(contracts[name] != 0);

		contracts[name] = contractAddress;
	}

	function getContract(string name) constant returns (address contractAddress) {
		require(contracts[name] != 0);

		return contracts[name];
	}
}