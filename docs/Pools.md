# Pools

![Pools Contracts](/images/poolsContracts.png?raw=true "Pools Contracts")

Space for contributions where users can participate with their own AIX tokens into the pool.  
All collected tokens (pool) will participate in insurance product reserves.  
After finishing insurance product left reserves return to the pool and will be distributed for pool contributors.  

The main contract will be **Pools** contract which holds:

* AIX Balance of all pools  
* All actions Events  
* Available pools list  
* Contributors contribution details  

**Events**

* Initialize
* PoolAdded
* ContributionAdded
* PoolStatusChange
* Paidout
* Withdraw
* PoolAddressesUpdated
* PoolDescriptionsUpdated
* PoolDataUpdated

**Pool entity**

This entity holds all contributions and address to PrizeCalculator. Full Entity structure:

* id - identity
* contributionStartUtc - (UNIX timestamp) Start date when the pool starts to accept contributions  
* contributionEndUtc - (UNIX timestamp) End date until which the pool accept contributions  
* destination - address of the product to which this pool is dedicated  
* status - 

  * NotSet (0)
  * Active (1) - the pool is ready for contributions. Initial status  
  * Distributing (2) - insurance product is ended and rewards are ready  
  * Funding (3) - pool contributions are ended and funds are sent to the insurance product  
  * Paused (4) - the pool is paused by administrators  
  * Canceled (5) - some issue happened and refunds for this pool contributors will happen  
   
* amountLimit - limit how much tokens pool will collect  
* amountCollected - a number of tokens were collected  
* amountDistributing - a number of tokens will be distributed as a reward  
* paidout - a number of tokens were already paid out  
* prizeCalculator - address of reward formula calculator [PrizeCalculator spec](PrizeCalculator.md)
* contributions - an array of contributions ids


**Contribution entity**

* id - identity
* poolId - pool identity
* owner - contribution owner wallet address
* amount - contribution size in AIX tokens
* paidout - if the pool is canceled or pool distributing - an amount which was transferred for user
* created - (UNIX timestamp) When contribution was received.


**Pools functions**

* **version** - version  
* **token** - token address set on initialization  
* **paused** - paused flag. Market can be paused by owner and no other actions can be done  
* **totalPools** - number of total pools added
* **POOL_ID** - last pool id
* **CONTRIBUTION_ID** - last contribution id

* **pools** - list of pools  
* **contributions** - list of contributions  
* **myContributions** - list of wallet contributions  

* **initialize** - pools owner should initialize to start contract  
* **addPool** - owner can add pool using this function  
* **setPoolStatus** - owner can pause or update pool status  
* **setPoolAmountDistributing** - owner sets distributing amount and distributing status (distributing or canceled)  
* **receiveApproval** - AIX token will call this function to setup user contribution  
* **transferToDestination** - owner can transfer all amount to destination  
* **payout** - function dedicated for reward payouts  
* **refund** - function dedicated for payout contribution if it was canceled

Update functions:

* **updateAddresses** - update child contract address of pool
* **updateDescriptions** - update pool title and description
* **updateData** - update pool data fields, like contribution start and end dates

View functions are used, because of current solidity limitations:  

* **getContribution** - ability to read contribution details
* **getPoolContributionsLength** - number of pool contributions
* **getPoolContribution** - get contribution id by index
* **getMyContributionsLength** - get my contributions length

Safety functions:  

* **withdrawETH** - withdraw all ethers in case something wrong will be found
* **withdrawTokens** - withdraw all tokens in case something wrong will be found
* **pause** - pause market in case something wrong will be found