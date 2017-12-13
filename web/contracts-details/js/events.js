const Web3 = require('web3')


//const etherscanAddress = 'https://etherscan.io/'

const web3ProviderAddress = 'https://ropsten.infura.io'
const eventEmitterAddress = '0xaf13bf2a191459d731f99e5e72393dc80f947f03'; 


var contract_eventEmitter


function errorHappened (err) {
  if (err != null) {
    console.log(err)
    alert('There was an error fetching contract.')
    return true
  }
}

function fillform () {
  App.fillBlock()
  App.fillEvents()
}

window.App = {
  start: function () {
    var self = this


    let abi_eventEmitter = JSON.parse(
      '[{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transfer2Ownership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"},{"name":"param","type":"bytes32"}],"name":"warning","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"executor","type":"address"}],"name":"addExecutor","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"executor","type":"address"}],"name":"removeExecutor","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"executorsCount","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner2","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"canExecute","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"}],"name":"info","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"}],"name":"warning","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"}],"name":"error","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"},{"name":"param","type":"bytes32"}],"name":"info","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"message","type":"bytes32"},{"name":"param","type":"bytes32"}],"name":"error","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"msg","type":"bytes32"},{"indexed":false,"name":"param","type":"bytes32"}],"name":"Info","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"msg","type":"bytes32"},{"indexed":false,"name":"param","type":"bytes32"}],"name":"Warning","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"msg","type":"bytes32"},{"indexed":false,"name":"param","type":"bytes32"}],"name":"Error","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_address","type":"address"}],"name":"AddedExecutor","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_address","type":"address"}],"name":"RemovedExecutor","type":"event"}]'
    )


    let abi_eventEmitter_instance = web3.eth.contract(abi_eventEmitter)
    contract_eventEmitter = abi_eventEmitter_instance.at(eventEmitterAddress)

  
    fillform()
  },

  fillBlock: function () {
    web3.eth.getBlockNumber(function (err, value) {
      if (errorHappened(err)) {
        return
      }
      $('#blockId').html(
        value +
          `&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ${web3ProviderAddress}  (Works only with MetaMask!!)`
      )

      web3.eth.getBlock(value, function (err, value) {
        if (errorHappened(err)) {
          return
        }
        let date = new Date(value.timestamp * 1000)
        $('#time').html(date.toISOString())
      })
    })
  },

  fillEvents: function () {

    contract_eventEmitter.Info({}, {fromBlock: 0, toBlock: 'latest'}).get((error, logs) => {
      
      //logs.forEach(log => console.log(log.args))
      //console.log(error)
   
      $('#tblInfo tr').not(':first').not(':last').remove();
      var html = '<tr > <td>Block</td> <td>Sender</td> <td>msg</td> <td>param</td> </tr>';
      for(var i = 0; i < logs.length; i++)
                  html += '<tr><td>' +  logs[i].blockNumber.toString() + '	&nbsp;	&nbsp;' + 
                          '</td><td>' + logs[i].args.sender.toString() +  '	&nbsp;	&nbsp;' +   
                          '</td><td>' + web3.toAscii(logs[i].args.msg) + '	&nbsp;	&nbsp;' + 
                          '</td><td>' + logs[i].args.param.toString()  + '</td></tr>';
      $('#tblInfo tr').first().after(html);
    })


    contract_eventEmitter.Warning({}, {fromBlock: 0, toBlock: 'latest'}).get((error, logs) => {
   
      $('#tblWarrning tr').not(':first').not(':last').remove();
      var html = '<tr > <td>Block</td> <td>Sender</td> <td>msg</td> <td>param</td> </tr>';
      for(var i = 0; i < logs.length; i++)
                html += '<tr><td>' +  logs[i].blockNumber.toString() + '	&nbsp;	&nbsp;' + 
                        '</td><td>' + logs[i].args.sender.toString() +  '	&nbsp;	&nbsp;' +   
                        '</td><td>' + web3.toAscii(logs[i].args.msg) + '	&nbsp;	&nbsp;' + 
                        '</td><td>' + logs[i].args.param.toString()  + '</td></tr>';
      $('#tblWarrning tr').first().after(html);
    })




    contract_eventEmitter.Error({}, {fromBlock: 0, toBlock: 'latest'}).get((error, logs) => {
      
      $('#tblError tr').not(':first').not(':last').remove();
      var html = '<tr> <td>Block</td> <td>Sender</td> <td>msg</td> <td>param</td> </tr>';
      for(var i = 0; i < logs.length; i++)
                html += '<tr><td>' +  logs[i].blockNumber.toString() + '	&nbsp;	&nbsp;' + 
                        '</td><td>' + logs[i].args.sender.toString() +  '	&nbsp;	&nbsp;' +   
                        '</td><td>' + web3.toAscii(logs[i].args.msg) + '	&nbsp;	&nbsp;' + 
                        '</td><td>' + logs[i].args.param.toString()  + '</td></tr>';
      $('#tblError tr').first().after(html);
    })

    var events = contract_eventEmitter.allEvents(function(error, log){
      if (!error)
        console.log(log);
    });
  
  }




}

window.addEventListener('load', function () {
//  window.web3 = new Web3(new Web3.providers.HttpProvider(web3ProviderAddress))
//   App.start()

 "undefined" != typeof web3 ? (window.web3 = new Web3(web3.currentProvider),
    web3.version.getNetwork(function(t, e) {
        "3" == e ? App.start() : (console.log(t), // works only with metamask and ropsten testnet
        console.log('nowallet'))
    })) : console.log('nowallet2')

})

