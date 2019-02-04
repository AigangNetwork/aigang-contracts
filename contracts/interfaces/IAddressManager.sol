pragma solidity ^0.4.24;

contract IAddressManager {
	function getContract(bytes32 name) constant public returns (address);
	function available() public constant returns (bool);
}