pragma solidity ^0.4.15;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../helpers/EntranceControl.sol";
import "./../interfaces/IContractManager.sol";
import "./../interfaces/IEventEmitter.sol";
import "./interfaces/IWallet.sol";

contract Wallet is Ownable, EntranceControl, IWallet {
    bytes32 public EVENT_EMITTER  = "EventEmitter";

    IContractManager contractsManager;
    IEventEmitter logger;

    function Wallet(address _contractsManager) public {
        refreshDependencies(_contractsManager);
    }

    function() payable public { 
        require(msg.value > 0);                   
        logger.info2("[W] deposit", bytes32(msg.value));
    }

    function withdraw(address _th, uint value) public onlyCanExecute {   
        require(_th != address(0) && value > 0);  

        logger.info2("[W] withdraw req", bytes32(_th));                 
        _th.transfer(value);
        logger.info2("[W] withdrawed", bytes32(value));
    }


    /////////
    // Safety Methods
    //////////

    
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {   // set to 0 in case you want to extract ether.   
            msg.sender.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);

        token.transfer(msg.sender, balance);
        logger.info2("Tokens are claimed", bytes32(msg.sender));
    }

    function refreshDependencies(address _contractsManager) public onlyOwner {
        require(_contractsManager != address(0));

        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract(EVENT_EMITTER));
    }

    function selfCheck() constant public onlyOwner returns (bool) {
        require(contractsManager.available());
        require(contractsManager.getContract(EVENT_EMITTER) != address(0));

        require(logger.available(this));
        return(true);
    }

    function available(address _tx) public constant returns (bool) {
       return canExecute[_tx];
    }

    // Method is used for Remix IDE easier debuging
    function getBalance() public constant returns (uint) {
        return this.balance; 
    }
}