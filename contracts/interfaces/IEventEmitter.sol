pragma solidity ^0.4.15;

contract IEventEmitter {
    function info(bytes32 _message) public;
    function info2(bytes32 _message, bytes32 _param) public;

    function warning(bytes32 _message) public;
    function warning2(bytes32 _message, bytes32 _param) public;

    function error(bytes32 _message) public;
    function error2(bytes32 _message, bytes32 _param) public;

    function available(address _tx) public constant returns (bool);
}