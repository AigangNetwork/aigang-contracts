const EventEmitter = artifacts.require("./EventEmitter.sol");
const assert = require("chai").assert;

contract("EventEmmiter", function(accounts) {
    let eventEmitter;
    beforeEach(async function(){
      eventEmitter = await EventEmitter.deployed();
    })

    describe("Testing INFO events:", function(){
      it("Calling info(string)", function(done) {
        var InfoMessage = 'TestingWithOneParam';
          eventEmitter.info(InfoMessage).then(function(result) {
              assert.equal(result.logs[0].event, 'Info', "Event must be INFO!");
              assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), InfoMessage, `Info message does not match with ${InfoMessage}`);
          }).then(done).catch(done);
      });

      it("Calling info2(string, _param:string)", function(done){
        var InfoMessage = "TestingWithTwoParams";
        var Param = "ParamNo0";
        eventEmitter.info2(InfoMessage, Param).then(function(result){
          assert.equal(result.logs[0].event, 'Info', "Event must be INFO!");
          
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), InfoMessage, `Info message does not match with ${InfoMessage}`);
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._param).replace(/\u0000/g, ''), Param, `Info message does not match with ${Param}`)

        }).then(done).catch(done);;
      })
    });

    describe("Testing WARNING events:", function(){
      it("Calling warning(string)", function(done){
        var warningMessage = "Warning!";
        eventEmitter.warning(warningMessage).then(function(result) {
            assert.equal(result.logs[0].event, 'Warning', "Event must be Warning!");
            assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), warningMessage, `Warning message does not match with ${warningMessage}`);
        }).then(done).catch(done);
      });

      it("Calling warning2(string, params:string", (done) => {
        var warningMessage = "Warning2";
        var params = "Param02";
        eventEmitter.warning2(warningMessage, params).then(function(result) {
          assert.equal(result.logs[0].event, 'Warning', "Event must be Warning!");
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), warningMessage, `Warning message does not match with ${warningMessage}`);
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._param).replace(/\u0000/g, ''), params, `Warning message does not match with ${params}`);
        }).then(done).catch(done);
      });
    });
    
    
    describe("Testing ERROR events:", function(){
      it("Calling error(string)", function(done){
        var errorMessage = "Error!";
        eventEmitter.error(errorMessage).then(function(result) {
            assert.equal(result.logs[0].event, 'Error', "Event must be Error!");
            assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), errorMessage, `Error message does not match with ${errorMessage}`);
        }).then(done).catch(done);
      });

      it("Calling error2(string, params:string)", (done) => {
        var errorMessage = "Error2";
        var params = "Param03";
        eventEmitter.error2(errorMessage, params).then(function(result) {
          assert.equal(result.logs[0].event, 'Error', "Event must be Error!");
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._msg).replace(/\u0000/g, ''), errorMessage, `Error message does not match with ${errorMessage}`);
          assert.equal(web3._extend.utils.toAscii(result.logs[0].args._param).replace(/\u0000/g, ''), params, `Error message does not match with ${params}`);
        }).then(done).catch(done);
      });
    });



  });