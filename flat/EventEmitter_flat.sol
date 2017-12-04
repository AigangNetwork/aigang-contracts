pragma solidity ^0.4.13;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract EntranceControl is Ownable {
    uint public executorsCount = 0;
    mapping (address => bool) public canExecute;
   
    event AddedExecutor(address _address);
    event RemovedExecutor(address _address);

    function EntranceControl() public {
        canExecute[msg.sender] = true;
        executorsCount++;
        AddedExecutor(msg.sender);
    }
    
    function addExecutor(address _executor) public onlyOwner{
        canExecute[_executor] = true;
        executorsCount++;
        AddedExecutor(_executor);
    }
    
    function removeExecutor(address _executor) public onlyOwner{
        canExecute[_executor] = false;
        executorsCount--;
        RemovedExecutor(_executor);
    }
    
    modifier onlyCanExecute() {
        require(canExecute[msg.sender]);
        _;
    }
}

contract EventEmitter is EntranceControl{
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

