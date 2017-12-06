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
    
    function addExecutor(address executor) public onlyOwner {
        require(!canExecute[executor]);

        canExecute[executor] = true;
        executorsCount++;
        AddedExecutor(executor);
    }
    
    function removeExecutor(address executor) public onlyOwner {
        require(canExecute[executor]);

        canExecute[executor] = false;
        executorsCount--;
        RemovedExecutor(executor);
    }
    
    modifier onlyCanExecute() {
        require(canExecute[msg.sender]);
        _;
    }
}

contract IEventEmitter {

    function info(string message) public;
    function info(string message, string param) public;

    function warning(string message) public;
    function warning(string message, string param) public;

    function error(string message) public;
    function error(string message, string param) public;
}

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

