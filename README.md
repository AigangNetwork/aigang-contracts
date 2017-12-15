# aigang-contracts

Aigang Smart Contracts for our Insurance Protocol

## Auto-deployment commands:
   truffle compile

   # To testrpc
        truffle migrate
   # To Ropsten Network:
        mnemonic="accountPhrase" apiKey="infuraApiKey" truffle migrate --network ropsten

## Setup

- Deploy EventEmitter
- Deploy ContractManger
        - Set EventEmitter.addExecutor with parameter "ContractManger" address
        - Call SetContract: "EventEmitter" address;

### Product deployment

- Deploy Wallet
        - Call EventEmitter.addExecutor with parameter "Wallet" address
- Deploy InsuranceProduct
- Deploy InvestmentManager
        - Call EventEmitter.addExecutor with parameter "InvestmentManager" address
        - Call Wallet.addExecutor add "InvestmentManager" address