pragma solidity ^0.4.13;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function approve(address _spender, uint256 _amount) external returns (bool success);
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool success);
  function totalSupply() external constant returns (uint);
}

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _totalTokens, uint _winnersPoolTotalTokens, uint _yourTokens)
        pure
        external
        returns (uint);
}

interface IResultStorage {
    function getResult(uint _predictionId) external returns (uint8);
}

contract Owned {
    address public owner;
    address public executor;
    address public superOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        superOwner = msg.sender;
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlySuperOwner {
        require(msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyOwnerOrSuperOwner {
        require(msg.sender == owner || msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor || msg.sender == superOwner, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function transferSuperOwnership(address _newOwner) public onlySuperOwner {
        emit OwnershipTransferred(superOwner, _newOwner);
        superOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }
}

contract Market is Owned {
    using SafeMath for uint;  

    event Initialize(address _token); 
    event PredictionAdded(uint id);
    event ForecastAdded(address _from, uint _predictionId, uint _forecastId); 
    event PredictionStatusChanged(uint predictionId, PredictionStatus oldStatus, PredictionStatus newStatus);
    event Refunded(uint predictionId, uint _forecastId);
    event PredictionResolved(uint predictionId, uint8 winningOutcomeId);
    event PaidOut(uint _predictionId, uint _forecastId);
    event Withdraw(uint _amount);
    event PredictionDescriptionsUpdated(uint _predictionId, string _title, string _description);
    event PredictionOutcomeAdded(uint _predictionId,uint8 _outcomeIndex);
    event PredictionOutcomeUpdated(uint _predictionId,uint8 _outcomeIndex);
    event PredictionAddressesUpdated(uint _predictionId, address _resultStorage, address _prizeCalculator);
    event PredictionDataUpdated(uint _predictionId,uint _forecastEndUtc,uint _forecastStartUtc,uint _fee,uint8 _outcomeCount,uint _initialTokens,uint _totalTokens);

    enum PredictionStatus {
        NotSet,    // 0
        Published, // 1
        Resolved,  // 2
        Paused,    // 3
        Canceled   // 4
    }  
    
    struct Prediction {
        uint forecastEndUtc;
        uint forecastStartUtc;
        uint fee; // in WEIS       
        PredictionStatus status;    
        uint8 outcomesCount;
        uint8 resultOutcome;
        uint[] forecasts;
        //mapping(uint8 => uint) outcomeTokens;
        uint initialTokens;  
        uint totalTokens;          
        uint totalForecasts;   
        uint totalTokensPaidout;     
        address resultStorage;   
        address prizeCalculator;
        mapping(uint8 => Outcome) outcomes;
    }

    struct Details {  
        string title;
        string description;
    }

    struct Outcome {  
        uint8 id;
        string title;  
        string value;
        uint totalTokens;
    }

    struct Forecast {  
        uint id; 
        uint predictionId;  
        address owner;
        uint amount;
        uint8 outcomeId;
        uint paidOut;
        uint created;
    }

    uint8 public constant version = 1;
    address public token;
    bool public paused = true;
    uint public totalPredictions;
    uint public PREDICTION_ID;
    uint public FORECAST_ID;

    mapping(uint => Details) public predictionDetails;
    mapping(uint => Prediction) public predictions;
    mapping(uint => Forecast) public forecasts;
    mapping(address => uint[]) public myForecasts;

    uint public totalFeeCollected;

    modifier contractNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier statusIsCanceled(uint _predictionId) {
        require(predictions[_predictionId].status == PredictionStatus.Canceled, "Prediction is not canceled");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token), "Sender is not token");
        _;
    }

    modifier predictionExist(uint _predictionId) {
        require(predictions[_predictionId].status != PredictionStatus.NotSet, "Entity should be initialized");
        _;
    }
    
    function initialize(address _token) external onlyOwnerOrSuperOwner {
        token = _token;
        paused = false;
        emit Initialize(_token);
    }
 
    function addPrediction(
            uint _forecastEndUtc,
            uint _forecastStartUtc,
            uint _fee, 
            uint8 _outcomesCount,
            uint _initialTokens,   
            address _resultStorage, 
            address _prizeCalculator) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        returns (uint) {
        
        uint id = getPredictionId();
        require(predictions[id].status == PredictionStatus.NotSet, "Entity already initialized");
        
        totalPredictions++;
        predictions[id].forecastEndUtc = _forecastEndUtc;
        predictions[id].forecastStartUtc = _forecastStartUtc;
        predictions[id].fee = _fee;
        predictions[id].status = PredictionStatus.Paused;  
        predictions[id].outcomesCount = _outcomesCount;
        predictions[id].initialTokens = _initialTokens;
        predictions[id].totalTokens = _initialTokens;
        predictions[id].resultStorage = _resultStorage;
        predictions[id].prizeCalculator = _prizeCalculator;

        emit PredictionAdded(id);
        return id;
    }

    function updateOutcome(uint _predictionId, 
            uint8 _outcomeIndex,
            string _title,
            string _value) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        predictionExist(_predictionId) {
        
        require(_outcomeIndex > 0, "index starts from 1");

        predictions[_predictionId].outcomes[_outcomeIndex].title = _title;
        predictions[_predictionId].outcomes[_outcomeIndex].value = _value;
        
        if(predictions[_predictionId].outcomes[_outcomeIndex].id == 0) {
            // add
            predictions[_predictionId].outcomes[_outcomeIndex].id = _outcomeIndex;
            emit PredictionOutcomeAdded(_predictionId, _outcomeIndex);
        } else {
            // update
            emit PredictionOutcomeUpdated(_predictionId, _outcomeIndex);
        }
    }

    function changePredictionStatus(uint _predictionId, PredictionStatus _status) 
            external 
            onlyAllowed {
        require(predictions[_predictionId].status != PredictionStatus.NotSet, "Prediction not exist");
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, _status);
        predictions[_predictionId].status = _status;            
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    // _data = outcomeId(1), predictionId
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            contractNotPaused {    

        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        
        uint8 outcomeId = uint8(_data[0]);
        uint predictionId = bytesToUint(_data,1);

        // Validate prediction and forecast
        require(predictions[predictionId].status == PredictionStatus.Published, "Prediction is not published");
        require(predictions[predictionId].forecastEndUtc > now, "Forecasts are over");
        require(predictions[predictionId].forecastStartUtc < now, "Forecasting has not started yet");
        require(predictions[predictionId].outcomesCount >= outcomeId && outcomeId > 0, "Outcome id is not in range");
        require(predictions[predictionId].fee < _amountOfTokens, "Amount should be bigger then fee");
        //require(predictions[predictionId].forecasts[forecastIdString].amount == 0);

        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");

        uint amount = _amountOfTokens.sub(predictions[predictionId].fee);
        totalFeeCollected = totalFeeCollected.add(predictions[predictionId].fee);

        uint forecastId = getForecastId();
        predictions[predictionId].forecasts.push(forecastId); 

        predictions[predictionId].totalTokens = predictions[predictionId].totalTokens.add(amount);
        predictions[predictionId].totalForecasts = predictions[predictionId].totalForecasts.add(1);

        predictions[predictionId].outcomes[outcomeId].totalTokens = predictions[predictionId].outcomes[outcomeId].totalTokens.add(amount);
    
        forecasts[forecastId] = Forecast(forecastId, predictionId, _from, amount, outcomeId, 0, now);
        myForecasts[_from].push(forecastId);

        emit ForecastAdded(_from, predictionId, forecastId);
    }

    function resolve(uint _predictionId) external onlyAllowed {
        require(predictions[_predictionId].status == PredictionStatus.Published, "Prediction must be Published"); 

        if (predictions[_predictionId].forecastEndUtc < now) // allow to close prediction earliar
        {
            predictions[_predictionId].forecastEndUtc = now;
        }

        uint8 winningOutcomeId = IResultStorage(predictions[_predictionId].resultStorage).getResult(_predictionId); // SWC ID: 107 if will be public posible reentrancy attacks
        require(winningOutcomeId <= predictions[_predictionId].outcomesCount && winningOutcomeId > 0, "OutcomeId is not valid");

        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, PredictionStatus.Resolved);
        predictions[_predictionId].resultOutcome = winningOutcomeId;
        predictions[_predictionId].status = PredictionStatus.Resolved; 
        emit PredictionResolved(_predictionId, winningOutcomeId);
    }

    function payout(uint _predictionId, uint _forecastId) public contractNotPaused {
        require(predictions[_predictionId].status == PredictionStatus.Resolved, "Prediction should be resolved");
        require(predictions[_predictionId].resultOutcome != 0, "Outcome should be set");

        Forecast storage forecast = forecasts[_forecastId];
        assert(predictions[_predictionId].resultOutcome == forecast.outcomeId);
        assert(forecast.paidOut == 0);
        
        IPrizeCalculator calculator = IPrizeCalculator(predictions[_predictionId].prizeCalculator);
    
        uint winAmount = calculator.calculatePrizeAmount(
            predictions[_predictionId].totalTokens,
            predictions[_predictionId].outcomes[predictions[_predictionId].resultOutcome].totalTokens,
            forecast.amount
        );

        assert(winAmount > 0);
        forecast.paidOut = winAmount;
        predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(winAmount);
        
        assert(IERC20(token).transfer(forecast.owner, winAmount));
        emit PaidOut(_predictionId, _forecastId);
    }

    // Owner can refund any users forecasts
    function refundUser(uint _forecastId) external onlyOwnerOrSuperOwner {
        uint predictionId = forecasts[_forecastId].predictionId;
        require (predictions[predictionId].status != PredictionStatus.Resolved);
        
        performRefund(_forecastId);
    }
   
    // User can refund when status is CANCELED
    function refund(uint _forecastId, uint _predictionId) external contractNotPaused statusIsCanceled(_predictionId) {
        performRefund(_forecastId);
    }

    function performRefund(uint _forecastId) private {
        require(forecasts[_forecastId].paidOut == 0, "Already paid");  

        uint predictionId = forecasts[_forecastId].predictionId;

        uint refundAmount = forecasts[_forecastId].amount;
        predictions[predictionId].totalTokensPaidout = predictions[predictionId].totalTokensPaidout.add(refundAmount);        
        forecasts[_forecastId].paidOut = refundAmount;
                                                    
        assert(IERC20(token).transfer(forecasts[_forecastId].owner, refundAmount)); 
        emit Refunded(predictionId, _forecastId);
    }

     //////////
    // Updates
    //////////
    function updateAddresses(uint _predictionId, 
            address _resultStorage,
            address _prizeCalculator) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused
        predictionExist(_predictionId) {
        
        predictions[_predictionId].resultStorage = _resultStorage;
        predictions[_predictionId].prizeCalculator = _prizeCalculator;

        emit PredictionAddressesUpdated(_predictionId, _resultStorage, _prizeCalculator);
    }

    function updateDescriptions(uint _predictionId, 
            string _title,
            string _description) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused
        predictionExist(_predictionId) {
        
        predictionDetails[_predictionId].title = _title;
        predictionDetails[_predictionId].description = _description;

        emit PredictionDescriptionsUpdated(_predictionId, _title, _description);
    }

    function updateData(uint _predictionId, 
            uint _forecastEndUtc,
            uint _forecastStartUtc,
            uint _fee, 
            uint8 _outcomesCount,
            uint _initialTokens,
            uint _totalTokens) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused 
        predictionExist(_predictionId) {

        predictions[_predictionId].forecastEndUtc = _forecastEndUtc;
        predictions[_predictionId].forecastStartUtc = _forecastStartUtc;
        predictions[_predictionId].fee = _fee;
        predictions[_predictionId].outcomesCount = _outcomesCount;
        predictions[_predictionId].initialTokens = _initialTokens;
        predictions[_predictionId].totalTokens = _totalTokens;

        emit PredictionDataUpdated(_predictionId, _forecastEndUtc, _forecastStartUtc, _fee, _outcomesCount, _initialTokens, _totalTokens);
    }
   

    //////////
    // Views
    //////////
    function getForecast(uint _forecastId) public view returns(uint, uint, address, uint, uint8, uint, uint) {
        return (
            forecasts[_forecastId].id,
            forecasts[_forecastId].predictionId,
            forecasts[_forecastId].owner,
            forecasts[_forecastId].amount,
            forecasts[_forecastId].outcomeId,
            forecasts[_forecastId].paidOut,
            forecasts[_forecastId].created);
    }

    function getOutcome(uint _predictionId, uint8 _outcomeIndex) public view returns(uint, string, string, uint) {
        return (
            predictions[_predictionId].outcomes[_outcomeIndex].id,
            predictions[_predictionId].outcomes[_outcomeIndex].title,
            predictions[_predictionId].outcomes[_outcomeIndex].value,
            predictions[_predictionId].outcomes[_outcomeIndex].totalTokens
           );
    }

    function getDetails(uint _predictionId) public view returns(string, string) {
        return (
            predictionDetails[_predictionId].title,
            predictionDetails[_predictionId].description
           );
    }

    function getPredictionForecastsLength(uint _predictionId) public view returns(uint) {
        return predictions[_predictionId].forecasts.length;
    }

    function getPredictionForecast(uint _predictionId, uint index) public view returns (uint) {
        return predictions[_predictionId].forecasts[index];
    }

    function getMyForecastsLength() public view returns(uint) {
        return myForecasts[msg.sender].length;
    }

    // ////////
    // Utils
    // ////////

    function bytesToUint(bytes b, uint startIndex) public pure returns(uint) {
        uint256 number;
        for(uint i=startIndex;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        
        return number;
    }

    function getPredictionId() private returns (uint) {
        return PREDICTION_ID = PREDICTION_ID.add(1);
    }

     function getForecastId() private returns (uint) {
        return FORECAST_ID = FORECAST_ID.add(1);
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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

