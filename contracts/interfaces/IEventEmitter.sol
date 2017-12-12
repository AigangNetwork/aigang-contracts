pragma solidity ^0.4.17;

contract IEventEmitter {
    function info(bytes32 message) public;
    function info(bytes32 message, bytes32 param) public;

    function warning(bytes32 message) public;
    function warning(bytes32 message, bytes32 param) public;

    function error(bytes32 message) public;
    function error(bytes32 message, bytes32 param) public;
}