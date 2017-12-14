pragma solidity ^0.4.15;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../interfaces/IEventEmitter.sol";
import "./../interfaces/IContractManager.sol";
import "./interfaces/IInvestmentManager.sol";
import "./interfaces/IWallet.sol";

contract InvestmentManager is Ownable, IInvestmentManager {
    IWallet public wallet;
    IEventEmitter public logger;
    IContractManager public contractsManager;
    address public insuranceProduct;

    mapping (address => uint) public investors;
    uint public totalInvestorsCount;
    uint public totalInvestedAmount;

    uint public maxPayout;
    uint public investmentsLimit;
    uint32 public investmentsDeadlineTimeStamp;    

    uint8 constant DECIMAL_PRECISION = 8;
    uint24 constant ALLOWED_RETURN_INTERVAL_SEC = 24 * 60 * 60; // each 24 hours

    modifier onlyInsuranceProduct() {
        require(msg.sender == insuranceProduct);
        _;
    }

    function InvestmentManager(address _contractsManager, address _wallet, address _insuranceProduct) public {
        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract("EventEmitter"));
        wallet = IWallet(_wallet);
        insuranceProduct = _insuranceProduct;

        maxPayout = 10 finney;   // 0.01 ETH
        investmentsLimit = 1000 ether; //1000 ETH
        investmentsDeadlineTimeStamp = uint32(now) + 90 days;
    }

    function invest(address _th) payable public onlyInsuranceProduct returns (bool) {
        require(msg.value > 0);
        require(!isInvestmentPeriodEnded());

        investors[_th] = investors[_th] + msg.value;
        totalInvestorsCount++;
        totalInvestedAmount = totalInvestedAmount + msg.value;

        wallet.deposit(msg.value);  
        logger.info("[InvM]Invested", bytes32(_th));
        return true;  
    }

    function isInvestmentPeriodEnded() constant public returns (bool) {
        return (investmentsDeadlineTimeStamp < now);
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
        logger.info2("Tokens are claimed", bytes32(msg.sender));
    }

    /// @notice By default this contract should not accept ethers
    function() payable public {
        require(false);
    }
}