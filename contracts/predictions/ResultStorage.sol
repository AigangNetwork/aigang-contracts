pragma solidity ^0.4.23;

import "./../utils/OwnedWithExecutor.sol";
import "./../interfaces/IERC20.sol";
import "./../interfaces/IResultStorage.sol";

contract ResultStorage is Owned, IResultStorage {

    event ResultAssigned(bytes32 indexed _predictionId, uint8 _outcomeId);
    event Withdraw(uint _amount);

    struct Result {     
        uint8 outcomeId;
        bool resolved; 
    }

    uint8 public constant version = 1;
    bool public paused;
    mapping(bytes32 => Result) public results;  

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier resolved(bytes32 _predictionId) {
        require(results[_predictionId].resolved == true, "Prediction is not resolved");
        _;
    }
 
    function setOutcome (bytes32 _predictionId, uint8 _outcomeId)
            public 
            onlyAllowed
            notPaused {        
        
        results[_predictionId].outcomeId = _outcomeId;
        results[_predictionId].resolved = true;
        
        emit ResultAssigned(_predictionId, _outcomeId);
    }

    function getResult(bytes32 _predictionId) 
            public 
            view 
            resolved(_predictionId)
            returns (uint8) {
        return results[_predictionId].outcomeId;
    }

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        assert(IERC20(_token).transfer(owner, _amount));
        emit Withdraw(_amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }
}