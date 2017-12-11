pragma solidity ^0.4.17;

import "./../interfaces/IContractManager.sol";
import "./../interfaces/IEventEmitter.sol";
import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./interfaces/IInsuranceProduct.sol";
import "./interfaces/IInvestmentManager.sol";

contract InsuranceProduct is Ownable, IInsuranceProduct { 
  IContractManager contractsManager;
  IInvestmentManager investmentManager;

  string public EVENT_EMITTER  = "EventEmitter";
  IEventEmitter logger;

  function InsuranceProduct(address _contractsManager, address _investmentManager) public {
      contractsManager = IContractManager(_contractsManager);
      logger = IEventEmitter(contractsManager.getContract(EVENT_EMITTER));
      logger.info("Dependencies refreshed");

      investmentManager = IInvestmentManager(_investmentManager);

      //refreshDependencies(_contractsManager);
  }

  // ----------------------------------       Investment logic
  function invest() payable public {
    require(msg.value > 0);

    investmentManager.invest(msg.sender);
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
    logger.info("Tokens are claimed", string(msg.sender.toBytes()));
  }

  /// @notice By default this contract should not accept ethers
  function() payable public {
    require(false);
  }

  /// @notice Refresh dependences from contract Manager
  // function refreshDependencies(address _contractsManager) public onlyOwner {
  //     contractsManager = IContractManager(_contractsManager);
  //     logger = IEventEmitter(contractsManager.getContract(EVENT_EMITTER));
  //     logger.info("Dependencies refreshed");
  // }

}


"0": "string: 0xca35b7d915458ef540ade6068dfe2f44e8fa733c"