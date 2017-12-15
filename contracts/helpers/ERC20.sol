pragma solidity ^0.4.15;

contract ERC20 {
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
  function totalSupply() public constant returns (uint);
}
