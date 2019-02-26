var TestToken = artifacts.require('TestToken.sol')
var PremiumCalculator = artifacts.require('./insurance/PremiumCalculator.sol')
var Product = artifacts.require('./insurance/Product.sol')

let tryCatch = require('../exceptions.js').tryCatch
let errTypes = require('../exceptions.js').errTypes

contract('Product', accounts => {
  let premiumCalculatorInstance
  let testTokenInstance
  let productInstance
  let now
  let endDate
  let owner = accounts[0]
  let executor = accounts[1]
  let nonOwner = accounts[2]
  let pool = accounts[3]
  let addresses = [
    '0xD7dFCEECe5bb82F397f4A9FD7fC642b2efB1F565',
    '0x501AC3B461e7517D07dCB5492679Cc7521AadD42',
    '0xDc76C949100FbC502212c6AA416195Be30CE0732',
    '0x2C49e8184e468F7f8Fb18F0f29f380CD616eaaeb',
    '0xB3d3c445Fa47fe40a03f62d5D41708aF74a5C387',
    '0x34D468BFcBCc0d83F4DF417E6660B3Cf3e14F62A',
    '0x27E6FaE913861180fE5E95B130d4Ae4C58e2a4F4',
    '0x7B199FAf7611421A02A913EAF3d150E359718C2B',
    '0x086282022b8D0987A30CdD508dBB3236491F132e',
    '0xdd39B760748C1CA92133FD7Fc5448F3e6413C138',
    '0x0868411cA03e6655d7eE957089dc983d74b9Bf1A',
    '0x4Ec993E1d6980d7471Ca26BcA67dE6C513165922'
  ]

  describe('#initialize', async function () {
    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()

      const basePremium = web3.toWei(10, 'ether')
      const payout = web3.toWei(20, 'ether')
      const loading = web3.toWei(1, 'ether')
      now = Date.now()
      endDate = now + 60

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, {
        from: owner
      })
    })

    it('happy flow', async function () {
      await productInstance.initialize(testTokenInstance.address, now, endDate, 0, "Title", "Description", {
        from: owner
      })

      await productInstance.initializePolicies(premiumCalculatorInstance.address, 100, 2000000000000000000000, 604800, {
        from: owner
      })

      let paused = await productInstance.paused({
        from: owner
      })
      let premiumCalculator = await productInstance.premiumCalculator({
        from: owner
      })
      let token = await productInstance.token({
        from: owner
      })
      let utcProductStartDate = await productInstance.utcProductStartDate({
        from: owner
      })
      let utcProductEndDate = await productInstance.utcProductEndDate({
        from: owner
      })

      assert.equal(paused, false)
      assert.equal(premiumCalculator, premiumCalculatorInstance.address)
      assert.equal(utcProductStartDate, now)
      assert.equal(utcProductEndDate, endDate)
    })

    it('throws than not owner', async function () {
      await tryCatch(
        productInstance.initialize(testTokenInstance.address, now, endDate, 0, "Title", "Description", {
          from: nonOwner
        }),
        errTypes.revert
      )

      let paused = await productInstance.paused({
        from: nonOwner
      })
      let utcProductStartDate = await productInstance.utcProductStartDate({
        from: nonOwner
      })
      let utcProductEndDate = await productInstance.utcProductEndDate({
        from: nonOwner
      })

      assert.equal(paused, true)
      assert.equal(utcProductStartDate, 0)
      assert.equal(utcProductEndDate, 0)
    })
  })

  describe('#policies', async function () {
    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()

      const basePremium = web3.toWei(10, 'ether')
      const payout = web3.toWei(20, 'ether')
      const loading = web3.toWei(1, 'ether')
      now = Date.now()
      endDate = now + 6000

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, {
        from: owner
      })
      await productInstance.initialize(testTokenInstance.address, now, endDate, 0, "Title", "Description",{
        from: owner
      })
      await productInstance.initializePolicies(premiumCalculatorInstance.address, 100, 2000000000000000000000, 604800, {
        from: owner
      })
    })

    it('happy flow', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      //let p_owner = addresses[0]
      // let start = Date.now()
      // let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
        from: owner
      })

      let policiesCount = await productInstance.policiesIdsLength({
        from: owner
      })

      assert.equal(policiesCount, 1)
    })

    it('claim not set policy', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      //let p_owner = addresses[0]
      let start = Date.now()
      const claimProperties = "TEST"

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await tryCatch(
        productInstance.claim(policyIdBytes, claimProperties),
        errTypes.revert
      )

      const payoutsCount = await productInstance.policiesPayoutsCount({
        from: owner
      })


    it('claim canceled policy', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      let start = Date.now()
      let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'
      const claimProperties = "TEST"

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes, start, end, calculatedPayOut, properties, {
        from: owner
      })

      await productInstance.cancel(policyIdBytes, { from: owner })

      await tryCatch(
        productInstance.claim(policyIdBytes, claimProperties),
        errTypes.revert
      )

      const payoutsCount = await productInstance.policiesPayoutsCount({
        from: owner
      })
        
      assert.equal(payoutsCount.toNumber(), 0)
    })
    
    it('claim with not owner', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      let start = Date.now()
      let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'
      const claimProperties = "TEST"

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
        from: owner
      })

      await tryCatch(
        productInstance.claim(policyIdBytes, claimProperties, { from: accounts[1]}),
        errTypes.revert
      )

      const payoutsCount = await productInstance.policiesPayoutsCount({
        from: owner
      })
        
      assert.equal(payoutsCount.toNumber(), 0)
    })
        
      assert.equal(payoutsCount.toNumber(), 0)
    })

    it('contract paused', async function () {
      let policyIdBytes = web3.fromAscii('firstID')

      // let start = Date.now()
      // let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.pause(true)

      await tryCatch(
        productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
          from: owner
        }),
        errTypes.revert
      )

      await productInstance.pause(false)
      
      await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
        from: owner
      })

      let policiesCount = await productInstance.policiesIdsLength({
        from: owner
      })

      assert.equal(policiesCount, 1)
    })

    it('set unpaid policy', async function () {
      let policyIdBytes = web3.fromAscii('firstID')

      // let start = Date.now()
      // let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      await tryCatch(
        productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, { from: owner }), 
        errTypes.revert
      )
    })

    it('pay for the same policy twice', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      let start = Date.now()

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await tryCatch(
        testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, { from: owner }), 
        errTypes.revert
      )
    })

    it('update policy', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      let start = Date.now()
      let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      // let start2 = Date.now() - 10
      // let end2 = start + 10
      let calculatedPayOut2 = web3.toWei(1.5, 'ether')
      let isCanceled = true
      
      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      const paymentValue2 = web3.toWei((premium+100).toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
        from: owner
      })
      
      await productInstance.updatePolicy(policyIdBytes, owner, start, end, paymentValue2, calculatedPayOut2, isCanceled, {
        from: owner
      })

      let policy = await productInstance.policies.call(policyIdBytes)
   
      assert.equal(owner, policy[0])
      // assert.equal(policy[1].toNumber(), start2)
      // assert.equal(policy[2].toNumber(), end2)
      assert.equal(policy[9], isCanceled)
      assert.equal(policy[4].toNumber(), paymentValue2)
      assert.equal(policy[5].toNumber(), calculatedPayOut2)
    })


  it('update policy 2', async function () {
    let policyIdBytes = web3.fromAscii('firstID')
    let start = Date.now()
    // let end = start + 100
    let calculatedPayOut = web3.toWei(1.6, 'ether')
    let properties = 'test 1'

    const properties2 = "test 2"
    const payout = 100
    const payoutDate = start + 10000
    const claimProperties = "test 3"
    
    const premium = 300
    const paymentValue = web3.toWei(premium.toString(), 'ether')

    await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
      from: owner
    })

    await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
      from: owner
    })
    
    await productInstance.updatePolicy2(policyIdBytes, properties2, payout, payoutDate, claimProperties, {
      from: owner
    })

    policy = await productInstance.policies.call(policyIdBytes)
    
    assert.equal(policy[6], properties2)
    assert.equal(policy[7].toNumber(), payout)
    assert.equal(policy[3].toNumber(), payoutDate)
    assert.equal(policy[8], claimProperties)
  })

    it('happy flow', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      //let p_owner = addresses[0]
      // let start = Date.now()
      // let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
        from: owner
      })

      let policiesCount = await productInstance.policiesIdsLength({
        from: owner
      })

      assert.equal(policiesCount, 1)
    })

    it('set same policy twice', async function () {
        let policyIdBytes = web3.fromAscii('firstID')
        //let p_owner = addresses[0]
        // let start = Date.now()
        // let end = start + 100
        let calculatedPayOut = web3.toWei(1.6, 'ether')
        let properties = 'test 1'
  
        const premium = 300
        const paymentValue = web3.toWei(premium.toString(), 'ether')
  
        await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
          from: owner
        })
  
        await productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, {
          from: owner
        })

        await tryCatch(productInstance.addPolicy(policyIdBytes, calculatedPayOut, properties, { from: owner }), errTypes.revert)
    })

    it('claim same policy twice', async function () {
      let policyIdBytes = web3.fromAscii('firstID')
      // let start = Date.now()
      // let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'
      const claimProperties = "TEST"

      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      await productInstance.addPolicy(policyIdBytes,  calculatedPayOut, properties, {
        from: owner
      })

      await productInstance.claim(policyIdBytes, claimProperties)

      await tryCatch(productInstance.claim(policyIdBytes, claimProperties), errTypes.revert)

      const payoutsCount = await productInstance.policiesPayoutsCount({
        from: owner
      })
        
      assert.equal(payoutsCount.toNumber(), 1)
    })
  })

  describe('#payment', async function () {
    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()
      // now = Date.now()
      // endDate = now + 6000

      await productInstance.initialize(testTokenInstance.address, now, endDate, pool, "Title", "Description", {
        from: owner
      })
      await productInstance.initializePolicies(premiumCalculatorInstance.address, 100, 2000000000000000000000, 604800, {
        from: owner
      })

      await testTokenInstance.transfer(accounts[2], web3.toWei(2000))
    })

    it('happy flow', async function () {
      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      let policyIdBytes = web3.fromAscii('firstID')

      await productInstance.initialize(testTokenInstance.address, now, endDate, 0, "Title", "Description", {
        from: owner
      })

      await productInstance.initializePolicies(premiumCalculatorInstance.address, 100, 2000000000000000000000, 604800, {
        from: owner
      })

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      policyIdBytes = web3.fromAscii('secondID')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })
    })

    it('throws that not valid policy owner', async function () {
      const premium = 300
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      let policyIdBytes = web3.fromAscii('thirdID')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })

      try {
        await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
          from: owner
        })
      } catch (error) {
        const invalidJump = error.message.search('revert') >= 0
        assert(invalidJump, 'Expected revert')
      }
    })

    it('withdraw Tokens', async function () {
      const premium = 2000
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      let policyIdBytes = web3.fromAscii('thirdID')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: accounts[2]
      })

      await productInstance.transferOwnership(accounts[2], { from: owner })

      await productInstance.withdrawTokens(paymentValue, testTokenInstance.contract.address, { from: accounts[2] })

      const balance = await testTokenInstance.balanceOf(accounts[2])

      assert.equal(web3.fromWei(balance), 2000)
    })

    it('transferToPool', async function () {
      const premium = 2000
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      let policyIdBytes = web3.fromAscii('thirdID')

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: accounts[2]
      })
    
      await productInstance.transferToPool({ from: owner })

      const balance = await testTokenInstance.balanceOf(pool)

      assert.equal(web3.fromWei(balance), 2000)
    })

  })

  describe('#utils', async function () {
    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      productInstance = await Product.new()
      now = Date.now()
      endDate = now + 6000

      await productInstance.initialize(testTokenInstance.address, now, endDate, 0, "Title", "Description", {
        from: owner
      })

      await productInstance.initializePolicies(premiumCalculatorInstance.address, 100, 2000000000000000000000, 604800, {
        from: owner
      })
    })

    it('update premium calculator', async function () {
      const newPremiumCalculator = await PremiumCalculator.new()
      
      await productInstance.updatePremiumCalculator(newPremiumCalculator.contract.address)

      const premiumCalculatorAddress = await productInstance.premiumCalculator()

      assert.equal(premiumCalculatorAddress, newPremiumCalculator.contract.address)
    })

  })

})