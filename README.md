# Bistroo Review Contract
Use voting tokens to upvote Merchants and exchange them for rewards 

## Process flow
Roles
* Consumer: Upvotes an order, gets rewards for submitted upvotes
* Merchant: Receives upvotes for an order, gets rewards for received upvotes
* Admin: Sets the smart contract variabes

###### Process
1.	Consumer places an order and receives a unique upvote link
2.	Consumer submits upvotes for the merchant
3.	Merchant receives Rm BIST after Um upvotes
4.	Consumer receives Rc BIST after Uv upvotes

Notes:
* Reward balance of contract needs to be monitored

![Review schematic](https://github.com/bistroo/review-contract/blob/main/images/review-schematic.png)
![Review application design](https://github.com/bistroo/review-contract/blob/main/images/review-application-design.png)

# Installation

## Installing the test enviroment
* run `npm install` to install web3, openzeppelin and truffle libraries

In order to use the truffle-config.js file:
* create .infura file containing infura project ID for using Infura Web3 api
* create .secret file containing mnemonics for creating a specific token owner account
* create .etherscan file etherscan key

# Test and deployment

## On local ganache
open a terminal window
run ganache cli with custom config in this terminal window
```
./start-ganache.sh
```
### Test smart contracts
run ganache cli
open a terminal window
Run test script:
```
truffle test ./test/BistrooToken.js
truffle test ./test/BistrooUpvote.js
```
Known issue with older Truffle version and Babel: `npm install -g babel-runtime`
### Deploy smart contracts
```
npm run migrate-ganache
```
## On Rinkeby
Deploy only the contract on Rinkeby:
```
npm run migrate-rinkeby-update
```
Deploy both contracts on Rinkeby:
```
npm run migrate-rinkeby
```
