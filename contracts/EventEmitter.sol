pragma solidity ^0.4.17;

import "./helpers/EntranceControl.sol";
import "./interfaces/IEventEmitter.sol";

contract EventEmitter is EntranceControl, IEventEmitter {
    event Info(address indexed sender, bytes32 msg, bytes32 param);
    event Warning(address indexed sender, bytes32 msg, bytes32 param);
    event Error(address indexed sender, bytes32 msg, bytes32 param);

    function EventEmitter() public {
        Info(this, "Initialized", "");
    }

    function info(bytes32 message) public onlyCanExecute { 
        Info(msg.sender, message, "");
    }

    function info(bytes32 message, bytes32 param) public onlyCanExecute {
        Info(msg.sender, message, param);
    }

    function warning(bytes32 message) public onlyCanExecute {
        Warning(msg.sender, message, "");
    }

    function warning(bytes32 message, bytes32 param) public onlyCanExecute {
        Warning(msg.sender, message, param);
    }

    function error(bytes32 message) public onlyCanExecute {
        Error(msg.sender, message, "");
    }

    function error(bytes32 message, bytes32 param) public onlyCanExecute {
        Error(msg.sender, message, param);
    }
}