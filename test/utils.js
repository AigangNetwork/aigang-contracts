
  module.exports.getHex = function(x) {
  var result = web3.toHex(x)

  if(result.length % 2 == 1) {
    // bug https://github.com/ethereum/web3.js/issues/873
    result = result.replace("0x","0x0")
  }
  return result;
}