const TestToken = artifacts.require('TestToken.sol');
const Market = artifacts.require('./predictions/Market.sol');
const PrizeCalculator = artifacts.require('./predictions/PrizeCalculator.sol');
const ResultStorage = artifacts.require('./predictions/ResultStorage.sol');
const Utils = require('../utils.js');

const BigNumber = web3.BigNumber;
contract('Market', accounts => {

  let owner = accounts[0];
  let marketInstance;
  let prizeCalculatorInstance;
  let resultStorageInstance;
  let testTokenInstance;

  describe('#prediction', async () => {
    let id;
    beforeEach(async () => {
      marketInstance = await Market.new();
      prizeCalculatorInstance = await PrizeCalculator.new();
      resultStorageInstance = await ResultStorage.new();
      testTokenInstance = await TestToken.new();

      await marketInstance.initialize(testTokenInstance.address);

      id = 1;
      const endTime = Date.now() + 60;
      const startTime = new Date().getTime() / 1000 - 2;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = 1000;

      await marketInstance.addPrediction(
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      await marketInstance.changePredictionStatus(1,1)
    });

    it('add prediction', async () => {
      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(1, predictionStatus);

      // Details
      let title = "Test Title"
      let description = "TEST Description"
      await marketInstance.updateDescriptions(id,title,description);

      let details = await marketInstance.getDetails(id);

      assert.equal(title, details[0]);
      assert.equal(description, details[1]);
      
      // Outcomes
      title = "Outcome Title"
      let value = ">1"
      await marketInstance.updateOutcome(id,1,title,value);
      await marketInstance.updateOutcome(id,2,title + "2",value+"2");

      let outcome1 = await marketInstance.getOutcome(id,1);
      assert.equal(1, outcome1[0].toNumber());
      assert.equal(title, outcome1[1]);
      assert.equal(value, outcome1[2]);

      let outcome2 = await marketInstance.getOutcome(id,2);
      assert.equal(2, outcome2[0].toNumber());
    });

    it('change prediction status', async () => {
      await marketInstance.changePredictionStatus(id, 3);

      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(3, predictionStatus);
    });

    it('update addresses', async () => {
      let address = '0x49904b161ac375d8709cadd9595666ea0f4c1169'
      await marketInstance.updateAddresses(id, address,address);

      const prediction = await marketInstance.predictions.call(id);
      const resultStorage = prediction[10];
      const prizeCalculator = prediction[11];

      assert.equal(address, resultStorage);
      assert.equal(address, prizeCalculator);
    });

    it('update Descriptions', async () => {
      let testTitle = 'Test Title'
      let testDescription = 'Test Description'
      await marketInstance.updateDescriptions(id, testTitle, testDescription);

      const prediction = await marketInstance.getDetails(id);
      const title = prediction[0];
      const description = prediction[1];

      assert.equal(testTitle, title);
      assert.equal(testDescription, description);
    });

    it('update Data', async () => {
      await marketInstance.updateData(id, 
        0,
        1,
        2,
        4,
        6,
        7);

      const prediction = await marketInstance.predictions.call(id);

      assert.equal(0, prediction[0].toNumber()); // _forecastEndUtc,
      assert.equal(1, prediction[1].toNumber()); // _forecastStartUtc,
      assert.equal(2, prediction[2].toNumber()); // _fee, 
      assert.equal(4, prediction[4].toNumber()); // _outcomesCount,
      assert.equal(6, prediction[6].toNumber()); // _initialTokens,
      assert.equal(7, prediction[7].toNumber());// _totalTokens
    });

    it('cancel prediction', async () => {
      await marketInstance.changePredictionStatus(id,4); 

      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(4, predictionStatus);
    });

    it('resolve prediction', async () => {
      const id = 1;
      const endTime = new Date().getTime() / 1000 - 1000;
      const startTime = Date.now() - 1;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = 1000;

      await marketInstance.addPrediction(
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      const outcomeId = 1;
      await resultStorageInstance.setOutcome(id, outcomeId);
      await marketInstance.resolve(id);

      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(2, predictionStatus);
    });

    it('payout prediction', async () => {
      // Creating prediction
      const id = Utils.getHex(2); 
      const endTime = new Date().getTime() / 1000 + 2;
      const startTime = new Date().getTime() / 1000 - 2;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = web3.toWei(0, 'ether');

      await marketInstance.addPrediction(
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      await marketInstance.changePredictionStatus(2,1)

      // Adding two forecasts
      const firstAmount = web3.toWei(112, 'ether');
      const firstOutcomeId = 1;

      const secondAmount = web3.toWei(62, 'ether');
      const secondOutcomeId = 2;

      const firstIdHex = Utils.getHex(1);
      const secondIdHex = Utils.getHex(2);

      await testTokenInstance.transfer(marketInstance.address, totalTokens);
      await testTokenInstance.transfer(accounts[1], firstAmount);

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, firstIdHex + id.replace("0x",""), {
        from: accounts[1]
      });
      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, secondIdHex + id.replace("0x",""));


      // Sleep to make prediction endTime < now
      await sleep(3000);

      // Setting outcome and making prediction resolved
      await resultStorageInstance.setOutcome(id, firstOutcomeId);
      await marketInstance.resolve(id);

      // Paying out
      await marketInstance.payout(id, firstIdHex);

      const forecast = await marketInstance.getForecast(firstIdHex);
      //console.log(`forecast: ${forecast}`)
      assert(forecast[5].toNumber() != 0, 'Paid sum is 0');
    });
  });

  describe('#forecast', async () => {
    let predictionId;
    let feeInWeis;

    beforeEach(async () => {
      marketInstance = await Market.new();
      prizeCalculatorInstance = await PrizeCalculator.new();
      resultStorageInstance = await ResultStorage.new();
      testTokenInstance = await TestToken.new();

      await marketInstance.initialize(testTokenInstance.address);
      predictionId = Utils.getHex(1);
      const endTime = Date.now() + 60;
      const startTime = new Date().getTime() / 1000 - 2;
      feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 4;
      const totalTokens = web3.toWei(1000, 'ether');

      await marketInstance.addPrediction(
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      await marketInstance.changePredictionStatus(1,1)

      await testTokenInstance.transfer(marketInstance.address, totalTokens);
    });

    it('create forecast', async () => {
      const firstAmount = web3.toWei(100, 'ether');
      const firstOutcomeId = 1;
      var firstOutcomeIdHex = Utils.getHex(firstOutcomeId);

      const secondAmount = web3.toWei(75, 'ether');
      const secondOutcomeId = 2;
      var secondOutcomeIdHex = Utils.getHex(secondOutcomeId);

      await testTokenInstance.transfer(accounts[3], web3.toWei(75, 'ether')); // give tokens to account 3

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, firstOutcomeIdHex + predictionId.replace("0x", ""));
      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, secondOutcomeIdHex + predictionId.replace("0x", ""), {
        from: accounts[3]
      });

      const firstForecast = await marketInstance.getForecast(firstOutcomeId);
      const secondForecast = await marketInstance.getForecast(secondOutcomeId);

      assert.equal(firstForecast[2], owner);
      assert.equal(firstForecast[3].toNumber(), firstAmount - feeInWeis);
      assert.equal(firstForecast[6].toNumber()>0, true); // Created
      assert.equal(secondForecast[3].toNumber(), secondAmount - feeInWeis);

      var myForecastsLength = await marketInstance.getMyForecastsLength({
        from: accounts[3]
      });
      assert.equal(myForecastsLength.toNumber(), 1);

      var predictionForecastsLength = await marketInstance.getPredictionForecastsLength(predictionId);
      assert.equal(predictionForecastsLength.toNumber(), 2);

      var predictionForecasId = await marketInstance.getPredictionForecast(predictionId,1);
      assert.equal(predictionForecasId.toNumber(), 2);

    });

    it('refund forecast', async () => {
      // Adding two forecast
      const firstAmount = web3.toWei(112, 'ether');
      const firstOutcomeId = 1;
      var firstOutcomeIdHex = Utils.getHex(firstOutcomeId);

      const secondAmount = web3.toWei(62, 'ether');
      const secondOutcomeId = 2;
      var secondOutcomeIdHex = Utils.getHex(secondOutcomeId);

      await testTokenInstance.transfer(accounts[3], web3.toWei(113, 'ether'));

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, firstOutcomeIdHex + predictionId.replace("0x", ""), {
        from: accounts[3]
      });

      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, secondOutcomeIdHex + predictionId.replace("0x", ""));

      await marketInstance.changePredictionStatus(predictionId,4); 
      await marketInstance.refund(firstOutcomeIdHex, predictionId);

      const forecast = await marketInstance.getForecast(firstOutcomeIdHex);

      assert.equal(forecast[5].toNumber(), firstAmount - feeInWeis);
    })
  })

  

  // TODO: Unit test withdraw ETH and WithdrawTokens
})

const sleep = milliseconds => {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve();
    }, milliseconds);
  })
}