const BistrooToken = artifacts.require("../contracts/BistrooToken.sol");
const BistrooUpvote = artifacts.require("../contracs/BistrooUpvote.sol");

let tokenInstance;
let contractInstance;

require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

// ** DEPLOY ALL CONTRACTS TO GANACHE OR ONLY DEPLOY TRANSPORT AND ORDER CONTRACT TO RINKEBY **
module.exports = async function(deployer, network, accounts) {
  let tokenAddress;
    try {
    if(network === 'development') {
       await singletons.ERC1820Registry(accounts[0]);
    }

    if (network === 'goerli-update') {
      console.log('doing goerli update deploy')
      tokenAddress = "";
    } else {
      console.log('doing new deploy')
      await deployer.deploy(BistrooToken);
      tokenInstance = await BistrooToken.deployed();
      tokenAddress = tokenInstance.address;
      console.log("deployed BistrooToken contract to %s", tokenAddress)
    }

    await deployer.deploy(BistrooUpvote, tokenAddress, accounts[1], accounts[2]);
    contractInstance = await BistrooUpvote.deployed();
    console.log("deployed BistrooUpvote contract to %s", contractInstance.address);

  } catch (error) {
    console.log(error);
  }
  
};
