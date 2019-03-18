# Aigang Contracts

Aigang Smart Contracts for:   
 - Prediction Market  
 - Pools  
 - Insurance product  

Full image:

![Architecture](images/architecture.png?raw=true "Architecture")

# Structure
## Web 
This part with detailed configuration instructions can be found at https://github.com/AigangNetwork/aigang-platform-web

## AddressManager.sol
This contract manages addresses for the platform. The web page is reading this contract and loads all available Prediction markets, pools and insurance products. All Functions retails can be found at [Address Manager spec](docs/AddressManager.md)

## Market.sol
This is Prediction Market Contract needed to run prediction market Web and organize predictions. Full detailed spec can be found at [Market spec](docs/Market.md), [PrizeCalclulator spec](docs/PrizeCalculator.md), [ResultStorage spec](docs/ResultStorage.md)

## Pools.sol
This is main contract for token pools collecting. Full detailed spec can be found at [Pools spec](docs/Pools.md), [PrizeCalclulator spec](docs/PrizeCalculator.md)

## Product.sol
This is main contract for insurance product. Full detailed spec can be found at [Product spec](docs/Product.md), [PremiumCalculator spec](docs/PremiumCalculator.md)

# Development

## Run Tests:  
        truffle test --network default  
        truffle test = truffle test --network development  

## Auto-deployment commands:
        truffle compile

## To testrpc
        truffle migrate

## To Ropsten Network:
        mnemonic="accountPhrase" apiKey="infuraApiKey" truffle migrate --network ropsten
  
## Flat contracts 
        sh ./make_flat.sh  

# Contributing

Everyone is welcome to contribute this repository, just make sure your code does not have validation issues and builds without errors. Create your feature branch and send us a pull request to the master branch.
