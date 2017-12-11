pragma solidity ^0.4.17;

import "./Ownable.sol";

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