pragma solidity ^0.4.23;

import "./../utils/OwnedWithExecutor.sol";
import "./../utils/SafeMath.sol";
import "./../interfaces/IERC20.sol";
import "./../interfaces/IResultStorage.sol";
import "./../interfaces/IPrizeCalculator.sol";

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
        mapping(uint8 => uint) outcomeTokens;
        uint initialTokens;  
        uint totalTokens;          
        uint totalForecasts;   
        uint totalTokensPaidout;     
        address resultStorage;   
        address prizeCalculator;
    }

    struct Forecast {  
        uint id; 
        uint predictionId;  
        address owner;
        uint amount;
        uint8 outcomeId;
        uint paidOut;
    }

    uint8 public constant version = 1;
    address public token;
    bool public paused = true;
    uint public totalPredictions;
    uint public PREDICTION_ID;
    uint public FORECAST_ID;

    mapping(uint => Prediction) public predictions;
    mapping(uint => Forecast) public forecasts;
    mapping(address => uint[]) public myForecasts;

    uint public totalFeeCollected;

    modifier marketNotPaused() {
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
        marketNotPaused 
        returns (uint) {
        
        uint id = getPredictionId();

        predictions[id].forecastEndUtc = _forecastEndUtc;
        predictions[id].forecastStartUtc = _forecastStartUtc;
        predictions[id].fee = _fee;
        predictions[id].status = PredictionStatus.Published;  
        predictions[id].outcomesCount = _outcomesCount;
        predictions[id].initialTokens = _initialTokens;
        predictions[id].totalTokens = _initialTokens;
        predictions[id].resultStorage = _resultStorage;
        predictions[id].prizeCalculator = _prizeCalculator;

        emit PredictionAdded(id);
        return id;
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
            marketNotPaused {    

        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        
        uint8 outcomeId = uint8(_data[0]);
        bytes32 predictionId = bytesToUint(_data,1);

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
        predictions[predictionId].forecasts.push(forecastId) 

        predictions[predictionId].totalTokens = predictions[predictionId].totalTokens.add(amount);
        predictions[predictionId].totalForecasts = predictions[predictionId].totalForecasts.add(1);
        predictions[predictionId].outcomeTokens[outcomeId] = predictions[predictionId].outcomeTokens[outcomeId].add(amount);
    
        forecasts[forecastId] = Forecast(forecastId, predictionId, _from, amount, outcomeId, 0);
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

    function payout(uint _predictionId, uint _forecastId) public marketNotPaused {
        require(predictions[_predictionId].status == PredictionStatus.Resolved, "Prediction should be resolved");
        require(predictions[_predictionId].resultOutcome != 0, "Outcome should be set");

        Forecast storage forecast = forecasts[_forecastId];
        assert(predictions[_predictionId].resultOutcome == forecast.outcomeId);
        assert(forecast.paidOut == 0);
        
        IPrizeCalculator calculator = IPrizeCalculator(predictions[_predictionId].prizeCalculator);
    
        uint winAmount = calculator.calculatePrizeAmount(
            predictions[_predictionId].totalTokens,
            predictions[_predictionId].outcomeTokens[predictions[_predictionId].resultOutcome],
            forecast.amount
        );

        assert(winAmount > 0);
        forecast.paidOut = winAmount;
        predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(winAmount);
        
        assert(IERC20(token).transfer(forecast.user, winAmount));
        emit PaidOut(_predictionId, _forecastId);
    }

    // Owner can refund any users forecasts
    function refundUser(uint _forecastId) external onlyOwnerOrSuperOwner {
        uint predictionId = forecasts[_forecastId].predictionId;
        require (predictions[predictionId].status != PredictionStatus.Resolved);
        
        performRefund(_forecastId);
    }
   
    // User can refund when status is CANCELED
    function refund(uint _forecastId) external marketNotPaused statusIsCanceled(_predictionId) {
        performRefund(_forecastId);
    }

    function performRefund(uint _forecastId) private {
        require(forecasts[_forecastId].paidOut == 0, "Already paid");  

        uint predictionId = forecasts[_forecastId].predictionId;

        uint refundAmount = forecasts[_forecastId].amount;
        predictions[predictionId].totalTokensPaidout = predictions[predictionId].totalTokensPaidout.add(refundAmount);        
        forecasts[_forecastId].paidOut = refundAmount;
                                                    
        assert(IERC20(token).transfer(predictions[predictionId].forecasts[_forecastId].owner, refundAmount)); 
        emit Refunded(predictionId, _forecastId);
    }

    

    //////////
    // Views
    //////////
    function getForecast(uint _forecastId) public view returns(address, uint, uint8, uint) {
        return (forecasts[_forecastId].user,
            forecasts[_forecastId].amount,
            forecasts[_forecastId].outcomeId,
            forecasts[_forecastId].paidOut);
    }

    function getOutcomeTokens(bytes32 _predictionId, uint8 _outcomeId) public view returns(uint) {
        return (predictions[_predictionId].outcomeTokens[_outcomeId]);
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