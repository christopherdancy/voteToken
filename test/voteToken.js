//Contract Abstraction
const voteToken = artifacts.require('voteToken');

//call contract name
//call accounts
contract("voteToken", (accounts) => {

  //Delegate function
  it("should delegate vote power to an address", async() => {
    //setup
    const contractInstance = await voteToken.new();
    //act
    //generate new tokens
    await contractInstance.generateTokens({from:accounts[0]});
    //delegate to accounts[1] fro, accounts[0]
    await contractInstance.delegate(accounts[1], 10, {from: accounts[0]});
    //what is the votePowerof accounts[1]
    result = await contractInstance.votePowerOf(accounts[1]);
    //assert
    assert.equal(result, 10);
  })

  //votePowerofAt function
  it("should return votePower of block", async() => {
    //setup
    const contractInstance = await voteToken.new();
    //act
    //generate new tokens
    await contractInstance.generateTokens({from:accounts[0]});
    //delegate tokens to accounts[1]
    await contractInstance.delegate(accounts[1], 10, {from: accounts[0]});
    //use votePowerOf to access current block
    //run votePowerofAt with current block
    result = await contractInstance.votePowerOf(accounts[0]);
    //assert
    assert.equal(result, 90);
  })

  //BalanceofAt function
  it("should return balance of block", async() => {
    //setup
    const contractInstance = await voteToken.new();
    //act
    //generate new tokens
    await contractInstance.generateTokens({from:accounts[0]});
    //delegate tokens to accounts[1]
    await contractInstance.delegate(accounts[1], 10, {from: accounts[0]});
    //use balanceof  to access current block
    //run balanceofAt with current block
    result = await contractInstance.balanceOf(accounts[0]);
    //assert
    assert.equal(result, 100);
  })


})
