pragma solidity ^0.4.13;

contract Ownable {
  address public owner;
  address public owner2;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender != address(0) && (msg.sender == owner || msg.sender == owner2)); //TODO: test
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
  //TODO: TEST
  function transfer2Ownership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner2 = newOwner;
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
    function info(bytes32 message) public;
    function info(bytes32 message, bytes32 param) public;

    function warning(bytes32 message) public;
    function warning(bytes32 message, bytes32 param) public;

    function error(bytes32 message) public;
    function error(bytes32 message, bytes32 param) public;
}

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

