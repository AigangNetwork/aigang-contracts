# aigang-contracts

Aigang Smart Contracts:   
 - Prediction Market  
 - Pools  
 - Insurance product  

 ## Run Tests:  
 truffle test --network default  
 truffle test = truffle test --network development   

## Auto-deployment commands:
   truffle compile

   # To testrpc
        truffle migrate
   # To Ropsten Network:
        mnemonic="accountPhrase" apiKey="infuraApiKey" truffle migrate --network ropsten
  
## Flat contracts 
sh ./make_flat.sh  

## Setup

- Deploy AddressManager
       