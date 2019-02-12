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

  describe('#product', async function () {

    beforeEach(async function () {
        premiumCalculatorInstance = await PremiumCalculator.new()
        testTokenInstance = await TestToken.new()
        productInstance = await Product.new()
  
        const basePremium = web3.toWei(10, 'ether')
        const payout = web3.toWei(20, 'ether')
        const loading = 100
        now = Date.now()
        endDate = now + 6000
  
        await premiumCalculatorInstance.initialize(basePremium, loading, payout, {
          from: owner
        })

        await productInstance.initialize(premiumCalculatorInstance.address, testTokenInstance.address, now, endDate, 0, {
          from: owner
        })

        await testTokenInstance.transfer(accounts[1], web3.toWei(100))

        await testTokenInstance.transfer(accounts[2], web3.toWei(50))

        await testTokenInstance.transfer(accounts[3], web3.toWei(50))
    })

    it('1 success workflow', async function () {
      const end = new Date().getTime() / 1000 + 3
      const start = new Date().getTime() / 1000 - 2
      const payout = await premiumCalculatorInstance.getPayout()

      const policyIdBytes1 = web3.fromAscii('firstID')
      const properties1 = {
        batteryDesignCapacity: 3500,
        currentChargeLevel: 40,
        deviceAgeInMonths: 1,
        region: 'FI', // 1
        deviceBrand: 'HUAWEI',
        batteryWearLevel: '100'
      }

      let isValid = await premiumCalculatorInstance.validate(
        properties1.batteryDesignCapacity,
        properties1.currentChargeLevel,
        properties1.deviceAgeInMonths,
        properties1.region,
        properties1.deviceBrand,
        properties1.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium1 = await premiumCalculatorInstance.calculatePremium(
        properties1.batteryDesignCapacity,
        properties1.currentChargeLevel,
        properties1.deviceAgeInMonths,
        properties1.region,
        properties1.deviceBrand,
        properties1.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium1.toNumber(), policyIdBytes1, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes1, start, end, payout, JSON.stringify(properties1), {
        from: owner
      })
      

      const policyIdBytes2 = web3.fromAscii('secondID')
      const properties2 = {
        batteryDesignCapacity: 4000,
        currentChargeLevel: 100,
        deviceAgeInMonths: 4,
        region: 'LT',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100' 
      }

      isValid = await premiumCalculatorInstance.validate(
        properties2.batteryDesignCapacity,
        properties2.currentChargeLevel,
        properties2.deviceAgeInMonths,
        properties2.region,
        properties2.deviceBrand,
        properties2.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium2 = await premiumCalculatorInstance.calculatePremium(
        properties2.batteryDesignCapacity,
        properties2.currentChargeLevel,
        properties2.deviceAgeInMonths,
        properties2.region,
        properties2.deviceBrand,
        properties2.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium2, policyIdBytes2, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes2, start, end, payout, JSON.stringify(properties2), {
        from: owner
      })

      const policyIdBytes3 = web3.fromAscii('thirdID')
      const properties3 = {
        batteryDesignCapacity: 4000,
        currentChargeLevel: 100,
        deviceAgeInMonths: 4,
        region: 'LT',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100'
      }

      isValid = await premiumCalculatorInstance.validate(
        properties3.batteryDesignCapacity,
        properties3.currentChargeLevel,
        properties3.deviceAgeInMonths,
        properties3.region,
        properties3.deviceBrand,
        properties3.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium3 = await premiumCalculatorInstance.calculatePremium(
        properties3.batteryDesignCapacity,
        properties3.currentChargeLevel,
        properties3.deviceAgeInMonths,
        properties3.region,
        properties3.deviceBrand,
        properties3.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium3, policyIdBytes3, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes3, start, end, payout, JSON.stringify(properties3), {
        from: owner
      })
      

      const policyIdBytes4 = web3.fromAscii('fourthID')
      const properties4 = {
        batteryDesignCapacity: 3900,
        currentChargeLevel: 100,
        deviceAgeInMonths: 6,
        region: 'IE',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100'
      }

      isValid = await premiumCalculatorInstance.validate(
        properties4.batteryDesignCapacity,
        properties4.currentChargeLevel,
        properties4.deviceAgeInMonths,
        properties4.region,
        properties4.deviceBrand,
        properties4.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium4 = await premiumCalculatorInstance.calculatePremium(
        properties4.batteryDesignCapacity,
        properties4.currentChargeLevel,
        properties4.deviceAgeInMonths,
        properties4.region,
        properties4.deviceBrand,
        properties4.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium4, policyIdBytes4, {
        from: owner
      })  
  
      await productInstance.addPolicy(policyIdBytes4, start, end, payout, JSON.stringify(properties4), {
        from: owner
      })

      properties4.batteryWearLevel = '10'

      const isClaimable4 = await premiumCalculatorInstance.isClaimable(properties4.batteryWearLevel)

      if(isClaimable4){
        await productInstance.claim(policyIdBytes4, JSON.stringify(properties4))
      }

      const policiesPayoutsCount = await productInstance.policiesPayoutsCount();
      const policiesTotalPayouts = await productInstance.policiesTotalPayouts();

      assert.equal(policiesPayoutsCount, 1)
      assert.equal(policiesTotalPayouts.toNumber(), payout)

      const policiesCount = await productInstance.policiesCount()

      const policiesTotalCalculatedPayouts = await productInstance.policiesTotalCalculatedPayouts();

      assert.equal(policiesTotalCalculatedPayouts.toNumber(), payout.toNumber() * 4)
      assert.equal(policiesCount, 4)

      // Sleep to make prediction endTime < now
      await sleep(3000)
      
      const claimProperties = { batteryWearLevel: 100 }
      await tryCatch(productInstance.claim(policyIdBytes1, JSON.stringify(claimProperties)), errTypes.revert)
      await tryCatch(productInstance.claim(policyIdBytes2, JSON.stringify(claimProperties)), errTypes.revert)
      await tryCatch(productInstance.claim(policyIdBytes3, JSON.stringify(claimProperties)), errTypes.revert)
    })

    it('2 success workflow', async function () {
      const end = new Date().getTime() / 1000 + 3
      const start = new Date().getTime() / 1000 - 2
      const payout = await premiumCalculatorInstance.getPayout()

      const policyIdBytes1 = web3.fromAscii('firstID')
      const properties1 = {
        batteryDesignCapacity: 3500,
        currentChargeLevel: 40,
        deviceAgeInMonths: 1,
        region: 'FI', // 1
        deviceBrand: 'HUAWEI',
        batteryWearLevel: '100'
      }

      let isValid = await premiumCalculatorInstance.validate(
        properties1.batteryDesignCapacity,
        properties1.currentChargeLevel,
        properties1.deviceAgeInMonths,
        properties1.region,
        properties1.deviceBrand,
        properties1.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium1 = await premiumCalculatorInstance.calculatePremium(
        properties1.batteryDesignCapacity,
        properties1.currentChargeLevel,
        properties1.deviceAgeInMonths,
        properties1.region,
        properties1.deviceBrand,
        properties1.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium1.toNumber(), policyIdBytes1, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes1, start, end, payout, JSON.stringify(properties1), {
        from: owner
      })

      const policyIdBytes2 = web3.fromAscii('secondID')
      const properties2 = {
        batteryDesignCapacity: 4000,
        currentChargeLevel: 100,
        deviceAgeInMonths: 4,
        region: 'LT',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100' 
      }

      isValid = await premiumCalculatorInstance.validate(
        properties2.batteryDesignCapacity,
        properties2.currentChargeLevel,
        properties2.deviceAgeInMonths,
        properties2.region,
        properties2.deviceBrand,
        properties2.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium2 = await premiumCalculatorInstance.calculatePremium(
        properties2.batteryDesignCapacity,
        properties2.currentChargeLevel,
        properties2.deviceAgeInMonths,
        properties2.region,
        properties2.deviceBrand,
        properties2.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium2, policyIdBytes2, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes2, start, end, payout, JSON.stringify(properties2), {
        from: owner
      })


      const policyIdBytes3 = web3.fromAscii('thirdID')
      const properties3 = {
        batteryDesignCapacity: 4000,
        currentChargeLevel: 100,
        deviceAgeInMonths: 4,
        region: 'LT',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100'
      }

      isValid = await premiumCalculatorInstance.validate(
        properties3.batteryDesignCapacity,
        properties3.currentChargeLevel,
        properties3.deviceAgeInMonths,
        properties3.region,
        properties3.deviceBrand,
        properties3.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')
 
      const premium3 = await premiumCalculatorInstance.calculatePremium(
        properties3.batteryDesignCapacity,
        properties3.currentChargeLevel,
        properties3.deviceAgeInMonths,
        properties3.region,
        properties3.deviceBrand,
        properties3.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium3, policyIdBytes3, {
        from: owner
      })
  
      await productInstance.addPolicy(policyIdBytes3, start, end, payout, JSON.stringify(properties3), {
        from: owner
      })
      
      const policyIdBytes4 = web3.fromAscii('fourthID')
      const properties4 = {
        batteryDesignCapacity: 3900,
        currentChargeLevel: 100,
        deviceAgeInMonths: 6,
        region: 'IE',
        deviceBrand: 'SAMSUNG',
        batteryWearLevel: '100'
      }

      isValid = await premiumCalculatorInstance.validate(
        properties4.batteryDesignCapacity,
        properties4.currentChargeLevel,
        properties4.deviceAgeInMonths,
        properties4.region,
        properties4.deviceBrand,
        properties4.batteryWearLevel
      )

      assert.equal(web3.toAscii(isValid), '\u0000\u0000')

      const premium4 = await premiumCalculatorInstance.calculatePremium(
        properties4.batteryDesignCapacity,
        properties4.currentChargeLevel,
        properties4.deviceAgeInMonths,
        properties4.region,
        properties4.deviceBrand,
        properties4.batteryWearLevel
      )
  
      await testTokenInstance.approveAndCall(productInstance.contract.address, premium4, policyIdBytes4, {
        from: owner
      })  
  
      await productInstance.addPolicy(policyIdBytes4, start, end, payout, JSON.stringify(properties4), {
        from: owner
      })

      const policiesCount = await productInstance.policiesCount()
      const policiesTotalCalculatedPayouts = await productInstance.policiesTotalCalculatedPayouts()

      assert.equal(policiesTotalCalculatedPayouts.toNumber(), payout * 4)
      assert.equal(policiesCount, 4)
      
      properties1.batteryWearLevel = '10'
      properties2.batteryWearLevel = '20'
      properties3.batteryWearLevel = '100'
      properties4.batteryWearLevel = '10'

      let isClaimable = await premiumCalculatorInstance.isClaimable(properties1.batteryWearLevel)
      assert.isTrue(isClaimable)

      isClaimable = await premiumCalculatorInstance.isClaimable(properties2.batteryWearLevel)
      assert.isTrue(isClaimable)

      isClaimable = await premiumCalculatorInstance.isClaimable(properties3.batteryWearLevel)
      assert.isFalse(isClaimable)

      isClaimable = await premiumCalculatorInstance.isClaimable(properties4.batteryWearLevel)
      assert.isTrue(isClaimable)

      await productInstance.claim(policyIdBytes1, JSON.stringify(properties1))
      await productInstance.claim(policyIdBytes2, JSON.stringify(properties2))
      await productInstance.claim(policyIdBytes4, JSON.stringify(properties4))
      await tryCatch(productInstance.claim(policyIdBytes3, JSON.stringify(properties3)), errTypes.revert)

      const policiesPayoutsCount = await productInstance.policiesPayoutsCount();
      const policiesTotalPayouts = await productInstance.policiesTotalPayouts();

      assert.equal(policiesPayoutsCount.toNumber(), 3)
      assert.equal(policiesTotalPayouts.toNumber(), payout.toNumber() * 3)
    })
  })
})


const sleep = milliseconds => {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve()
    }, milliseconds)
  })
}