pragma solidity ^0.4.13;

contract ERC20 {
  /// @notice Send `_amount` tokens to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _amount The amount of tokens to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _amount) public returns (bool success);

  /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
  ///  is approved by `_from`
  /// @param _from The address holding the tokens being transferred
  /// @param _to The address of the recipient
  /// @param _amount The amount of tokens to be transferred
  /// @return True if the transfer was successful
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

  /// @param _owner The address that's balance is being requested
  /// @return The balance of `_owner` at the current block
  function balanceOf(address _owner) constant public returns (uint256 balance);

  /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
  ///  its behalf. This is a modified version of the ERC20 approve function
  ///  to be a little bit safer
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _amount The amount of tokens to be approved for transfer
  /// @return True if the approval was successful
  function approve(address _spender, uint256 _amount) public returns (bool success);

  /// @dev This function makes it easy to read the `allowed[]` map
  /// @param _owner The address of the account that owns the token
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens of _owner that _spender is allowed
  ///  to spend
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
  ///  its behalf, and then a function is triggered in the contract that is
  ///  being approved, `_spender`. This allows users to use their tokens to
  ///  interact with contracts in one function call instead of two
  /// @param _spender The address of the contract able to transfer the tokens
  /// @param _amount The amount of tokens to be approved for transfer
  /// @return True if the function call was successful
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData
  ) public returns (bool success);

  /// @dev This function makes it easy to get the total number of tokens
  /// @return The total number of tokens
  function totalSupply() public constant returns (uint);
}

contract Ownable {
  address public owner;
  address public owner2;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender != address(0) && (msg.sender == owner || msg.sender == owner2)); //TODO: test
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
  //TODO: TEST
  function transfer2Ownership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner2 = newOwner;
  }
}

contract IInvestmentManager { 

  // ----- Investment logic
  function invest(address _th) payable public returns (bool);
  // function isInvestmentPeriodEnded() constant public returns (bool);
  // function checkAvailableDividends() constant public returns (uint);
  // function transferDividends() public returns (bool);
  // function calculateDividends() constant public returns (uint);
  // function getFreeBalance() private returns (int);
  // function getInvestorProportion() private returns (uint);

   function available(address _tx) public constant returns (bool);
}

contract InvestmentManager is Ownable, IInvestmentManager {
    IWallet public wallet;
    IEventEmitter public logger;
    IContractManager public contractsManager;
    address public insuranceProduct;

    mapping (address => uint) public investors;
    uint public totalInvestorsCount;
    uint public totalInvestedAmount;

    uint public maxPayout;
    uint public investmentsLimit;
    uint32 public investmentsDeadlineTimeStamp;    

    uint8 constant DECIMAL_PRECISION = 8;
    uint24 constant ALLOWED_RETURN_INTERVAL_SEC = 24 * 60 * 60; // each 24 hours

    modifier onlyInsuranceProduct() {
        require(msg.sender == insuranceProduct);
        _;
    }

    function InvestmentManager(address _contractsManager, address _wallet, address _insuranceProduct) public {
        refreshDependencies(_contractsManager, _wallet, _insuranceProduct);

        maxPayout = 10 finney;   // 0.01 ETH
        investmentsLimit = 1000 ether; //1000 ETH
        investmentsDeadlineTimeStamp = uint32(now) + 90 days;
    }

    function invest(address _th) payable public onlyInsuranceProduct returns (bool) {
        require(msg.value > 0);
        require(!isInvestmentPeriodEnded());

        investors[_th] = investors[_th] + msg.value;
        totalInvestorsCount++;
        totalInvestedAmount = totalInvestedAmount + msg.value;

        wallet.deposit(msg.value);  
        logger.info2("[InvM]Invested", bytes32(_th));
        return true;  
    }

    function isInvestmentPeriodEnded() constant public returns (bool) {
        return (investmentsDeadlineTimeStamp < now);
    }


    /////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {      
            msg.sender.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);

        token.transfer(msg.sender, balance);
        logger.info2("Tokens are claimed", bytes32(msg.sender));
    }

    /// @notice By default this contract should not accept ethers
    function() payable public {
        require(false);
    }

    function refreshDependencies(address _contractsManager, address _wallet, address _insuranceProduct) public onlyOwner {
        contractsManager = IContractManager(_contractsManager);
        logger = IEventEmitter(contractsManager.getContract("EventEmitter"));
        wallet = IWallet(_wallet);
        insuranceProduct = _insuranceProduct;
    }

    function available(address _tx) public constant returns (bool) {
       return _tx == insuranceProduct;
    }

    function selfCheck() constant public onlyOwner returns (bool) {
        require(contractsManager.available());
        require(contractsManager.getContract("EventEmitter") != address(0));

        require(logger.available(this));
        require(wallet.available(this));

        return(true);
    }
}

contract IWallet {
    function deposit(uint value) public payable;
    function withdraw(address _th, uint value) public;

    function available(address _tx) public constant returns (bool);
}

contract IContractManager {
	function getContract(bytes32 name) constant public returns (address);
	function available() public constant returns (bool);
}

contract IEventEmitter {
    function info(bytes32 _message) public;
    function info2(bytes32 _message, bytes32 _param) public;

    function warning(bytes32 _message) public;
    function warning2(bytes32 _message, bytes32 _param) public;

    function error(bytes32 _message) public;
    function error2(bytes32 _message, bytes32 _param) public;

    function available(address _tx) public constant returns (bool);
}

