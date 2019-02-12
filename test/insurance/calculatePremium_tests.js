var PremiumCalculator = artifacts.require('./insurance/PremiumCalculator.sol')

contract('PremiumCalculator', function (accounts) {
  it('...should calculate minimum possible premium', async function () {
    const PremiumCalculatorInstance = await PremiumCalculator.new()

    const basePremiumInWei = web3.toWei(0.000001, 'ether')
    const payout = web3.toWei(0.000002, 'ether')
    const loading = 50 // 50%

    await PremiumCalculatorInstance.initialize(basePremiumInWei, loading, payout, {
      from: accounts[0]
    })

    const batteryDesignCapacity = 3500 // 1
    const currentChargeLevel = 40 // 1
    const deviceAgeInMonths = 1 // 0.9
    const region = 'FI' // 1
    const deviceBrand = 'HUAWEI' // 1
    const batteryWearLevel = '100' // 1

    // premium = 0.000001 * 1 * 0.9 * 0.95 * 1 * 1 * 1 * 1 = 0.000000855
    // premium + loading = 0.000000855 * (100-50) = 0.0000427500

    let premium = await PremiumCalculatorInstance.calculatePremium(
      batteryDesignCapacity,
      currentChargeLevel,
      deviceAgeInMonths,
      region,
      deviceBrand,
      batteryWearLevel, {
        from: accounts[0]
      }
    )

    const premiumInETH = web3.fromWei(premium.toNumber(), 'ether')

    //actual, expected
    assert.equal(premiumInETH, 0.00000135)
  })

  it('...should calculate maximum possible premium', async function () {
    const PremiumCalculatorInstance = await PremiumCalculator.new()

    const basePremiumInWei = web3.toWei(999999.999999, 'ether')
    const payout = web3.toWei(1000, 'ether')
    const loading = 99

    await PremiumCalculatorInstance.initialize(basePremiumInWei, loading, payout, {
      from: accounts[0]
    })

    const batteryDesignCapacity = 3500 // 1
    const currentChargeLevel = 5 // 1.2
    const deviceAgeInMonths = 60 // 1.2
    const region = 'FI' // 1
    const deviceBrand = 'ELEPHONE' // 1.1
    const batteryWearLevel = '100' // 1

    // premium = 999999.999999 * 1 * 1.2 * 1.2 * 1.1 * 1 * 1.1 * 1 * 1 = 1742399.99999826
    // premium + loading = 1742399.99999826 * 199 = 3467375.9999965300

    const premium = await PremiumCalculatorInstance.calculatePremium(
      batteryDesignCapacity,
      currentChargeLevel,
      deviceAgeInMonths,
      region,
      deviceBrand,
      batteryWearLevel, {
        from: accounts[0]
      }
    )

    const premiumInETH = web3.fromWei(premium.toNumber(), 'ether')

    assert.equal(premiumInETH, 3152159.999996848)
  })

  describe('#validate', async function () {
    let premiumCalculatorInstance

    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      const basePremium = web3.toWei(10, 'ether')
      const payout = web3.toWei(20, 'ether')
      const loading = web3.toWei(1, 'ether')

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, {
        from: accounts[0]
      })
    })

    it('happy flow', async function () {
      const batteryDesignCapacity = 3500
      const currentChargeLevel = 5
      const deviceAgeInMonths = 60
      const region = 'CA'
      const deviceBrand = 'SAMSUNG'
      const batteryWearLevel = '100'

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), '')
    })

    it('DEVICE_BRAND should not fail', async function () {
      const batteryDesignCapacity = 3500
      const currentChargeLevel = 5
      const deviceAgeInMonths = 15
      const region = 'FI'
      const deviceBrand = 'ELEPHONE'
      const batteryWearLevel = '100'

      const notValid = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(notValid), '')
    })

    it('DESIGN_CAPACITY should fail', async function () {
      const batteryDesignCapacity = 0
      const currentChargeLevel = 5
      const deviceAgeInMonths = 71
      const region = 'CA'
      const deviceBrand = 'SAMSUNG'
      const batteryWearLevel = '100'

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), 'DC')
    })

    it('CHARGE_LEVEL should fail', async function () {
      const batteryDesignCapacity = 3500
      const currentChargeLevel = 0
      const deviceAgeInMonths = 71
      const region = 'CA'
      const deviceBrand = 'SAMSUNG'
      const batteryWearLevel = '100'

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), 'CL')
    })

    it('DEVICE_AGE should fail', async function () {
      const batteryDesignCapacity = 3500
      const currentChargeLevel = 5
      const deviceAgeInMonths = 73
      const region = 'CA'
      const deviceBrand = 'SAMSUNG'
      const batteryWearLevel = '100'

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), 'DA')
    })

    it('REGION should NOT fail', async function () {
      const batteryDesignCapacity = 3500
      const currentChargeLevel = 5
      const deviceAgeInMonths = 3
      const region = 'G'
      const deviceBrand = 'SAMSUNG'
      const batteryWearLevel = '100'

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), '')
    })

    it('WEAR_LEVEL should fail', async function () {
      const batteryDesignCapacity = 3500 // 1
      const currentChargeLevel = 5 // 1.2
      const deviceAgeInMonths = 3 // 1.2
      const region = 'FI' // 1
      const deviceBrand = 'SAMSUNG' // 1.1
      const batteryWearLevel = '30' // 1

      const result = await premiumCalculatorInstance.validate(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      assert.equal(web3.toUtf8(result), 'WL')
    })
  })

  describe('#coefficients', async function () {
    let premiumCalculatorInstance

    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
      const basePremium = web3.toWei(100, 'ether')
      const payout = web3.toWei(200, 'ether')
      const loading = 50

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, {
        from: accounts[0]
      })
    })

    it('...should remove interval coefficient', async function () {
      const batteryDesignCapacity = 3500 // 1
      const currentChargeLevel = 99 // 1
      const deviceAgeInMonths = 7 // 1
      const region = 'FI' // 1
      const deviceBrand = 'SAMSUNG' // 1
      const batteryWearLevel = '100' // 1
      const type = 'DC'
      const coefficient = 100

      await premiumCalculatorInstance.removeIntervalCoefficient(type, coefficient)

      const premium = await premiumCalculatorInstance.calculatePremium(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      const premiumInETH = web3.fromWei(premium.toNumber(), 'ether')

      assert.equal(premiumInETH, 0)
    })

    it('...should set coefficient', async function () {
      const batteryDesignCapacity = 3500 // 1
      const currentChargeLevel = 99 // 1
      const deviceAgeInMonths = 7 // 1
      const region = 'FI' // 1
      const deviceBrand = 'SAMSUNG' // 1
      const batteryWearLevel = '100' // 1
      const type = 'R'
      const newCoefficient = 200

      await premiumCalculatorInstance.setCoefficient(type, region, newCoefficient)

      const premium = await premiumCalculatorInstance.calculatePremium(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      const premiumInETH = web3.fromWei(premium.toNumber(), 'ether')

      assert.equal(premiumInETH, 300)
    })

    it('...should set interval coefficient', async function () {
      const batteryDesignCapacity = 2500 // 1
      const currentChargeLevel = 99 // 1
      const deviceAgeInMonths = 7 // 1
      const region = 'FI' // 1
      const deviceBrand = 'SAMSUNG' // 1
      const batteryWearLevel = '100' // 1

      const type = 'DC'
      const index = 0
      const insert = false // 1 insert, 0 update
      const minValue = 1000
      const maxValue = 3000
      const coefficient = 100

      await premiumCalculatorInstance.setIntervalCoefficient(type, index, insert, minValue, maxValue, coefficient)

      const premium = await premiumCalculatorInstance.calculatePremium(
        batteryDesignCapacity,
        currentChargeLevel,
        deviceAgeInMonths,
        region,
        deviceBrand,
        batteryWearLevel, {
          from: accounts[0]
        }
      )

      const premiumInETH = web3.fromWei(premium.toNumber(), 'ether')

      assert.equal(premiumInETH, 150)
    })
  })

  describe('#claim', async function () {
    let premiumCalculatorInstance

    beforeEach(async function () {
      premiumCalculatorInstance = await PremiumCalculator.new()
    })

    it('...should be claimable', async function () {
      const batteryWearLevel = "20"

      const isClaimable = await premiumCalculatorInstance.isClaimable(batteryWearLevel, {
        from: accounts[0]
      })

      assert.equal(isClaimable, true)
    })

    it('...should not be claimable', async function () {
      const batteryWearLevel = "31"

      const isClaimable = await premiumCalculatorInstance.isClaimable(batteryWearLevel, {
        from: accounts[0]
      })

      assert.equal(isClaimable, false)
    })
  })
})