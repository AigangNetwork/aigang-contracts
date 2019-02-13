const PrizeCalculator = artifacts.require('./PrizeCalculator.sol')

const BigNumber = web3.BigNumber
contract('PrizeCalculator', accounts => {
  let prizeCalculatorInstance

  describe('#calculatePrizeAmount', async () => {
    let id
    beforeEach(async () => {
      prizeCalculatorInstance = await PrizeCalculator.new()
    })

    it('calculate prize 1', async () => {
      const predictionTotalTokens = web3.toWei(1000, 'ether')
      const winOutputTotalTokens = web3.toWei(100, 'ether')
      const forecastTokens = web3.toWei(50, 'ether')

      // Result should:
      // forecastTokens * predictionTotalTokens  / winOutpuTokens
      // (50 * 1000 / 100) * 1000000000000000000

      const result = await prizeCalculatorInstance.calculatePrizeAmount(
        predictionTotalTokens,
        winOutputTotalTokens,
        forecastTokens
      )

      assert.equal(result.toNumber(), 500000000000000000000)
    })

    it('calculate prize 2', async () => {
      const predictionTotalTokens = web3.toWei(111, 'ether')
      const winOutputTotalTokens = web3.toWei(15, 'ether')
      const forecastTokens = web3.toWei(9, 'ether')

      // Result should:
      // forecastTokens * predictionTotalTokens  / winOutpuTokens
      // (50 * 1000 / 100) * 1000000000000000000

      const result = await prizeCalculatorInstance.calculatePrizeAmount(
        predictionTotalTokens,
        winOutputTotalTokens,
        forecastTokens
      )

      assert.equal(result.toNumber(), web3.toWei(66.6, 'ether'))
    })

    it('calculate prize 3', async () => {
      const distributeTotalTokens = web3.toWei(16, 'ether')
      const collectedTotalTokens = web3.toWei(14, 'ether')
      const contributionTokens = web3.toWei(10, 'ether')

      const result = await prizeCalculatorInstance.calculatePrizeAmount(
        distributeTotalTokens, 
        collectedTotalTokens, 
        contributionTokens
      )

      assert.equal(result.toNumber(), web3.toWei(11.428571428571429000, 'ether')  )
    })
  })
})
