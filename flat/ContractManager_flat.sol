pragma solidity ^0.4.13;

contract Ownable {
  address public owner;
  address public owner2;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender != address(0) && (msg.sender == owner || msg.sender == owner2)); //TODO: test
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
  //TODO: TEST
  function transfer2Ownership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner2 = newOwner;
  }
}

contract IContractManager {
	function getContract(bytes32 name) constant public returns (address);
	function available() public constant returns (bool);
}

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

contract IEventEmitter {
    function info(bytes32 _message) public;
    function info2(bytes32 _message, bytes32 _param) public;

    function warning(bytes32 _message) public;
    function warning2(bytes32 _message, bytes32 _param) public;

    function error(bytes32 _message) public;
    function error2(bytes32 _message, bytes32 _param) public;

    function available(address _tx) public constant returns (bool);
}

