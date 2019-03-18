# Result Storage

This is main contract for Predictions resolving. All type of oracles can add resolutions to this contract.

**Events**

- ResultAssigned(uint indexed _predictionId, uint8 _outcomeId)
- Withdraw(uint _amount)

**Result storage functions**

* **version** - version  
* **paused** - paused flag. Contract can be paused by owner and no other actions can be done  
* **results** - array of resolved prediction results:  
    * outcomeId - outcomeId configured in prediction which won prediction  
    * resolved - flag which identifies prediction is result is set  
* **setOutcome** - function with sets resolved prediction outcome  
* **getResult** - returns prediction won outcome id  

Safety functions:  

* **withdrawETH** - withdraw all ethers in case something wrong will be found
* **withdrawTokens** - withdraw all tokens in case something wrong will be found
* **pause** - pause market in case something wrong will be found