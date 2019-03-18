# Insurance Product

![Product Contracts](/images/insuranceContracts.png?raw=true "Product Contracts")

The main contract will be **Product** contract which holds all insurance product properties, balance, list of policies and reference to the Premium calculator contract.  

**Policies** contain all audit-able details about policy evaluation dates, premium, payout size, device details on policy writing date and all details about the payout.  

**Premium Calculator** contract will hold a risk model with calculation formulas, base premium, fees and claim validation rules. [PremiumCalculator spec](PremiumCalculator.md)  


**Events**

* PolicyAdd
* Claim  
* Cancel  
* PaymentReceived
* PolicyUpdatedManualy
* WithdrawToPool
* Withdraw
* ProductAddressesUpdated
* ProductUpdated

**Policy entity**

This entity holds all user policy details. Full Entity structure:

* id - 32 symbols hash  
* utcStart - (UNIX timestamp) Start date when the policy was paid  
* utcEnd - (UNIX timestamp) End date until when the policy is valid  
* utcPayoutDate - (UNIX timestamp) date when the payout was done  
* premium - calculated premium at policy creation time  
* calculatedPayout - payout amount which will be paid if the claim happens  
* properties - device properties when the policy was created  
* payout - payout amount which was paid  
* claimProperties - device properties when the claim was created  
* isCanceled - true if the policy was canceled  
* created - (UNIX timestamp) when the policy was created  


**Product functions**

* **token** - token address set on initialization  
* **premiumCalculator** - premium calculator address. [PremiumCalculator spec](PremiumCalculator.md)  
* **investorsPool** - pool address where will be sent all leftover tokens after finalizing product  
* **utcProductStartDate** - date when product will start to accept policies  
* **utcProductEndDate** - date when product will stop to accept policies  
* **title** - product title
* **description** - product description
* **paused** - paused flag. Product can be paused by owner and no other actions can be done  
* **policiesTotalCalculatedPayouts** - total payouts amount calculated in this product  
* **policiesPayoutsCount** - count how much payouts was executed  
* **policiesTotalPayouts** - amount how much payouts was executed  
* **policies** - array of all policies details  
* **policiesIds** - array of all policies ids  
* **myPolicies** - all my policies  
* **created** - date when product was created  
* **policiesLimit** - limit how much policies can be created in this product
* **productPoolLimit** - limit how much tokens can be collected in this product
* **policyTermInSeconds** - policy term

* **initialize** - product owner should initialize to start contract  
* **initializePolicies** - because of solidity limitations initialization is splitted in two parts  
* **addPolicy** - executor service will update user paid policy details  
* **receiveApproval** - AIX token will call this function to setup user policy  
* **claim** - executor service will payout policy when detects broken device  
* **cancel** - set policy flag for canceled  
* **transferToPool** - owner can transfer all amount to investorsPool  

Update functions:

* **updatePolicy** - update policy if something wrong happened  
* **updatePolicy2** - because of solidity limitations update is splitted into 2 parts  
* **updateAddresses** - update product addresses  
* **updateProduct** - update product details  

View functions are used, because of current solidity limitations:  

* **getProductDetails** - function which returns product details using one call  
* **getProductStats** - get product statistic  
* **myPoliciesLength** - my policies count
* **policiesIdsLength** - total number of policies in this product

Safety functions:  

* **tokenBalance** - returns token balance for this product  
* **withdrawETH** - withdraw all ethers in case something wrong will be found  
* **withdrawTokens** - withdraw all tokens in case something wrong will be found  
* **pause** - pause market in case something wrong will be found  