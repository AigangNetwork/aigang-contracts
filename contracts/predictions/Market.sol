pragma solidity ^0.4.23;

import "./../utils/OwnedWithExecutor.sol";
import "./../utils/SafeMath.sol";
import "./../interfaces/IERC20.sol";
import "./../interfaces/IResultStorage.sol";
import "./../interfaces/IPrizeCalculator.sol";

contract Market is Owned {
    using SafeMath for uint;  

    event Initialize(address _token); 
    event PredictionAdded(bytes32 id);
    event ForecastAdded(bytes32 predictionId, bytes32 _forecastId); 
    event PredictionStatusChanged(bytes32 predictionId, PredictionStatus oldStatus, PredictionStatus newStatus);
    event Refunded(bytes32 predictionId, bytes32 _forecastId);
    event PredictionResolved(bytes32 predictionId, uint8 winningOutcomeId);
    event PaidOut(bytes32 _predictionId, bytes32 _forecastId);
    event Withdraw(uint _amount);
    //event Debug(uint index);

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
        mapping(bytes32 => Forecast) forecasts;
        mapping(uint8 => uint) outcomeTokens;
        uint initialTokens;  
        uint totalTokens;          
        uint totalForecasts;   
        uint totalTokensPaidout;     
        address resultStorage;   
        address prizeCalculator;
    }

    struct Forecast {    
        address user;
        uint amount;
        uint8 outcomeId;
        uint paidOut;
    }

    struct ForecastIndex {    
        bytes32 predictionId;
        bytes32 forecastId;
    }

    uint8 public constant version = 1;
    address public token;
    bool public paused = true;
    uint public totalPredictions;

    mapping(bytes32 => Prediction) public predictions;

    mapping(address => ForecastIndex[]) public walletPredictions;
  
    uint public totalFeeCollected;

    modifier marketNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier statusIsCanceled(bytes32 _predictionId) {
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
        bytes32 _id,
        uint _forecastEndUtc,
        uint _forecastStartUtc,
        uint _fee,
        uint8 _outcomesCount,  
        uint _initialTokens,   
        address _resultStorage, 
        address _prizeCalculator) external onlyOwnerOrSuperOwner marketNotPaused {

        if (predictions[_id].status == PredictionStatus.NotSet) { // do not increase if update
            totalPredictions++;
        } 

        predictions[_id].forecastEndUtc = _forecastEndUtc;
        predictions[_id].forecastStartUtc = _forecastStartUtc;
        predictions[_id].fee = _fee;
        predictions[_id].status = PredictionStatus.Published;  
        predictions[_id].outcomesCount = _outcomesCount;
        predictions[_id].initialTokens = _initialTokens;
        predictions[_id].totalTokens = _initialTokens;
        predictions[_id].resultStorage = _resultStorage;
        predictions[_id].prizeCalculator = _prizeCalculator;

        emit PredictionAdded(_id);
    }

    function changePredictionStatus(bytes32 _predictionId, PredictionStatus _status) 
            external 
            onlyAllowed {
        require(predictions[_predictionId].status != PredictionStatus.NotSet, "Prediction not exist");
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, _status);
        predictions[_predictionId].status = _status;            
    }

    function resolve(bytes32 _predictionId) external onlyAllowed {
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

    function payout(bytes32 _predictionId, bytes32 _forecastId) public marketNotPaused {
        require(predictions[_predictionId].status == PredictionStatus.Resolved, "Prediction should be resolved");
        require(predictions[_predictionId].resultOutcome != 0, "Outcome should be set");

        Forecast storage forecast = predictions[_predictionId].forecasts[_forecastId];
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
        assert(IERC20(token).transfer(forecast.user, winAmount));
        predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(winAmount);
        emit PaidOut(_predictionId, _forecastId);
    }

    // Owner can refund any users forecasts
    function refundUser(bytes32 _predictionId, bytes32 _forecastId) external onlyOwnerOrSuperOwner {
        require (predictions[_predictionId].status != PredictionStatus.Resolved);
        
        performRefund(_predictionId, _forecastId);
    }
   
    // User can refund when status is CANCELED
    function refund(bytes32 _predictionId, bytes32 _forecastId) external marketNotPaused statusIsCanceled(_predictionId) {
        performRefund(_predictionId, _forecastId);
    }

    function performRefund(bytes32 _predictionId, bytes32 _forecastId) private {
        require(predictions[_predictionId].forecasts[_forecastId].paidOut == 0, "Already paid");  

        uint refundAmount = predictions[_predictionId].forecasts[_forecastId].amount;
        predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(refundAmount);        
        predictions[_predictionId].forecasts[_forecastId].paidOut = refundAmount;
                                                    
        assert(IERC20(token).transfer(predictions[_predictionId].forecasts[_forecastId].user, refundAmount)); 
        emit Refunded(_predictionId, _forecastId);
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    // _data = predictionId(32),forecastId(32),outcomeId(1)
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            marketNotPaused {    
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        require(_data.length == 65, "not valid _data length");
        bytes1 outcomeIdString = _data[64];
        uint8 outcomeId = uint8(outcomeIdString);

        bytes32 predictionIdString = bytesToFixedBytes32(_data,0);
        bytes32 forecastIdString = bytesToFixedBytes32(_data,32);

        // Validate prediction and forecast
        require(predictions[predictionIdString].status == PredictionStatus.Published, "Prediction is not published");
        require(predictions[predictionIdString].forecastEndUtc > now, "Forecasts are over");
        require(predictions[predictionIdString].forecastStartUtc < now, "Forecasting has not started yet");
        require(predictions[predictionIdString].outcomesCount >= outcomeId && outcomeId > 0, "Outcome id is not in range");
        require(predictions[predictionIdString].fee < _amountOfTokens, "Amount should be bigger then fee");
        require(predictions[predictionIdString].forecasts[forecastIdString].amount == 0);

        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");

        uint amount = _amountOfTokens.sub(predictions[predictionIdString].fee);
        totalFeeCollected = totalFeeCollected.add(predictions[predictionIdString].fee);

        predictions[predictionIdString].totalTokens = predictions[predictionIdString].totalTokens.add(amount);
        predictions[predictionIdString].totalForecasts = predictions[predictionIdString].totalForecasts.add(1);
        predictions[predictionIdString].outcomeTokens[outcomeId] = predictions[predictionIdString].outcomeTokens[outcomeId].add(amount);
        predictions[predictionIdString].forecasts[forecastIdString] = Forecast(_from, amount, outcomeId, 0);
       
        walletPredictions[_from].push(ForecastIndex(predictionIdString, forecastIdString));

        emit ForecastAdded(predictionIdString, forecastIdString);
    }

    //////////
    // Views
    //////////
    function getForecast(bytes32 _predictionId, bytes32 _forecastId) public view returns(address, uint, uint8, uint) {
        return (predictions[_predictionId].forecasts[_forecastId].user,
            predictions[_predictionId].forecasts[_forecastId].amount,
            predictions[_predictionId].forecasts[_forecastId].outcomeId,
            predictions[_predictionId].forecasts[_forecastId].paidOut);
    }

    function getOutcomeTokens(bytes32 _predictionId, uint8 _outcomeId) public view returns(uint) {
        return (predictions[_predictionId].outcomeTokens[_outcomeId]);
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

    function bytesToFixedBytes32(bytes memory b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}