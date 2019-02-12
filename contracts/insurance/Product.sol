pragma solidity ^0.4.23;

import "./../utils/OwnedWithExecutor.sol";
import "./../utils/SafeMath.sol";
import "./../utils/BytesHelper.sol";
import "./../interfaces/IERC20.sol";

interface IProduct {
    function addPolicy(bytes32 _id, uint _utcStart, uint _utcEnd, uint _calculatedPayout, string _properties) external;
    function claim(bytes32 _policyId, string _properties) external;
}

contract Product is Owned, IProduct {
    using SafeMath for uint;
    using BytesHelper for bytes;

    event PolicyAdd(bytes32 indexed _policyId);
    event Claim(bytes32 indexed _policyId, uint _amount);    
    event Cancel(bytes32 indexed _policyId, uint _amount);    
    event PremiumCalculatorChange(address _old, address _new);
    event PaymentReceived(bytes32 indexed _policyId, uint _amount);
    event PolicyUpdatedManualy(bytes32 indexed _policyId);
    event WithdrawToPool(uint _amount);
    event Withdraw(uint _amount);

    struct Policy {
        address owner;
        uint utcStart;
        uint utcEnd;
        uint utcPayoutDate;
        uint premium;
        uint calculatedPayout;
        string properties;
        // claim
        uint payout;
        string claimProperties;
        bool isCanceled;
    }
    
    address public token;
    address public premiumCalculator;
    address public pool;
    uint public utcProductStartDate;
    uint public utcProductEndDate;

    bool public paused = true;
    
    uint public policiesCount;
    uint public policiesTotalCalculatedPayouts;
    uint public policiesPayoutsCount;
    uint public policiesTotalPayouts;
        
    mapping(bytes32 => Policy) public policies;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier policyValidForPayout(bytes32 _policyId) {
        require(policies[_policyId].owner != address(0), "Owner is not valid");       
        require(policies[_policyId].payout == 0, "Payout already done");
        require(policies[_policyId].isCanceled == false, "Policy already canceled");
        require(policies[_policyId].calculatedPayout != 0, "Policy is not set");
        require(policies[_policyId].utcEnd > now, "Policy has ended");
        _;
    }
   
    function initialize(
        address _premiumCalculator, 
        address _token, 
        uint _utcProductStartDate, 
        uint _utcProductEndDate,
        address _pool) 
            external 
            onlyOwnerOrSuperOwner {

        premiumCalculator = _premiumCalculator;
        token = _token;
        utcProductStartDate = _utcProductStartDate; 
        utcProductEndDate = _utcProductEndDate;
        pool = _pool;
        paused = false;
    }

    function addPolicy(bytes32 _id, uint _utcStart, uint _utcEnd, uint _calculatedPayout, string _properties) 
            external 
            onlyAllowed 
            notPaused {
        require(policies[_id].premium > 0, "Policy is not payed");
        require(policies[_id].utcStart == 0, "Policy is already set");
        require(policies[_id].isCanceled == false, "Policy is already canceled");

        policies[_id].utcStart = _utcStart;
        policies[_id].utcEnd = _utcEnd;
        policies[_id].calculatedPayout = _calculatedPayout;
        policies[_id].properties = _properties;

        policiesCount++;
        policiesTotalCalculatedPayouts = policiesTotalCalculatedPayouts.add(_calculatedPayout);

        emit PolicyAdd(_id);
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            notPaused {
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");

        bytes32 policyId = _data.bytesToBytes32();

        require(policies[policyId].premium == 0, "policy is paid and laready exist");

        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");
   
        policies[policyId].premium = _amountOfTokens;
        policies[policyId].owner = _from;

        emit PaymentReceived(policyId, _amountOfTokens);
    }
          
    function claim(bytes32 _policyId, string _properties) external 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) { 
      
        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayout, "Contract balance is to low");

        policies[_policyId].utcPayoutDate = uint(now);
        policies[_policyId].payout = policies[_policyId].calculatedPayout;
        policies[_policyId].claimProperties = _properties;

        policiesPayoutsCount++;
        policiesTotalPayouts = policiesTotalPayouts.add(policies[_policyId].payout);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payout));

        emit Claim(_policyId, policies[_policyId].payout);
    }

    function cancel(bytes32 _policyId) public 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) {
                
        policies[_policyId].isCanceled = true;
       
        emit Cancel(_policyId, policies[_policyId].payout);
    }

    function updatePremiumCalculator(address _newCalculator) public onlyOwnerOrSuperOwner {
        emit PremiumCalculatorChange(premiumCalculator, _newCalculator);
        premiumCalculator = _newCalculator;
    }      

    function transferToPool() public onlyOwnerOrSuperOwner {
        require(pool != address(0), 'Pool should be set');
        uint balance = tokenBalance();
        paused = true;
        assert(IERC20(token).transfer(pool, balance));
        emit WithdrawToPool(balance);
    }

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function updatePolicy(
        bytes32 _policyId,
        address _owner,
        uint _utcStart,
        uint _utcEnd,
        uint _premium,
        uint _calculatedPayout,
        bool _isCanceled) 
            external 
            onlyOwnerOrSuperOwner {
        
        policies[_policyId].owner = _owner;
        policies[_policyId].utcStart = _utcStart;
        policies[_policyId].utcEnd = _utcEnd;
        policies[_policyId].premium = _premium;
        policies[_policyId].calculatedPayout = _calculatedPayout;
        policies[_policyId].isCanceled = _isCanceled;

        emit PolicyUpdatedManualy(_policyId);
    }

    function updatePolicy2(
        bytes32 _policyId,
        string _properties,
        uint _payout,
        uint _utcPayoutDate,
        string _claimProperties) 
            external 
            onlyOwnerOrSuperOwner {
        
        policies[_policyId].properties = _properties;
        policies[_policyId].payout = _payout;
        policies[_policyId].utcPayoutDate = _utcPayoutDate;
        policies[_policyId].claimProperties = _claimProperties;
  
        emit PolicyUpdatedManualy(_policyId);
    }

    function tokenBalance() public view returns (uint) {
        return IERC20(token).balanceOf(this);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        IERC20(_token).transfer(owner, _amount);
        emit Withdraw(_amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }
}