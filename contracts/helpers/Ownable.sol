pragma solidity ^0.4.15;

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