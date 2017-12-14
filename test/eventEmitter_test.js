const EventEmitter = artifacts.require("./EventEmitter.sol");
const assert = require("chai").assert;

contract("EventEmmiter", function(accounts) {
    let eventEmitter;
    beforeEach(async function(){
      eventEmitter = await EventEmitter.deployed();
    })

    describe("Testing INFO event call:", function(){
      it("it should call info(string)", function(done) {
        var InfoMessage = "TestingWithOneParam";
          eventEmitter.info(InfoMessage).then(function(result) {
              assert(result.logs[0].event, 'Info', "Event must be INFO!");
              assert(web3._extend.utils.toAscii(result.logs[0].args._msg), InfoMessage, `Info message does not match with ${InfoMessage}`);
          }).then(done).catch(done);
      });

      it("it should call info2(string, _param:string)", function(done){
        var InfoMessage = "TestingWithTwoParams";
        var Param = "ParamNo0";
        eventEmitter.info2(InfoMessage, Param).then(function(result){
          // console.log(result.logs[0].args);
          assert(result.logs[0].event, 'Info', "Event must be INFO!");
          assert(web3._extend.utils.toAscii(result.logs[0].args._msg), InfoMessage, `Info message does not match with ${InfoMessage}`);
          assert(web3._extend.utils.toAscii(result.logs[0].args._param), Param, `Info message does not match with ${Param}`)

        }).then(done).catch(done);;
      })
    });

    describe("")


  });