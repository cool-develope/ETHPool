// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHPool {
    uint256 public totalDeposit;

    address private _owner;

    address[] private _users;

    mapping(address => uint256) private _deposits;
    mapping(address => uint256) private _fees;

    constructor() {
        _owner = msg.sender;
    }

    event Received(address indexed payee, uint256 weiAmount);
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed withdrawer, uint256 weiAmount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Pool: caller is not the owner");
        _;
    }

    /**
     * @dev Stores the sent amount as deposit from users.
     */
    function deposit() public payable {
        address payee = msg.sender;
        uint256 amount = msg.value;

        if (_deposits[payee] == 0) _users.push(payee);

        _deposits[payee] += amount;
        totalDeposit += amount;

        emit Deposited(payee, amount);
    }

    /**
     * @dev Assign rewards to stake holders.
     */
    function addReward() public payable onlyOwner {
        uint256 amount = msg.value;

        for (uint256 i; i < _users.length; i++) {
            _fees[_users[i]] += (amount * _deposits[_users[i]]) / totalDeposit;
        }
    }

    /**
     * @dev Withdraw the deposit with the share of rewards.
     */
    function withdraw() public {
        address withdrawer = msg.sender;
        uint256 amount = _deposits[withdrawer] + _fees[withdrawer];

        _removeUser(withdrawer);

        totalDeposit -= _deposits[withdrawer];
        _deposits[withdrawer] = 0;
        _fees[withdrawer] = 0;

        require(amount > 0, "Pool: insufficient balance");
        (bool success, ) = withdrawer.call{value: amount}("");
        require(
            success,
            "Pool: unable to send value, withdrawer may have reverted"
        );

        emit Withdrawn(withdrawer, amount);
    }

    /**
     * @dev Remove the user from the user list.
     * @param user The address to remove.
     */
    function _removeUser(address user) private {
        require(_deposits[user] > 0, "Pool: the user is already removed");

        for (uint256 i; i < _users.length; i++) {
            if (_users[i] == user) {
                _users[i] = _users[_users.length - 1];
                _users.pop();
                break;
            }
        }
    }
}
