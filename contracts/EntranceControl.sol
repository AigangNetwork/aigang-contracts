pragma solidity ^0.4.17;

import "./helpers/Ownable.sol";

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