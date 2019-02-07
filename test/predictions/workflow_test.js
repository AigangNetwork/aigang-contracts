const TestToken = artifacts.require('TestToken.sol')
const Market = artifacts.require('./predictions/Market.sol')
const PrizeCalculator = artifacts.require('./predictions/PrizeCalculator.sol')
const ResultStorage = artifacts.require('./predictions/ResultStorage.sol')

const BigNumber = web3.BigNumber
contract('Market', accounts => {

  let owner = accounts[0]
  let marketInstance
  let prizeCalculatorInstance
  let resultStorageInstance

  describe('#market', async () => {
    let predictionId = web3.fromAscii('18fda5cf3a7a4999e3400f4940126432') // result is hex 
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
        predictionId,
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      )

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

      const firstOutcomeId = 1
      var firstOutcomeIdHex = "0" + firstOutcomeId.toString(16)
      const secondOutcomeId = 2
      var secondOutcomeIdHex = "0" + secondOutcomeId.toString(16)
      const thirdOutcomeId = 3
      var thirdOutcomeIdHex = "0" + thirdOutcomeId.toString(16)
        
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
      const p1out1IdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed515')
      const p1out2IdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed516')
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(10, 'ether'), predictionId + p1out1IdHex.replace("0x", "") + firstOutcomeIdHex, {
          from: player1
      })
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(5, 'ether'), predictionId + p1out2IdHex.replace("0x", "") + secondOutcomeIdHex, {
        from: player1
      })

      assert.equal(0, await testTokenInstance.balanceOf(player1))
      //assert.equal(web3.toWei(25, 'ether'), await testTokenInstance.balanceOf(marketInstance.address))

      // Player2 forecasts
      const p2out1IdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed517')
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(7, 'ether'), predictionId + p2out1IdHex.replace("0x", "") + firstOutcomeIdHex, {
        from: player2
      })

      // Player3 forecasts
      const p3out1IdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed518')
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(4, 'ether'), predictionId + p3out1IdHex.replace("0x", "") + secondOutcomeIdHex, {
        from: player3
      })

      // Player4 forecasts
      const p4out1IdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed519')
      await testTokenInstance.approveAndCall(marketInstance.address, web3.toWei(80, 'ether'), predictionId + p4out1IdHex.replace("0x", "") + thirdOutcomeIdHex, {
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
      assert.equal(web3.toWei(15, 'ether'), await marketInstance.getOutcomeTokens(predictionId,1)) 
      assert.equal(web3.toWei(7, 'ether'), await marketInstance.getOutcomeTokens(predictionId,2)) 
      assert.equal(web3.toWei(79, 'ether'), await marketInstance.getOutcomeTokens(predictionId,3))

      // ASSERT FORECASTS
      // Player 1
      const p1f1Forecast = await marketInstance.getForecast(predictionId, p1out1IdHex)
      assert.equal(p1f1Forecast[0], player1)  // user
      assert.equal(web3.toWei(9, 'ether'), p1f1Forecast[1].toNumber()) // amount
      assert.equal(1, p1f1Forecast[2].toNumber()) // 1 outcomeId
      assert.equal(web3.toWei(66.6, 'ether'), p1f1Forecast[3].toNumber())

      const p1f2Forecast = await marketInstance.getForecast(predictionId, p1out2IdHex)
      assert.equal(p1f2Forecast[0], player1)  // user
      assert.equal(web3.toWei(4, 'ether'), p1f2Forecast[1].toNumber()) // amount
      assert.equal(2, p1f2Forecast[2].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p1f2Forecast[3].toNumber())

      assert.equal(web3.toWei(66.6, 'ether'), await testTokenInstance.balanceOf(player1))

      let userPrediction = await marketInstance.walletPredictions.call(player1, 0)
      assert.equal(userPrediction[0], predictionId)  // user
      assert.equal(userPrediction[1], p1out1IdHex)
 
      userPrediction = await marketInstance.walletPredictions.call(player1, 1)
      assert.equal(userPrediction[0], predictionId)  // user
      assert.equal(userPrediction[1], p1out2IdHex)
      
      //console.log(`pr ${userPredictions}`)

      // Player 2
      const p2f1Forecast = await marketInstance.getForecast(predictionId, p2out1IdHex)
      assert.equal(p2f1Forecast[0], player2)  // user
      assert.equal(web3.toWei(6, 'ether'), p2f1Forecast[1].toNumber()) // amount
      assert.equal(1, p2f1Forecast[2].toNumber()) // outcomeId
      assert.equal(web3.toWei(44.4, 'ether'), p2f1Forecast[3].toNumber())

      assert.equal(web3.toWei(44.4, 'ether'), await testTokenInstance.balanceOf(player2))

      userPrediction = await marketInstance.walletPredictions.call(player2, 0)
      assert.equal(userPrediction[0], predictionId)  // user
      assert.equal(userPrediction[1], p2out1IdHex)

      // Player 3
      const p3f1Forecast = await marketInstance.getForecast(predictionId, p3out1IdHex)
      assert.equal(p3f1Forecast[0], player3)  // user
      assert.equal(web3.toWei(3, 'ether'), p3f1Forecast[1].toNumber()) // amount
      assert.equal(2, p3f1Forecast[2].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p3f1Forecast[3].toNumber())

      assert.equal(web3.toWei(0, 'ether'), await testTokenInstance.balanceOf(player3))

      userPrediction = await marketInstance.walletPredictions.call(player3, 0)
      assert.equal(userPrediction[0], predictionId)  // user
      assert.equal(userPrediction[1], p3out1IdHex)

      // Player 4
      const p4f1Forecast = await marketInstance.getForecast(predictionId, p4out1IdHex)
      assert.equal(p4f1Forecast[0], player4)  // user
      assert.equal(web3.toWei(79, 'ether'), p4f1Forecast[1].toNumber()) // amount
      assert.equal(3, p4f1Forecast[2].toNumber()) // outcomeId
      assert.equal(web3.toWei(0, 'ether'), p4f1Forecast[3].toNumber())

      assert.equal(web3.toWei(0, 'ether'), await testTokenInstance.balanceOf(player4))

      userPrediction = await marketInstance.walletPredictions.call(player4, 0)
      assert.equal(userPrediction[0], predictionId)  // user
      assert.equal(userPrediction[1], p4out1IdHex)
      
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