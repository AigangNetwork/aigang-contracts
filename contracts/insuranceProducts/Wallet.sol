pragma solidity ^0.4.13;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../helpers/EntranceControl.sol";
import "./../interfaces/IContractManager.sol";
import "./../interfaces/IEventEmitter.sol";

contract Wallet is Ownable, EntranceControl {
    IContractManager contractsManager;
    IEventEmitter logger;

    function Wallet(address _contractsManager) public {
        refreshDependencies(_contractsManager);
    }

    function deposit(uint value) public onlyCanExecute {   
        require(value > 0);                   
        this.transfer(value);
        logger.info("[W] deposit", bytes32(value));
    }

    function withdraw(address _th, uint value) public onlyCanExecute {   
        require(_th != address(0) && value > 0);  
        logger.info("[W] withdraw req", bytes32(_th));                 
        _th.transfer(value);
        logger.info("[W] withdrawed", bytes32(value));
    }


    /////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {      
            msg.sender.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);

        token.transfer(msg.sender, balance);
        logger.info("Tokens are claimed", bytes32(msg.sender));
    }

    /// @notice By default this contract should not accept ethers
    function() payable public {
        require(false);
    }

    function refreshDependencies(address _contractsManager) public onlyOwner {
        require(_contractsManager != address(0));

        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract("EventEmitter"));
    }
}