pragma solidity ^0.4.23;

interface IPremiumCalculator {
    function calculatePremium(
        uint _batteryDesignCapacity,
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel
    ) external view returns (uint);

    function validate(
        uint _batteryDesignCapacity, 
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel) 
            external 
            view 
            returns (bytes2);
    
    function isClaimable(string _batteryWearLevel
    ) external pure returns (bool);

    function getPayout(
    ) external view returns (uint);

    function getDetails(
    ) external view returns (uint, uint, uint);
}