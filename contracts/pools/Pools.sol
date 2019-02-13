pragma solidity ^0.4.23;

import "./../utils/OwnedWithExecutor.sol";
import "./../utils/SafeMath.sol";
import "./../interfaces/IERC20.sol";
import "./../interfaces/IPrizeCalculator.sol";

contract Pools is Owned {
    using SafeMath for uint;  

    event Initialize(address _token);
    event PoolAdded(uint _id);
    event ContributionAdded(address _from, uint _poolId, uint _contributionId);
    event PoolStatusChange(uint _poolId, PoolStatus _oldStatus, PoolStatus _newStatus);
    event Paidout(uint _contributionId);
    event Withdraw(uint _amount);

    event PoolAddressesUpdated(uint _id, address _destination, address _prizeCalculator);
    event PoolDescriptionsUpdated(uint _id, string _title, string _description);
    event PoolDataUpdated(uint _id, uint _contributionEndUtc, uint _amountLimit);
    
    struct Pool {  
        uint contributionStartUtc;
        uint contributionEndUtc;
        address destination;
        PoolStatus status;
        uint amountLimit;
        uint amountCollected;
        uint amountDistributing;
        uint paidout;
        address prizeCalculator;
        uint[] contributions;
        string title;
        string description;
    }

    struct Contribution { 
        uint id; 
        uint poolId;
        uint amount;
        uint paidout;
        address owner;
        uint created;
    }
    
    enum PoolStatus {
        NotSet,       // 0
        Active,       // 1
        Distributing, // 2
        Funding,       // 3 
        Paused,       // 4
        Canceled      // 5 
    }  

    uint8 public constant version = 1;
    bool public paused = true;
    address public token;
    uint public totalPools;
    uint public POOL_ID;
    uint public CONTRIBUTION_ID;
    
    mapping(uint => Pool) public pools;
    mapping(uint => Contribution) public contributions;
    mapping(address => uint[]) public myContributions;

    modifier contractNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token), "Sender should be Token");
        _;
    }

    modifier poolExist(uint _poolId) {
        require(pools[_poolId].status != PoolStatus.NotSet, "Entity should be initialized");
        _;
    }

    function initialize(address _token) external onlyOwnerOrSuperOwner {
        token = _token;
        paused = false;
        emit Initialize(_token);
    }

    function addPool(
            address _destination, 
            uint _contributionStartUtc, 
            uint _contributionEndUtc, 
            uint _amountLimit, 
            address _prizeCalculator,
            string _title,
            string _description) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        returns (uint) {
        
        uint id = getPoolId();
        require(pools[id].status == PoolStatus.NotSet, "Entity already initialized");

        totalPools++;
        pools[id].contributionStartUtc = _contributionStartUtc;
        pools[id].contributionEndUtc = _contributionEndUtc;
        pools[id].destination = _destination;
        pools[id].status = PoolStatus.Active;
        pools[id].amountLimit = _amountLimit;
        pools[id].prizeCalculator = _prizeCalculator;
        
        pools[id].title = _title;
        pools[id].description = _description;
        
        emit PoolAdded(id);
        return id;
    }

    function setPoolStatus(uint _poolId, PoolStatus _status) 
            public 
            onlyOwnerOrSuperOwner
            poolExist(_poolId) {
       
        emit PoolStatusChange(_poolId,pools[_poolId].status, _status);
        pools[_poolId].status = _status;
    }
    
    // This method will be called for returning money when canceled or set everyone to take rewards by formula
    function setPoolAmountDistributing(uint _poolId, PoolStatus _poolStatus, uint _amountDistributing) external onlyOwnerOrSuperOwner {
        setPoolStatus(_poolId, _poolStatus);
        pools[_poolId].amountDistributing = _amountDistributing;
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    // _data = poolId
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            contractNotPaused {    
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
      
        uint poolId = bytesToUint(_data);
        
        // Validate pool and Contribution
        require(pools[poolId].status == PoolStatus.Active, "Status should be active");
        require(pools[poolId].contributionStartUtc < now, "Contribution is not started");    
        require(pools[poolId].contributionEndUtc > now, "Contribution is ended"); 
        require(pools[poolId].amountLimit == 0 ||
                pools[poolId].amountLimit >= pools[poolId].amountCollected.add(_amountOfTokens), "Contribution limit reached"); 
        
        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");

        pools[poolId].amountCollected = pools[poolId].amountCollected.add(_amountOfTokens);
        
        uint contributionId = getContributionId();
        pools[poolId].contributions.push(contributionId);

        contributions[contributionId] = Contribution(contributionId, poolId, _amountOfTokens, 0, _from, now);
        myContributions[_from].push(contributionId);

        emit ContributionAdded(_from, poolId, contributionId);
    }
    
    function transferToDestination(uint _poolId) external onlyOwnerOrSuperOwner {
        assert(IERC20(token).transfer(pools[_poolId].destination, pools[_poolId].amountCollected));
        setPoolStatus(_poolId,PoolStatus.Funding);
    }
    
    function payout(uint _contributionId) public contractNotPaused {
        Contribution storage con = contributions[_contributionId];
        uint poolId = con.poolId;

        require(pools[poolId].status == PoolStatus.Distributing, "Pool should be Distributing");
        require(pools[poolId].amountDistributing > pools[poolId].paidout, "Pool should be not empty");
        require(con.amount > 0, "Contribution not valid");
        require(con.paidout == 0, "Contribution already paidout");
        require(con.owner != address(0), "Owner not valid"); 

        IPrizeCalculator calculator = IPrizeCalculator(pools[poolId].prizeCalculator);
    
        uint winAmount = calculator.calculatePrizeAmount(
            pools[poolId].amountDistributing,
            pools[poolId].amountCollected,  
            con.amount
        );
      
        assert(winAmount > 0);
        con.paidout = winAmount;
        pools[poolId].paidout = pools[poolId].paidout.add(winAmount);
        assert(IERC20(token).transfer(con.owner, winAmount));
        emit Paidout(_contributionId);
    }

    function refund(uint _contributionId) public contractNotPaused {
        Contribution storage con = contributions[_contributionId];
        uint poolId = con.poolId;

        require(pools[poolId].status == PoolStatus.Canceled, "Pool should be canceled");
        require(pools[poolId].amountDistributing > pools[poolId].paidout, "Pool should be not empty");
        require(con.paidout == 0, "Contribution already paidout");        
        require(con.amount > 0, "Contribution not valid");   
        require(con.owner != address(0), "Owner not valid"); 

        con.paidout = con.amount;
        pools[poolId].paidout = pools[poolId].paidout.add(con.amount);
        assert(IERC20(token).transfer(con.owner, con.amount));

        emit Paidout(_contributionId);
    }

    //////////
    // Updates
    //////////
    function updateAddresses(uint _poolId, 
            address _destination,
            address _prizeCalculator) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused
        poolExist(_poolId) {
        
        pools[_poolId].destination = _destination;
        pools[_poolId].prizeCalculator = _prizeCalculator;

        emit PoolAddressesUpdated(_poolId, _destination, _prizeCalculator);
    }

    function updateDescriptions(uint _poolId, 
            string _title,
            string _description) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        poolExist(_poolId) {
        
        pools[_poolId].title = _title;
        pools[_poolId].description = _description;

        emit PoolDescriptionsUpdated(_poolId, _title, _description);
    }

    function updateData(uint _poolId, 
            uint _contributionEndUtc,
            uint _amountLimit) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        poolExist(_poolId) {

        pools[_poolId].contributionEndUtc = _contributionEndUtc;
        pools[_poolId].amountLimit = _amountLimit;

        emit PoolDataUpdated(_poolId, _contributionEndUtc, _amountLimit);
    }

    //////////
    // Views
    //////////
    function getContribution(uint _contributionId) public view returns(uint, uint, uint, uint, address, uint) {
        return (contributions[_contributionId].id,
            contributions[_contributionId].poolId,
            contributions[_contributionId].amount,
            contributions[_contributionId].paidout,
            contributions[_contributionId].owner,
            contributions[_contributionId].created);
    }

    function getPoolContributionsLength(uint _poolId) public view returns(uint) {
        return pools[_poolId].contributions.length;
    }

    function getPoolContribution(uint _poolId, uint index) public view returns (uint) {
        return pools[_poolId].contributions[index];
    }

    function getMyContributionsLength() public view returns(uint) {
        return myContributions[msg.sender].length;
    }

    // ////////
    // Utils
    // ////////

    function bytesToUint(bytes b) public pure returns(uint) {
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        
        return number;
    }

    function getPoolId() private returns (uint) {
        return POOL_ID = POOL_ID.add(1);
    }

     function getContributionId() private returns (uint) {
        return CONTRIBUTION_ID = CONTRIBUTION_ID.add(1);
    }
 

    // ////////
    // Safety Methods
    // ////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        assert(IERC20(_token).transfer(owner, _amount));
        emit Withdraw(_amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }
}