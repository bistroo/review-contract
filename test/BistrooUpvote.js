// test with ganache-cli instance
const { singletons } = require('@openzeppelin/test-helpers');
const { use, assert } = require('chai');
// https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
const truffleAssert = require('truffle-assertions');

const BistrooUpvote = artifacts.require("BistrooUpvote");
const BistrooToken = artifacts.require("BistrooToken");

function tokensToHex(tokens) {
  const decimals = web3.utils.toBN(18);
  const transferAmount = web3.utils.toBN(parseInt(tokens, 10));
  const transferAmountHex = '0x' + transferAmount.mul(web3.utils.toBN(10).pow(decimals)).toString('hex');
  return transferAmountHex;
}

contract("BistrooUpvote", accounts => {
  let tokenInstance;
  let contractInstance;
  let erc1820;
  let contractAddress;
  let result;
  const rewardPool = 250;

  console.log("\n accounts: %s", accounts);
  const owner = accounts[0];
  const admin = accounts[1];
  const registrar = accounts[2];
  const consumer = accounts[3];
  const merchant = accounts[4];

  const sendTokens = async (_to, _amount, _fromAddress) => {
    await tokenInstance.transfer(_to, _amount, {from: _fromAddress})
  }

  const initiateTest = async() => {
    tokenInstance = await BistrooToken.deployed();
    contractInstance = await BistrooUpvote.deployed();
    contractAddress = contractInstance.address;
    erc1820 = await singletons.ERC1820Registry(owner);
    console.log("\n initiated contractAddress: %s", contractAddress);
  }

  initiateTest();

  it("funds reward pool",  async () => {
    let amount = tokensToHex(rewardPool);
    await sendTokens(contractAddress, amount, owner);
    let balanceContract = await tokenInstance.balanceOf.call(contractAddress);

    // check that tokens were transferred
    assert.equal(
      web3.utils.toHex(balanceContract),
      tokensToHex(rewardPool),
      'reward pool did not receive the tokens');
    })
  
  it("registers a new vote",  async () => {
    result = await contractInstance.registerUpvote(consumer, merchant, {from: registrar});

    await truffleAssert.eventEmitted(result, 'upvoteStatus', (ev) => {
      return ev._message === "upvotes registered";
    });

    // let upvotesMerchant = await contractInstance.upvotesMerchant[merchant];
    // console.log("\n upvotesMerchant: %s", upvotesMerchant);
    // let upvotesConsumer = await contractInstance.upvotesConsumer[consumer];
    // console.log("\n upvotesConsumer: %s", upvotesConsumer);

    // assert.equal(
    //   upvotesConsumer,
    //   1,
    //   "upvotesConsumer is not 1'"
    // );
    
    // assert.equal(
    //   upvotesMerchant,
    //   1,
    //   "upvotesMerchant is not 1'"
    // );
  })

  it("sends the correct rewards",  async () => {
    // .......
  })

  it("changes the upvotegoalconsumer",  async () => {
    // .......
  })

  it("rejects registerUpvote not done by registrar",  async () => {
    await truffleAssert.reverts(
      contractInstance.registerUpvote(consumer, merchant, {from: admin}),
      "registerUpvote not triggered by registrar!"
    )
  })

  it("changes the registrar",  async () => {
    result = await contractInstance.changeRegistrar(admin, {from: owner});

    truffleAssert.eventEmitted(result, 'registrarChanged', (ev) => {
      return ev[0] === admin;
    });
  })

  it("pauses the contract",  async () => {
    result = await contractInstance.setPaused("true", {from: owner});
    // console.log("\n result2: %s", JSON.stringify(result.logs[0].args));
    await truffleAssert.eventEmitted(result, 'pausedSet', (ev) => {
      return ev.paused === true;
    })
  })

  it("rejects unpausing the contract by non-admin",  async () => {
    await truffleAssert.reverts(
      contractInstance.setPaused("true", {from: merchant}),
      "Ownable: caller is not the owner"
    )
  })

  it("rejects calling a paused contract",  async () => {
    await truffleAssert.reverts(
      contractInstance.registerUpvote(consumer, merchant, {from: admin}),
      "Contract is paused!"
    )
  })
});

