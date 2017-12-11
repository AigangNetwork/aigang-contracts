pragma solidity ^0.4.17;

import "./helpers/EntranceControl.sol";
import "./interfaces/IEventEmitter.sol";

contract EventEmitter is EntranceControl, IEventEmitter {
    event Info(address indexed sender, string msg, string param);
    event Warning(address indexed sender, string msg, string param);
    event Error(address indexed sender, string msg, string param);

    function EventEmitter() public {
        Info(this, "Initialized", "");
    }

    function info(string message) public onlyCanExecute { 
        Info(msg.sender, message, "");
    }

    function info(string message, string param) public onlyCanExecute {
        Info(msg.sender, message, param);
    }

    function warning(string message) public onlyCanExecute {
        Warning(msg.sender, message, "");
    }

    function warning(string message, string param) public onlyCanExecute {
        Warning(msg.sender, message, param);
    }

    function error(string message) public onlyCanExecute {
        Error(msg.sender, message, "");
    }

    function error(string message, string param) public onlyCanExecute {
        Error(msg.sender, message, param);
    }
}