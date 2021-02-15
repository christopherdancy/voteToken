pragma solidity ^0.5.3;


contract voteToken {

    /**
     * Boilerplate variables -
     * used from ERC20 standard
     */

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public tokensGenerated;

    // `creationBlock` is the block number that the Clone Token was created
    uint256 public creationBlock;

    /**
     * Stuct used to track values
     * in different blocks
     */
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint256 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint256 value;
    }


    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `delegatedBalances` is the map that tracks how much each address has delegated to other addresses, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping(address => Checkpoint[]) delegatedBalances;

    // `addressDelegatedPower` is the map that tracks the total amount given from one address to another, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping(address => mapping(address => Checkpoint[])) addressDelegatedPower;

    // `addressDelegatedPower` is the map that tracks the total vote power of an address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping(address => Checkpoint[]) votePowerAllowed;

    // `Delegate` is the event that emits new votepower transfers
    event Delegate(address indexed from, address indexed to, uint tokens);



    constructor() public {
        name = "Vote Token";
        symbol = "VT";
        decimals = 0;
        totalSupply = 100;
        owner = msg.sender;
        creationBlock = block.number;
    }

    /**
     *function 'delegate' transfers vote power to other addresses and updates mappings
     * Param(address to send, percentage to transfer)
     */
    function delegate(address _to, uint _votePercentage) public returns(uint delegated) {
        //Must revert - cannot delegate more than 100% of holdings
        require(_votePercentage<= 100, "cannot delegate more than 100%");
        //Must revert - cannot delegate to self
        require(msg.sender!=_to, "Cannot delegate to self");

        //if delegate percentage is 0
        //remove the power the msg.sender delegated
        if(_votePercentage == 0) {
            //update _to vote power
            //set vote power provided by msg.sender to 0
            uint _currentDelegateAmount = addressDelegatedOf(_to);
            updateValueAtNow(addressDelegatedPower[msg.sender][_to], 0);
            uint _currentVotePower = votePowerOf(_to) - _currentDelegateAmount;
            updateValueAtNow(votePowerAllowed[_to], _currentVotePower);
            return 0;
        }else{

        //The msg.sender cannot delegate from a 0 balance
        uint _currentBalance = balanceOf(msg.sender) - balanceOfDelegated(msg.sender);
        require(_currentBalance > 0, "You must have a balance to delegate");

        //The delegated votepower must be more than 1
        uint _percentconv = (_votePercentage * _currentBalance) / 100;
        require(_percentconv>= 1, "must delegate atleast 1 vote power");

        //update the balance of how much msg.sender has delegated
        uint _adddelegateBalance = balanceOfDelegated(msg.sender) + _percentconv;
        updateValueAtNow(delegatedBalances[msg.sender], _adddelegateBalance);
        //update the balance of _to delegated balance from msg.sender
        uint _addressDelegate = _percentconv + addressDelegatedOf(_to);
        updateValueAtNow(addressDelegatedPower[msg.sender][_to], _addressDelegate);
        //update the balance of _to vote power
        uint _addToVotePower = votePowerOf(_to) + _percentconv;
        updateValueAtNow(votePowerAllowed[_to], _addToVotePower);
        emit Delegate(msg.sender, _to, _percentconv);
        return _percentconv;

        }

    }


    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    function balanceOfDelegated(address _owner) public view returns (uint256 balance) {
        return balanceOfAtDelegated(_owner, block.number);
    }

    function addressDelegatedOf(address _to) public view returns (uint256 balance) {
        return balanceOfAtAddressDelegated(_to, block.number);
    }

    function votePowerOf(address _owner) public view returns (uint256 balance) {
        return votePowerOfAt(_owner, block.number);
    }


    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function votePowerOfAt(address _owner, uint _blockNumber) public view
    returns(uint) {
        uint _delegator = balanceOfAt(_owner, _blockNumber);
        uint _delegatedTotal = balanceOfAtDelegated(_owner, _blockNumber);
        uint _delegateeAllowedTotal = balanceOfAtAllowed(_owner, _blockNumber);
        uint total = _delegator - _delegatedTotal +  _delegateeAllowedTotal;
        return total;
    }

    function balanceOfAt(address _owner, uint _blockNumber) public view
        returns (uint) {
            return getValueAt(balances[_owner], _blockNumber);

    }

    function balanceOfAtDelegated(address _owner, uint _blockNumber)  view internal
    returns (uint) {
        return getValueAt(delegatedBalances[_owner], _blockNumber);

    }

    function balanceOfAtAllowed(address _owner, uint _blockNumber)  view internal
    returns (uint) {
        return getValueAt(votePowerAllowed[_owner], _blockNumber);

    }

    function balanceOfAtAddressDelegated(address _to, uint _blockNumber)  view internal
    returns (uint) {
        return getValueAt(addressDelegatedPower[msg.sender][_to], _blockNumber);

    }


    // @notice Generates `_amount` tokens that are assigned to `_owner`
    // @param owner The address that will be assigned the new tokens
    // @param totalsupply The quantity of tokens generated
    // @return True if the tokens are generated correctly
    function generateTokens() public returns (bool success) {
        require(msg.sender == owner);
        require(tokensGenerated != true);
        tokensGenerated = true;
        updateValueAtNow(balances[msg.sender], totalSupply);
        return true;
    }

    //helper functions
    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) view internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint256(block.number);
               newCheckPoint.value = uint256(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint256(_value);
           }
    }

}
