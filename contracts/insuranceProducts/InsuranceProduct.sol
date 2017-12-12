pragma solidity ^0.4.15;

import "./../interfaces/IContractManager.sol";
import "./../interfaces/IEventEmitter.sol";
import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./interfaces/IInsuranceProduct.sol";
import "./interfaces/IInvestmentManager.sol";

contract InsuranceProduct is Ownable, IInsuranceProduct { 
  IContractManager contractsManager;
  IInvestmentManager investmentManager;

  bytes32 public EVENT_EMITTER  = "EventEmitter";
  IEventEmitter logger;

  function InsuranceProduct(address _contractsManager, address _investmentManager) public {
      contractsManager = IContractManager(_contractsManager);
      
      logger = IEventEmitter(contractsManager.getContract(EVENT_EMITTER));
      investmentManager = IInvestmentManager(_investmentManager);
      
      logger.info("Dependencies refreshed");
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
    logger.info("Tokens are claimed", bytes32(msg.sender));
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