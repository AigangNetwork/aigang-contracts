pragma solidity ^0.4.13;

contract IPolicyInvestable {
  function invest() payable public returns (bool success);
}