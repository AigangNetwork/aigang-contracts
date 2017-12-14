pragma solidity ^0.4.15;

contract IWallet {
    function deposit(uint value) public payable;
    function withdraw(address _th, uint value) public;

    function available(address _tx) public constant returns (bool);
}