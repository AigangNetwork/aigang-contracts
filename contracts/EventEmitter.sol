pragma solidity ^0.4.15;

import "./helpers/EntranceControl.sol";
import "./interfaces/IEventEmitter.sol";

contract EventEmitter is EntranceControl, IEventEmitter {
    event Info(address indexed _sender, bytes32 _msg, bytes32 _param);
    event Warning(address indexed _sender, bytes32 _msg, bytes32 _param);
    event Error(address indexed _sender, bytes32 _msg, bytes32 _param);

    function EventEmitter() public {
        Info(this, "Initialized", "");
    }

    function info(bytes32 _message) public onlyCanExecute { 
        Info(msg.sender, _message, "");
    }

    function info(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Info(msg.sender, _message, _param);
    }

    function warning(bytes32 _message) public onlyCanExecute {
        Warning(msg.sender, _message, "");
    }

    function warning(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Warning(msg.sender, _message, _param);
    }

    function error(bytes32 _message) public onlyCanExecute {
        Error(msg.sender, _message, "");
    }

    function error(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Error(msg.sender, _message, _param);
    }
}