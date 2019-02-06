pragma solidity ^0.4.23;

 import "./utils/OwnedWithExecutor.sol";
 import "./interfaces/IAddressManager.sol";

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