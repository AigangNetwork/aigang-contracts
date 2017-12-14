# aigang-contracts

Aigang Smart Contracts for our Insurance Protocol

## Setup:

- Deploy EventEmitter
- Deploy ContractManger
        - call SetContract: "EventEmitter" address;
- Set EventEmitter.addExecutor with parameter "ContractManger" address


### Product deployment:

- Deploy Wallet
        - Call EventEmitter.addExecutor with parameter "Wallet" address
- Deploy InsuranceProduct
- Deploy InvestmentManager
        - Call EventEmitter.addExecutor with parameter "InvestmentManager" address
        - Call Wallet.CanExecute add "InvestmentManager" address





