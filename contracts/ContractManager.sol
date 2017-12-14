pragma solidity ^0.4.15;

import "./helpers/Ownable.sol";
import "./interfaces/IEventEmitter.sol";
import "./interfaces/IContractManager.sol";

contract ContractManager is Ownable, IContractManager {
	mapping (bytes32 => address) contracts;
	IEventEmitter logger;

	function ContractManager(address eventEmitter) public {
		logger = IEventEmitter(eventEmitter);
	}

	function setContract(bytes32 name, address contractAddress) public onlyOwner {
		contracts[name] = contractAddress;
		logger.info2("[CM] Contract address is set", name);
	}

	function removeContract(bytes32 name) public onlyOwner {
		require(contracts[name] != 0);

		contracts[name] = address(0);
		logger.info2("[CM] Contract address is removed", name);
	}

	function getContract(bytes32 name) constant public returns (address) {
		require(contracts[name] != address(0));

		return contracts[name];
	}

	function changeEventEmitter(address eventEmitter) public onlyOwner {
		logger = IEventEmitter(eventEmitter);	
		logger.info2("[CM] Event emitter is changed", bytes32(eventEmitter));
	}

	function available() public constant returns (bool) {
       return true;
    }
}