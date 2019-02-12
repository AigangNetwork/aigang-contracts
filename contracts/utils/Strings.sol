pragma solidity ^0.4.23;

library Strings {
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        if (bytes(_a).length != bytes(_b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
        }
    }

    function equalByBytes(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
       
        if (a.length != b.length) {
            return false;
        }
        
        for (uint i = 0; i < a.length; i ++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        
        return true;
    }
}