pragma solidity ^0.4.13;

interface IAddressManager {
	function add(uint typeId, address contractAddress) external;
	function get(uint typeId, uint index) external returns(address, uint, uint8);
	function changeStatus(uint typeId, uint index, uint8 status) external;
	function getLength(uint _typeId) external view returns(uint);
}

contract Owned {
    address public owner;
    address public executor;
    address public superOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        superOwner = msg.sender;
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlySuperOwner {
        require(msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyOwnerOrSuperOwner {
        require(msg.sender == owner || msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor || msg.sender == superOwner, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function transferSuperOwnership(address _newOwner) public onlySuperOwner {
        emit OwnershipTransferred(superOwner, _newOwner);
        superOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }
}

contract AddressManager is Owned, IAddressManager {
	
	struct Address {
		address contractAddress;
        uint created;
		uint8 status;
    }

	event Added(uint _typeId, address _contractAddress);
	event ChangedStatus(uint _typeId, uint _index, uint8 _status);
	  
	mapping (uint => Address[]) public contracts;

	function add(uint _typeId, address _contractAddress) public onlyAllowed {
		contracts[_typeId].push(Address(_contractAddress, now, 0));

        emit Added(_typeId, _contractAddress);
	}

	function get(uint _typeId, uint _index) public view returns(address, uint, uint8){
        return (contracts[_typeId][_index].contractAddress,
				contracts[_typeId][_index].created,
				contracts[_typeId][_index].status);
    }

	function getLength(uint _typeId) public view returns(uint) {
		return contracts[_typeId].length;
	}

	function changeStatus(uint _typeId, uint _index, uint8 _status) public onlyAllowed{
        contracts[_typeId][_index].status = _status;

		emit ChangedStatus(_typeId, _index, _status);
    }
}

