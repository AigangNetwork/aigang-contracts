pragma solidity ^0.4.15;

contract IWallet {
    function deposit(uint value) public;
    function withdraw(address _th, uint value) public;
}