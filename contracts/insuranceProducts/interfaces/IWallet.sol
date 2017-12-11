pragma solidity ^0.4.13;

contract IWallet {
    function deposit(uint value) public;
    function withdraw(address _th, uint value) public;
}