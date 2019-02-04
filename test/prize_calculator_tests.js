const PrizeCalculator = artifacts.require('./pools/PrizeCalculator.sol')

const BigNumber = web3.BigNumber
contract('PrizeCalculator', accounts => {
  let prizeCalculatorInstance

  describe('#calculatePrizeAmount', async () => {
    let id
    beforeEach(async () => {
      prizeCalculatorInstance = await PrizeCalculator.new()
    })

    it('calculate prize 1', async () => {
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
