pragma solidity ^0.4.15;

contract IWallet {
    function() payable public;
    function withdraw(address _th, uint value) public;

    function available(address _tx) public constant returns (bool);
}