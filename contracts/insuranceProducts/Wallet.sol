pragma solidity ^0.4.13;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../helpers/EntranceControl.sol";

contract Wallet is Ownable {

    function Wallet() public {
    }

    function deposit(uint value) public onlyCanExecute {   
        require(value > 0);                   
        this.transfer(value);
    }

    function withdraw(address _th, uint value) public onlyCanExecute {   
        require(_th != address(0) && value > 0);                   
        _th.send(value);
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
        logger.info("Tokens are claimed", msg.sender);
    }

    /// @notice By default this contract should not accept ethers
    function() payable public {
        require(false);
    }
}