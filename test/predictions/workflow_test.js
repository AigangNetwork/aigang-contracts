const TestToken = artifacts.require('TestToken.sol')
const Market = artifacts.require('./predictions/Market.sol')
const PrizeCalculator = artifacts.require('./predictions/PrizeCalculator.sol')
const ResultStorage = artifacts.require('./predictions/ResultStorage.sol')

const Utils = require('../utils.js');

const BigNumber = web3.BigNumber
contract('Market', accounts => {

  let owner = accounts[0]
  let marketInstance
  let prizeCalculatorInstance
  let resultStorageInstance

  describe('#market', async () => {
    let predictionId = Utils.getHex(1) // result is hex 
    let feeInWeis = web3.toWei(1, 'ether')

    beforeEach(async () => {
      marketInstance = await Market.new()
      prizeCalculatorInstance = await PrizeCalculator.new()
      resultStorageInstance = await ResultStorage.new()
      testTokenInstance = await TestToken.new()

      await marketInstance.initialize(testTokenInstance.address)  
      const endTime = Date.now() + 60
      const startTime = Math.floor(new Date().getTime() / 1000 - 2)
      const outcomesCount = 3
      const totalTokens = web3.toWei(10, 'ether')

      await marketInstance.addPrediction(
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      )
      
      await marketInstance.changePredictionStatus(1,1)

      await testTokenInstance.transfer(marketInstance.address, totalTokens)

      const prediction = await marketInstance.predictions.call(predictionId)
      // console.log(prediction)
      assert.equal(endTime, prediction[0].toNumber())
      assert.equal(startTime, prediction[1].toNumber())
      assert.equal(feeInWeis, prediction[2].toNumber())
      assert.equal(1, prediction[3].toNumber()) // published
      assert.equal(outcomesCount, prediction[4].toNumber())  
      assert.equal(totalTokens, prediction[6].toNumber())  //initialTokens
      assert.equal(totalTokens, prediction[7].toNumber())  //totalTokens
     // console.log(`total tokens: ${totalTokens} initial tokens : ${prediction[5].toNumber()}`)
      assert.equal(resultStorageInstance.address, prediction[10])
      assert.equal(prizeCalculatorInstance.address, prediction[11])
    })

    it('1 success workflow', async () => {
      // initialize prediction with 10 AIX and 1 AIX fee
      // 3 output and first output is winner
      // participate 4 players
      // player1 - 10 AIX - 1 output
      //           5 AIX - 2 output

      // player2 - 7 AIX - 1 output
      // player3 - 4 AIX - 2 output
      // player4 - 80 AIX - 3 output

      const owner = accounts[0];
      const player1 = accounts[1];
      const player2 = accounts[2];
      const player3 = accounts[3];
      const player4 = accounts[4];

      const firstOutcomeId = Utils.getHex(1)
      const secondOutcomeId = Utils.getHex(2)
      const thirdOutcomeId = Utils.getHex(3)
        
      // Give tokens
      assert.equal(0, await testTokenInstance.balanceOf(player1))
      assert.equal(0, await testTokenInstance.balanceOf(player2))
      assert.equal(0, await testTokenInstance.balanceOf(player3))
      assert.equal(0, await testTokenInstance.balanceOf(player4))

      await testTokenInstance.transfer(player1, web3.toWei(15, 'ether')) 
      await testTokenInstance.transfer(player2, web3.toWei(7, 'ether')) 
      await testTokenInstance.transfer(player3, web3.toWei(4, 'ether')) 
      await testTokenInstance.transfer(player4, web3.toWei(80, 'ether')) 

      // Player1 forecasts
      const p1out1IdHex = Utils.getHex(1)
      const p1out2IdHex =  Utils.getHex(2)
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(10, 'ether'), firstOutcomeId +  predictionId.replace("0x", ""), {
          from: player1
      })
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(5, 'ether'), secondOutcomeId +  predictionId.replace("0x", ""), {
        from: player1
      })

      assert.equal(0, await testTokenInstance.balanceOf(player1))
      //assert.equal(web3.toWei(25, 'ether'), await testTokenInstance.balanceOf(marketInstance.address))

      // Player2 forecasts
      const p2out1IdHex = Utils.getHex(3)
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(7, 'ether'), firstOutcomeId + predictionId.replace("0x", ""), {
        from: player2
      })

      // Player3 forecasts
      const p3out1IdHex = Utils.getHex(4)
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(4, 'ether'), secondOutcomeId  + predictionId.replace("0x", ""), {
        from: player3
      })

      // Player4 forecasts
      const p4out1IdHex = Utils.getHex(5)
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(80, 'ether'), thirdOutcomeId  + predictionId.replace("0x", ""), {
        from: player4
      })
       

      assert.equal(web3.toWei(116, 'ether'), await testTokenInstance.balanceOf(marketInstance.address)) // total predictions forecast volume 116
 
      //Sleep to make prediction endTime < now
      await sleep(60)

      // Setting outcome and making prediction resolved
      await resultStorageInstance.setOutcome(predictionId, firstOutcomeId)
      await marketInstance.resolve(predictionId)

      // Paying out
      await marketInstance.payout(predictionId, p1out1IdHex)
      await marketInstance.payout(predictionId, p2out1IdHex)
      
      // ASSERT PREDICTION
      const prediction = await marketInstance.predictions.call(predictionId)
      //console.log(prediction)
      assert.equal(2, prediction[3].toNumber()) // Resolved
      assert.equal(1, prediction[5].toNumber()) // ResultOutcome = 1
      assert.equal(web3.toWei(5, 'ether'), await marketInstance.totalFeeCollected()) // 5 forecast with 1 aix
      assert.equal(web3.toWei(111, 'ether'), prediction[7].toNumber())// totalTokens 116 - 5 = 111
      assert.equal(5, prediction[8].toNumber()) // totalForecasts
      assert.equal(web3.toWei(111, 'ether'), prediction[9].toNumber())// totalTokensPaidout 
      assert.equal(web3.toWei(5, 'ether'), await testTokenInstance.balanceOf(marketInstance.address)) // total prediction left over

      // ASSERT OUTCOMES
      assert.equal(web3.toWei(15, 'ether'), (await marketInstance.getOutcome(predictionId,1))[3]) 
      assert.equal(web3.toWei(7, 'ether'), (await marketInstance.getOutcome(predictionId,2))[3]) 
      assert.equal(web3.toWei(79, 'ether'), (await marketInstance.getOutcome(predictionId,3))[3])

      // ASSERT FORECASTS
      // Player 1
      const p1f1Forecast = await marketInstance.getForecast(p1out1IdHex)
      assert.equal(p1f1Forecast[2], player1)  // user
      assert.equal(web3.toWei(9, 'ether'), p1f1Forecast[3].toNumber()) // amount
      assert.equal(1, p1f1Forecast[4].toNumber()) // 1 outcomeId
      assert.equal(web3.toWei(66.6, 'ether'), p1f1Forecast[5].toNumber())

      const p1f2Forecast = await marketInstance.getForecast(p1out2IdHex)
      assert.equal(p1f2Forecast[2], player1)  // user
      assert.equal(web3.toWei(4, 'ether'), p1f2Forecast[3].toNumber()) // amount
      assert.equal(2, p1f2Forecast[4].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p1f2Forecast[5].toNumber())

      assert.equal(web3.toWei(66.6, 'ether'), await testTokenInstance.balanceOf(player1))

      let userPrediction = await marketInstance.myForecasts.call(player1, 0)
      assert.equal(userPrediction.toNumber(), p1out1IdHex)

      userPrediction = await marketInstance.myForecasts.call(player1, 1)
      assert.equal(userPrediction.toNumber(), p1out2IdHex)

      // Player 2
      const p2f1Forecast = await marketInstance.getForecast(p2out1IdHex)
      assert.equal(p2f1Forecast[2], player2)  // user
      assert.equal(web3.toWei(6, 'ether'), p2f1Forecast[3].toNumber()) // amount
      assert.equal(1, p2f1Forecast[4].toNumber()) // outcomeId
      assert.equal(web3.toWei(44.4, 'ether'), p2f1Forecast[5].toNumber())

      assert.equal(web3.toWei(44.4, 'ether'), await testTokenInstance.balanceOf(player2))

      userPrediction = await marketInstance.myForecasts.call(player2, 0)
      assert.equal(userPrediction.toNumber(), p2out1IdHex)

      // Player 3
      const p3f1Forecast = await marketInstance.getForecast(p3out1IdHex)
      assert.equal(p3f1Forecast[2], player3)  // user
      assert.equal(web3.toWei(3, 'ether'), p3f1Forecast[3].toNumber()) // amount
      assert.equal(2, p3f1Forecast[4].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p3f1Forecast[5].toNumber())

      assert.equal(web3.toWei(0, 'ether'), await testTokenInstance.balanceOf(player3))

      userPrediction = await marketInstance.myForecasts.call(player3, 0)
      assert.equal(userPrediction.toNumber(), p3out1IdHex)

      // Player 4
      const p4f1Forecast = await marketInstance.getForecast(p4out1IdHex)
      assert.equal(p4f1Forecast[2], player4)  // user
      assert.equal(web3.toWei(79, 'ether'), p4f1Forecast[3].toNumber()) // amount
      assert.equal(3, p4f1Forecast[4].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p4f1Forecast[5].toNumber())

      assert.equal(web3.toWei(0, 'ether'), await testTokenInstance.balanceOf(player4))

      userPrediction = await marketInstance.myForecasts.call(player4, 0)
      assert.equal(userPrediction.toNumber(), p4out1IdHex)
      
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