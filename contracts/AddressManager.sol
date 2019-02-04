pragma solidity ^0.4.23;

// import "./utils/OwnedWithExecutor.sol";
// import "./interfaces/IAddressManager.sol";

// contract AddressManager is Ownable, IAddressManager {
// 	mapping (bytes32 => address) contracts;


// 	function AddressManager(address eventEmitter) public {

// 	}

// 	function setContract(bytes32 name, address contractAddress) public onlyOwner {
// 		contracts[name] = contractAddress;
// 	}

// 	function removeContract(bytes32 name) public onlyOwner {
// 		require(contracts[name] != 0);

// 		contracts[name] = address(0);
// 	}

// 	function getContract(bytes32 name) constant public returns (address) {
// 		require(contracts[name] != address(0));

// 		return contracts[name];
// 	}



// 	function available() public constant returns (bool) {
//        return true;
//     }
// }