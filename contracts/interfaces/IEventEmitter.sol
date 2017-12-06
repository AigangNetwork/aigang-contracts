pragma solidity ^0.4.17;

contract IEventEmitter {
    function info(string message) public;
    function info(string message, string param) public;

    function warning(string message) public;
    function warning(string message, string param) public;

    function error(string message) public;
    function error(string message, string param) public;
}