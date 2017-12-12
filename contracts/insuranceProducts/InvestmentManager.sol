pragma solidity ^0.4.15;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../helpers/EntranceControl.sol";
import "./../helpers/Strings.sol";
import "./../interfaces/IEventEmitter.sol";
import "./../interfaces/IContractManager.sol";
import "./interfaces/IInvestmentManager.sol";
import "./interfaces/IWallet.sol";

contract InvestmentManager is Ownable, IInvestmentManager {
    using Strings for address;
    IWallet wallet;
    IEventEmitter logger;
    IContractManager contractsManager;

    function InvestmentManager(address _contractsManager, address _wallet) public {
        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract("EventEmitter"));
        logger.info("Dependencies refreshed");
        wallet = IWallet(_wallet);
    }

    function invest(address _th) payable public {
        require(msg.value > 0);

        wallet.deposit(msg.value);    
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
}