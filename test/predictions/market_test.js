const TestToken = artifacts.require('TestToken.sol');
const Market = artifacts.require('./predictions/Market.sol');
const PrizeCalculator = artifacts.require('./predictions/PrizeCalculator.sol');
const ResultStorage = artifacts.require('./predictions/ResultStorage.sol');

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

      id = web3.toAscii('18fda5cf3a7a4bc999e3400f49401266');
      const endTime = Date.now() + 60;
      const startTime = new Date().getTime() / 1000 - 2;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = 1000;

      await marketInstance.addPrediction(
        id,
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );
    });

    it('add prediction', async () => {
      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(1, predictionStatus);
    });

    it('change prediction status', async () => {
      await marketInstance.changePredictionStatus(id, 3);

      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(3, predictionStatus);
    });

    it('cancel prediction', async () => {
      await marketInstance.changePredictionStatus(id,4); 

      const prediction = await marketInstance.predictions.call(id);
      const predictionStatus = prediction[3].toNumber();

      assert.equal(4, predictionStatus);
    });

    it('resolve prediction', async () => {
      const id = 1342;
      const endTime = new Date().getTime() / 1000 - 1000;
      const startTime = Date.now() - 1;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = 1000;

      await marketInstance.addPrediction(
        id,
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
      const id = web3.fromAscii('18fda5cf3a7a4999e3400f4940126432'); // result is hex 
      const endTime = new Date().getTime() / 1000 + 2;
      const startTime = new Date().getTime() / 1000 - 2;
      const feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 2;
      const totalTokens = web3.toWei(0, 'ether');

      await marketInstance.addPrediction(
        id,
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      // Adding two forecasts
      const firstAmount = web3.toWei(112, 'ether');
      const firstOutcomeId = 1;

      var firstOutcomeIdHex = firstOutcomeId.toString(16);
      if (firstOutcomeIdHex.length === 1) {
        firstOutcomeIdHex = "0" + firstOutcomeIdHex;
      }

      const secondAmount = web3.toWei(62, 'ether');
      const secondOutcomeId = 2;

      var secondOutcomeIdHex = secondOutcomeId.toString(16);
      if (secondOutcomeIdHex.length === 1) {
        secondOutcomeIdHex = "0" + secondOutcomeIdHex;
      }

      const firstIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
      const secondIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed516');

      await testTokenInstance.transfer(marketInstance.address, totalTokens);
      await testTokenInstance.transfer(accounts[1], firstAmount);

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, id + firstIdHex.replace("0x", "") + firstOutcomeIdHex, {
        from: accounts[1]
      });
      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, id + secondIdHex.replace("0x", "") + secondOutcomeIdHex);


      // Sleep to make prediction endTime < now
      await sleep(3000);

      // Setting outcome and making prediction resolved
      await resultStorageInstance.setOutcome(id, firstOutcomeId);
      await marketInstance.resolve(id);

      // Paying out
      await marketInstance.payout(id, firstIdHex);

      const forecast = await marketInstance.getForecast(id, firstIdHex);
      //console.log(`forecast: ${forecast}`)
      assert(forecast[3].toNumber() != 0, 'Paid sum is 0');
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
      predictionId = web3.fromAscii('18fda5cf3a7a4999e3400f4940126432'); // result is hex 
      const endTime = Date.now() + 60;
      const startTime = new Date().getTime() / 1000 - 2;
      feeInWeis = web3.toWei(12, 'ether');
      const outcomesCount = 4;
      const totalTokens = web3.toWei(1000, 'ether');

      await marketInstance.addPrediction(
        predictionId,
        endTime,
        startTime,
        feeInWeis,
        outcomesCount,
        totalTokens,
        resultStorageInstance.address,
        prizeCalculatorInstance.address
      );

      await testTokenInstance.transfer(marketInstance.address, totalTokens);
    });

    it('create forecast', async () => {
      const firstAmount = web3.toWei(100, 'ether');
      const firstOutcomeId = 1;
      var firstOutcomeIdHex = firstOutcomeId.toString(16);
      if (firstOutcomeIdHex.length === 1) {
        firstOutcomeIdHex = "0" + firstOutcomeIdHex;
      }

      const secondAmount = web3.toWei(75, 'ether');
      const secondOutcomeId = 2;
      var secondOutcomeIdHex = secondOutcomeId.toString(16);
      if (secondOutcomeIdHex.length === 1) {
        secondOutcomeIdHex = "0" + secondOutcomeIdHex;
      }

      const firstIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
      const secondIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed516');

      await testTokenInstance.transfer(accounts[3], web3.toWei(75, 'ether')); // give tokens to account 3

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, predictionId + firstIdHex.replace("0x", "") + firstOutcomeIdHex);
      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, predictionId + secondIdHex.replace("0x", "") + secondOutcomeIdHex, {
        from: accounts[3]
      });

      const firstForecast = await marketInstance.getForecast(predictionId, firstIdHex);
      const secondForecast = await marketInstance.getForecast(predictionId, secondIdHex);

      assert.equal(firstForecast[0], owner);
      assert.equal(firstForecast[1].toNumber(), firstAmount - feeInWeis);
      assert.equal(secondForecast[1].toNumber(), secondAmount - feeInWeis);
    });

    it('refund forecast', async () => {
      // Adding two forecast
      const firstAmount = web3.toWei(112, 'ether');
      const firstOutcomeId = 1;

      var firstOutcomeIdHex = firstOutcomeId.toString(16);
      if (firstOutcomeIdHex.length === 1) {
        firstOutcomeIdHex = "0" + firstOutcomeIdHex;
      }

      const secondAmount = web3.toWei(62, 'ether');
      const secondOutcomeId = 2;

      var secondOutcomeIdHex = secondOutcomeId.toString(16);
      if (secondOutcomeIdHex.length === 1) {
        secondOutcomeIdHex = "0" + secondOutcomeIdHex;
      }

      const firstIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed515');
      const secondIdHex = web3.fromAscii('0a883323f9d84b449c911ac5486ed516');

      await testTokenInstance.transfer(accounts[3], web3.toWei(113, 'ether'));

      await testTokenInstance.approveAndCall(marketInstance.address, firstAmount, predictionId + firstIdHex.replace("0x", "") + firstOutcomeIdHex, {
        from: accounts[3]
      });

      await testTokenInstance.approveAndCall(marketInstance.address, secondAmount, predictionId + secondIdHex.replace("0x", "") + secondOutcomeIdHex);

      await marketInstance.changePredictionStatus(predictionId,4); 
      await marketInstance.refund(predictionId, firstIdHex);

      const forecast = await marketInstance.getForecast(predictionId, firstIdHex);

      assert.equal(forecast[3].toNumber(), firstAmount - feeInWeis);
    });
  });

  // TODO: Unit test withdraw ETH and WithdrawTokens
});

const sleep = milliseconds => {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve();
    }, milliseconds);
  });
};