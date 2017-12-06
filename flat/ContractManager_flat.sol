pragma solidity ^0.4.13;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

contract IContractManager {
	function getContract(string name) constant public returns (address contractAddress);
}

contract ContractManager is Ownable, IContractManager {
	mapping (string => address) contracts;
	IEventEmitter logger;

	function ContractManager(address eventEmitter) public {
		logger = IEventEmitter(eventEmitter);
	}

	function setContract(string name, address contractAddress) public onlyOwner {
		contracts[name] = contractAddress;
		logger.info("[ContractManager] Contract address is set", name);
	}

	function removeContract(string name) public onlyOwner {
		require(contracts[name] != 0);

		contracts[name] = 0;
		logger.info("[ContractManager] Contract address is removed", name);
	}

	function getContract(string name) constant public returns (address contractAddress) {
		require(contracts[name] != 0);

		return contracts[name];
	}

	function changeEventEmitter(address eventEmitter) public onlyOwner {
		logger = IEventEmitter(eventEmitter);
		logger.info("[ContractManager] event emiter is changed");
	}
}

contract IEventEmitter {

    function info(string message) public;
    function info(string message, string param) public;

    function warning(string message) public;
    function warning(string message, string param) public;

    function error(string message) public;
    function error(string message, string param) public;
}

