pragma solidity ^0.4.15;

library Strings {
    function toAsciiString(address x) public returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function toBytes(address x) public returns (bytes b) {
        b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        }
    }

    function char(byte b) public constant returns (byte c) {
        if (b < 10) 
        return byte(uint8(b) + 0x30);
        else 
        return byte(uint8(b) + 0x57);
    }
}