pragma solidity ^0.4.17;

import "./EntranceControl.sol";

contract EventEmitter is EntranceControl {
  event Info(address indexed sender, string msg);
  event Warning(address indexed sender, string msg);
  event Error(address indexed sender, string msg);

  function EventEmitter() public {
    Info(this, "Initialized");
  }

  function info(string _msg) public onlyCanExecute{
   Info(msg.sender, _msg);
  }
  
  function warning(string _msg) public onlyCanExecute{
   Warning(msg.sender, _msg);
  }
  
  function error(string _msg) public onlyCanExecute{
   Error(msg.sender, _msg);
  }
}