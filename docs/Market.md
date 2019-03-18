# Predictions Market

![PMContracts](/images/predictionMarketContracts.png?raw=true "PM Contracts")

This is the main contract for Predictions market. This contract holds:
* AIX Balance of all predictions
* All actions Events 
* Available predictions list
* Participants forecasts details

**Events**
- Initialize
- PredictionAdded
- ForecastAdded
- PredictionStatusChanged
- Refunded
- PredictionResolved
- PaidOut
- Withdraw
- PredictionDescriptionsUpdated
- PredictionOutcomeAdded
- PredictionOutcomeUpdated
- PredictionAddressesUpdated
- PredictionDataUpdated

**Prediction entity**

The entity holds all participants forecasts and addresses to ResultStorage, PrizeCalculator. Full Entity structure:

* id - identity
* forecastStartUtc - Start date when Prediction starts to accept forecasts.
* forecastEndUtc - End date until which prediction accept forecasts
* fee - Each prediction can have a fee.  
* status: 

  * NotSet (0)
  * Published (1) - prediction is ready for market. Initial status.
  * Resolved (2) - prediction winning outcome is known and payouts are ready.
  * Paused (3) - participation in this predictions is paused and administrators are investigating what is happening
  * Canceled (4) - some issue happened and refunds for this prediction participants will happen.  
   
* outcomesCount - number how much outcomes are available
* resultOutcome - outcome index which won prediction. Start from 1.
* forecasts - an array of participants forecasts ids.
* initialTokens - a number of tokens which was transferred by an organizer  
* totalTokens - prediction tokens amount  
* totalForecasts - forecasts participated in this prediction count
* totalTokensPaidout - total tokens paid out after resolving  
* resultStorage - result oracle contract address [ResultStorage spec](ResultStorage.md)
* prizeCalculator - prize calculator formula contract address [PrizeCalculator spec](PrizeCalculator.md)
* outcomes - array of outcomes:

  * id - identity
  * title - name of outcome
  * value - value expression which can be compared with oracle result.
  * tatalTokens - total collected tokens for this outcome.

**Forecast entity**

* id - identity
* user - forecast owner wallet address
* amount - forecast size in AIX tokens
* outcomeId - forecast selected outcome index
* paidout - if the prediction is canceled or forecast won - an amount which was paid for user

**Details entity**

* title - prediction title
* description - prediction description

**Market functions**

* **version** - version  
* **token** - token address set on initialization  
* **paused** - paused flag. Market can be paused by owner and no other actions can be done  
* **PREDICTION_ID** - last generated prediction Id  
* **FORECAST_ID** - last generated forecast Id  

* **predictionDetails** - list predictions details  
* **predictions** - list of all predictions created in this market  
* **forecasts** - list of all forecasts participated in this market  
* **myForecasts** - user wallet forecasts ids  

* **initialize** - market owner should initialize market to start predictions  
* **addPrediction** - owner can add prediction using this function  
* **updateOutcome** - owner can add and update outcome for prediction  
* **changePredictionStatus** - [emergency function] owner can pause prediction when something wrong happened  
* **receiveApproval** - AIX token will call this function to setup user forecast 
* **resolve** - prediction resolving function will be called after oracle knows prediction winning outcome id  
* **payout** - function dedicated for winning payouts to take their rewards  
* **refundUser** - [emergency function] - owner can refund forecast to owner in case of issue  
* **refund** - if prediction was canceled users using this function will get refund  
* **transferToPool** - After the product end return leftover AIX tokens to the pool  

Update functions:
* **updateAddresses** - update child contract address of prediction
* **updateDescriptions** - update prediction title and description
* **updateData** - update prediction data fields, like forecast start and end dates

View functions are used, because of current solidity limitations:  

* **getForecast** - ability to read forecast details
* **getOutcome** -  ability to know each outcome data
* **getDetails** -  read prediction details
* **getPredictionForecastsLength** - number of prediction forecasts
* **getPredictionForecast** - get prediction forecast id by index
* **getMyForecastsLength** - get my forecasts length

Safety functions:  

* **withdrawETH** - withdraw all ethers in case something wrong will be found
* **withdrawTokens** - withdraw all tokens in case something wrong will be found
* **pause** - pause market in case something wrong will be found