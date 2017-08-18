pragma solidity ^0.4.13;

import "./helpers/Ownable.sol";

// Ownable sets the contract creator as Owner. Ownership can be transferred.
contract ProductManager is Ownable {
	
	bytes32[] allProducts;

	function addProduct(bytes32 name) onlyOwner {
		uint productIndex = IndexOf(allProducts, name);
    
        if(allProducts.length > 0) {
		    require(productIndex < allProducts.length);
        }

		allProducts.push(name);
	}

	function removeProduct(bytes32 name) onlyOwner {
		allProducts = RemoveByValue(allProducts, name);
	}

	// ----------------
	// Array Util function pasted inside, because you cannot pass string[] to external libarary 
	// should be excluded to separate contract as soon as solidity supports needed functionality.

	/** Finds the index of a given value in an array. */
	function IndexOf(bytes32[] values, bytes32 value) internal returns(uint) {
		uint i = 0;
		if(values.length > 0) {
		    while (values[i] == value && i < values.length) {
     		  i++;
     		}
		}
		
		return i;

	}

	/** Removes the given value in an array. */
	function RemoveByValue(bytes32[] values, bytes32 value) internal returns (bytes32[] valuesNew) {
		uint i = IndexOf(values, value);

		require(i < values.length);

		return RemoveByIndex(values, i);
	}

	/** Removes the value at the given index in an array. */
	function RemoveByIndex(bytes32[] values, uint index) internal returns (bytes32[] valuesNew) {
		bytes32[] memory arrayNew = new bytes32[](values.length-1);
		uint i = 0;

		while (i<values.length-1) {
			if(i == index) {
				continue;
			}
		  	arrayNew[i] = values[i+1];
		  	i++;
		}
		return arrayNew;

	}
}