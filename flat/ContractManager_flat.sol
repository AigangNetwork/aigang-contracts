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

library Strings {
    // function toAsciiString(address x) constant public returns (string) {
    //     bytes memory s = new bytes(40);
    //     for (uint i = 0; i < 20; i++) {
    //         byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    //         byte hi = byte(uint8(b) / 16);
    //         byte lo = byte(uint8(b) - 16 * uint8(hi));
    //         s[2*i] = char(hi);
    //         s[2*i+1] = char(lo);            
    //     }
    //     return string(s);
    // }

    // function toBytes(address x)  public returns (bytes b) {
    //     b = new bytes(20);
    //     for (uint i = 0; i < 20; i++) {
    //         b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    //     }
    // }

    // function char(byte b)  public constant returns (byte c) {
    //     if (b < 10) 
    //     return byte(uint8(b) + 0x30);
    //     else 
    //     return byte(uint8(b) + 0x57);
    // }
}

contract IContractManager {
	function getContract(bytes32 name) constant public returns (address contractAddress);
}

contract ContractManager is Ownable, IContractManager {
	mapping (bytes32 => address) contracts;
	IEventEmitter logger;

	function ContractManager(address eventEmitter) public {
		logger = IEventEmitter(eventEmitter);
	}

	function setContract(bytes32 name, address contractAddress) public onlyOwner {
		contracts[name] = contractAddress;
		logger.info("[CM] Contract address is set", name);
	}

	function removeContract(bytes32 name) public onlyOwner {
		require(contracts[name] != 0);

		contracts[name] = address(0);
		logger.info("[CM] Contract address is removed", name);
	}

	function getContract(bytes32 name) constant public returns (address contractAddress) {
		require(contracts[name] != address(0));

		return contracts[name];
	}

	function changeEventEmitter(address eventEmitter) public onlyOwner {
		logger = IEventEmitter(eventEmitter);	
		logger.info("[CM] Event emitter is changed", bytes32(eventEmitter));
	}
}

contract IEventEmitter {
    function info(bytes32 _message) public;
    function info(bytes32 _message, bytes32 _param) public;

    function warning(bytes32 _message) public;
    function warning(bytes32 _message, bytes32 _param) public;

    function error(bytes32 _message) public;
    function error(bytes32 _message, bytes32 _param) public;
}

