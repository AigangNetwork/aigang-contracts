pragma solidity ^0.4.23;

interface IAddressManager {
	function add(uint typeId, address contractAddress) external;
	function get(uint typeId, uint index) external returns(address, uint, uint8);
	function changeStatus(uint typeId, uint index, uint8 status) external;
	function getLength(uint _typeId) external view returns(uint);
}