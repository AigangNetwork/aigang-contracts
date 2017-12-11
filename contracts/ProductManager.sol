pragma solidity ^0.4.17;

import "./helpers/Ownable.sol";

contract ProductManager is Ownable {

	struct Product {
		string name;
		address location;
		string description;
		int8 status;  // -1 deleted, 0 not exist, 1 created, 2 ready for investment... 
	}

	bytes32[] public products;
	mapping(bytes32 => Product) public productDetails;  

	function add(bytes32 _id, string _name, address _address, string _description) public onlyOwner {	
        require(!isProduct(_id));
        
		products.push(_id);

        productDetails[_id] = Product(_name, _address, _description, 1);		
	}
	
	function update(bytes32 _id, string _name, address _address, string _description) public onlyOwner {	
        require(isProduct(_id));
        
        productDetails[_id].name = _name;	
        productDetails[_id].location = _address;
        productDetails[_id].description = _description;
	}

	function changeStatus(bytes32 _id, int8 _status) public onlyOwner {	   
	    require(isProduct(_id));
		productDetails[_id].status = _status;      
	}
	
	function isProduct(bytes32 _id) public view returns(bool) {   
		if (productDetails[_id].status != 0) {
			return true;
		}
	    
	    return false;
	}
	
	function remove(bytes32 _id) public onlyOwner {   
		return changeStatus(_id, -1);
	}
}