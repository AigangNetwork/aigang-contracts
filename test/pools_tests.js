var TestToken = artifacts.require('TestToken.sol')
var PrizeCalculator = artifacts.require('./pools/PrizeCalculator.sol')
var Pools = artifacts.require('./pools/Pools.sol')

let tryCatch = require('./exceptions.js').tryCatch
let errTypes = require('./exceptions.js').errTypes

contract('Product', accounts => {
    let prizeCalculatorInstance
    let testTokenInstance
    let poolsInstance
    
    let owner = accounts[0]
    let executor = accounts[1]
    let nonOwner = accounts[2]
    let destination = accounts[3]
    let c1 = accounts[4]
    let c2 = accounts[5]

    describe('#initialize', async function () {
      beforeEach(async function () {
        prizeCalculatorInstance = await PrizeCalculator.new()
        testTokenInstance = await TestToken.new()
        poolsInstance = await Pools.new()
      })
  
      it('happy initialize flow', async function () {
        await poolsInstance.initialize(testTokenInstance.address, {
          from: owner
        })
  
        let paused = await poolsInstance.paused({
          from: owner
        })
        
        let token = await poolsInstance.token({
          from: owner
        })          
  
        assert.equal(paused, false)
        
        assert.equal(token, testTokenInstance.address)
      })
  
      it('throws than not owner', async function () {
        await tryCatch(
          poolsInstance.initialize(testTokenInstance.address, {
            from: nonOwner
          }),
          errTypes.revert
        )
  
        let paused = await poolsInstance.paused({
          from: nonOwner
        })

        assert.equal(paused, true)
      })
    })

    describe('#addPool', async function () {
      beforeEach(async function () {
        prizeCalculatorInstance = await PrizeCalculator.new()
        testTokenInstance = await TestToken.new()
        poolsInstance = await Pools.new()
      })
  
      it('happy addPool flow', async function () {
        await poolsInstance.initialize(testTokenInstance.address, {
          from: owner
        })

        var poolId = "123"
        var contributionStartUtc = Date.now()
        var contributionEndUtc = contributionStartUtc + 1000
        var amountLimit = web3.toWei(12, 'ether')

        await poolsInstance.addPool(poolId, destination, 
          contributionStartUtc, contributionEndUtc, amountLimit, 
          prizeCalculatorInstance.address,
          {
          from: owner
        })       
        
        const pool = await poolsInstance.pools.call(poolId);
        // console.log(pool);
      
        assert.equal(contributionStartUtc, pool[0].toNumber())
        assert.equal(contributionEndUtc, pool[1].toNumber())
        assert.equal(destination, pool[2])
        assert.equal(1, pool[3].toNumber()) // status = active 1
        assert.equal(amountLimit, pool[4].toNumber())
        assert.equal(0, pool[5].toNumber()) // amountCollected
        assert.equal(0, pool[6].toNumber()) // amountDistributing
        assert.equal(0, pool[7].toNumber()) // paidout
        assert.equal(prizeCalculatorInstance.address, pool[8])
        let totalPools = await poolsInstance.totalPools()
        assert.equal(totalPools, 1)
      })
    })

    describe('#status change', async function () {
      var poolId = "123"
      var contributionStartUtc = Date.now()
      var contributionEndUtc = contributionStartUtc + 1000
      var amountLimit = web3.toWei(12, 'ether')

      beforeEach(async function () {
        prizeCalculatorInstance = await PrizeCalculator.new()
        testTokenInstance = await TestToken.new()
        poolsInstance = await Pools.new()

        await poolsInstance.initialize(testTokenInstance.address, {
          from: owner
        })

        await poolsInstance.addPool(poolId, destination, 
          contributionStartUtc, contributionEndUtc, amountLimit, 
          prizeCalculatorInstance.address,
          {
          from: owner
        }) 
      })
  
      it('setPoolStatus flow', async function () {
        // set Paused pool
        await poolsInstance.setPoolStatus(poolId, 4, {
          from: owner
        })
        
        const pool = await poolsInstance.pools.call(poolId);
      
        assert.equal(4, pool[3].toNumber()) // status = paused 4
      })

      it('setPoolDistributing flow', async function () {            
          var distributeAmount = web3.toWei(6, 'ether')
        
          await poolsInstance.setPoolAmountDistributing(poolId, 2, distributeAmount, {
            from: owner
          })
          
          const pool = await poolsInstance.pools.call(poolId);
        
          assert.equal(2, pool[3].toNumber()) // status = Distributing 2
          assert.equal(distributeAmount, pool[6].toNumber()) // amountDistributing
      })
    })

    describe('#tokens payouts', async function () {
      var poolId = web3.fromAscii('18fda5cf3a7a4999e3400f4940126432');
      var contributionStartUtc = new Date().getTime() / 1000 - 2;
      var contributionEndUtc = contributionStartUtc + 1000000
      var amountLimit = web3.toWei(12, 'ether')

      beforeEach(async function () {
        prizeCalculatorInstance = await PrizeCalculator.new()
        testTokenInstance = await TestToken.new()
        poolsInstance = await Pools.new()

        await poolsInstance.initialize(testTokenInstance.address, {
          from: owner
        })

        await poolsInstance.addPool(poolId, destination, 
          contributionStartUtc, contributionEndUtc, amountLimit, 
          prizeCalculatorInstance.address,
          {
          from: owner
        })    
      })
  
      it('happy receiveApproval flow', async function () {
        const amount = web3.toWei(2, 'ether');
        var contributionId = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
        
        await testTokenInstance.transfer(c1, amount); // give tokens to 1 contributor
        
        await testTokenInstance.approveAndCall(poolsInstance.address, amount, poolId + contributionId.replace("0x", ""), {
          from: c1
        });

        const contribution = await poolsInstance.getContribution(poolId, contributionId);
        const walletPools = await poolsInstance.walletPools.call(c1,0,{
          from: owner
        })
      
        assert.equal(contribution[0], c1);
        assert.equal(contribution[1].toNumber(), amount);
        assert.equal(contribution[2].toNumber(), 0);
        
        assert.equal(0, await testTokenInstance.balanceOf(c1))
        assert.equal(amount, await testTokenInstance.balanceOf(poolsInstance.address))

        assert.equal(walletPools[0], poolId);
        assert.equal(walletPools[1], contributionId);
      })

      it('happy refund flow', async function () {
        const amount = web3.toWei(2, 'ether');
     
        var contributionId = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
    
        await testTokenInstance.transfer(c1, amount); // give tokens to 1 contributor
        
        await testTokenInstance.approveAndCall(poolsInstance.address, amount, poolId + contributionId.replace("0x", ""), {
          from: c1
        });
        
        await poolsInstance.setPoolAmountDistributing(poolId, 5, amount, {
          from: owner
        })

        await poolsInstance.refund(poolId, contributionId, {
          from: c1
        })
        
        const contribution_c1 = await poolsInstance.getContribution(poolId, contributionId);
        
        assert.equal(contribution_c1[0], c1);
        assert.equal(contribution_c1[1].toNumber(), amount);
        assert.equal(contribution_c1[2].toNumber(), amount);
        
        assert.equal(amount, await testTokenInstance.balanceOf(c1))

        const pool = await poolsInstance.pools.call(poolId);        
     
        assert.equal(amount, pool[7].toNumber()) // paidout
        assert.equal(0, await testTokenInstance.balanceOf(poolsInstance.address))
      })

      it('happy transferToDestination flow', async function () {

        assert.equal(0, await testTokenInstance.balanceOf(destination))

        const amount = web3.toWei(2, 'ether');
     
        var contributionId = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
    
        await testTokenInstance.transfer(c1, amount); // give tokens to 1 contributor
        
        await testTokenInstance.approveAndCall(poolsInstance.address, amount, poolId + contributionId.replace("0x", ""), {
          from: c1
        })

        await poolsInstance.transferToDestination(poolId, {
          from: owner
        })
        
        assert.equal(0, await testTokenInstance.balanceOf(poolsInstance.address))
        assert.equal(amount, await testTokenInstance.balanceOf(destination))
      })
    })
})