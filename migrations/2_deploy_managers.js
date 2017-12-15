var ContractManager = artifacts.require("./ContractManager.sol");
var ProductManager = artifacts.require("./ProductManager.sol");
var EventEmmiter = artifacts.require("./EventEmitter.sol");

const abiEncoder = require('ethereumjs-abi');
const eventEmitterABI = require('../build/contracts/EventEmitter.json');
const contractManagerABI = require('../build/contracts/ContractManager.json')

module.exports = function(deployer) {
  	return deployer.deploy(EventEmmiter).then(async() => {
		const eventEmitter = await EventEmmiter.deployed();
		const encodeParamsEventEmitter = abiEncoder.rawEncode(['address'], [eventEmitter.address]);
		
		console.log('\n\n\nContract EventEmitter address:\n', eventEmitter.address);
		console.log('ENCODED PARAMS EventEmitter:\n', encodeParamsEventEmitter.toString('hex'));
		console.log('EventEmitter ABI:\n', JSON.stringify(eventEmitterABI));
		console.log('\n\n\n');

		await deployer.deploy(ContractManager, eventEmitter.address);
		const contractManager = await ContractManager.deployed();
		const encodeParamsContractManager = abiEncoder.rawEncode(['address'], [contractManager.address]);
		await eventEmitter.addExecutor(contractManager.address);
		contractManager.setContract("EventEmitter", eventEmitter.address);

		console.log('\n\n\nContractManager address:\n', contractManager.address);
		console.log('ENCODED PARAMS ContractManager:\n', encodeParamsContractManager.toString('hex'));
		console.log('ContractManager ABI:\n', JSON.stringify(contractManagerABI));
		console.log('\n\n\n');
		
	});
};