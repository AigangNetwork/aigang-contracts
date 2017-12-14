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
    function info(bytes32 _message) public;
    function info2(bytes32 _message, bytes32 _param) public;

    function warning(bytes32 _message) public;
    function warning2(bytes32 _message, bytes32 _param) public;

    function error(bytes32 _message) public;
    function error2(bytes32 _message, bytes32 _param) public;

    function available(address _tx) public constant returns (bool);
}

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

    function info2(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Info(msg.sender, _message, _param);
    }
    
    function warning(bytes32 _message) public onlyCanExecute {
        Warning(msg.sender, _message, "");
    }

    function warning2(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Warning(msg.sender, _message, _param);
    }

    function error(bytes32 _message) public onlyCanExecute {
        Error(msg.sender, _message, "");
    }

    function error2(bytes32 _message, bytes32 _param) public onlyCanExecute {
        Error(msg.sender, _message, _param);
    }

    function available(address _tx) public constant returns (bool) {
       return canExecute[_tx];
    }
}

