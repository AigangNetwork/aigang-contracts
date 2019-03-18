# Premium Calculator

This contract stores premium calculation details.

* **calculation coefficients and intervals** - all detail from premium calculation model  
* **basePremium**  - base premium  
* **payout** - payout size in weis  
* **loading** - fee in percents from 1 - n

Each premium calculator should inherit similar IPremiumCalculator interface with functions:  

* **calculatePremium** - function calculates policy premium with provided parameters
* **validate** - validates parameters for claim
* **isClaimable** - check device property is failing
* **getPayout** - get payout size in weis
* **getDetails** - get contract configuration