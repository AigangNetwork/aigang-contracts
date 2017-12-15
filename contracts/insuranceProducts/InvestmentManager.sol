pragma solidity ^0.4.15;

import "./../helpers/Ownable.sol";
import "./../helpers/ERC20.sol";
import "./../interfaces/IEventEmitter.sol";
import "./../interfaces/IContractManager.sol";
import "./interfaces/IInvestmentManager.sol";
import "./interfaces/IWallet.sol";

contract InvestmentManager is Ownable, IInvestmentManager {
    bytes32 public EVENT_EMITTER  = "EventEmitter";
    uint8 constant DECIMAL_PRECISION = 8;
    uint24 constant ALLOWED_RETURN_INTERVAL_SEC = 24 * 60 * 60; // each 24 hours

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


    modifier onlyInsuranceProduct() {
        require(msg.sender == insuranceProduct);
        _;
    }

    function InvestmentManager(address _contractsManager, address _wallet, address _insuranceProduct) public {
        refreshDependencies(_contractsManager, _wallet, _insuranceProduct);

        maxPayout = 10 finney;   // 0.01 ETH
        investmentsLimit = 1000 ether; //1000 ETH
        investmentsDeadlineTimeStamp = uint32(now) + 90 days;
    }

    function invest(address _th, uint _value) payable public onlyInsuranceProduct returns (bool) {
        require(_value > 0);
        require(!isInvestmentPeriodEnded());

        investors[_th] = investors[_th] + _value;
        totalInvestorsCount++;
        totalInvestedAmount = totalInvestedAmount + _value;

        wallet.transfer(_value);  
        logger.info2("[InvM]Invested", bytes32(_th));
        return true;  
    }

    function isInvestmentPeriodEnded() constant public returns (bool) {
        return (investmentsDeadlineTimeStamp < now);
    }


    /////////
    // Safety Methods
    //////////

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {    // set to 0 in case you want to extract ether.   
            msg.sender.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);

        token.transfer(msg.sender, balance);
        logger.info2("Tokens are claimed", bytes32(msg.sender));
    }

    /// By default this contract should not accept ethers
    function() payable public {
        require(false);
    }

    function refreshDependencies(address _contractsManager, address _wallet, address _insuranceProduct) public onlyOwner {
        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract(EVENT_EMITTER));
        wallet = IWallet(_wallet);
        insuranceProduct = _insuranceProduct;
    }

    function available(address _tx) public constant returns (bool) {
       return _tx == insuranceProduct;
    }

    function selfCheck() constant public onlyOwner returns (bool) {
        require(contractsManager.available());
        require(contractsManager.getContract(EVENT_EMITTER) != address(0));

        require(logger.available(this));
        require(wallet.available(this));

        return(true);
    }

    // Method is used for Remix IDE easier debuging
    function getBalance() public constant returns (uint) {
        return this.balance; 
    }
}