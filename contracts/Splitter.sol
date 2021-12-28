// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Splitter {
    address private _owner;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    constructor() {
        _owner = msg.sender;
    }

    event Received(address indexed sender, uint256 weiAmount);
    event Transfered(
        address indexed transfer,
        address indexed token,
        uint256 amount
    );
    event Withdrawn(address indexed token, uint256 amount);

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
        require(owner() == msg.sender, "Splitter: caller is not the owner");
        _;
    }

    /**
     * @dev Transfer ethers and split to payees.
     * @param payees The list of payee.
     */
    function addPayment(address[] memory payees) external payable {
        uint256 amount = msg.value;
        address transfer = msg.sender;

        uint256 unitAmount = (amount * 999) / 1000 / payees.length;
        bool success;

        require(unitAmount > 0, "Splitter: insufficient balance");
        for (uint256 i; i < payees.length; i++) {
            (success, ) = payees[i].call{value: unitAmount}("");
            require(
                success,
                "Splitter: unable to send value, transfer may have reverted"
            );
        }

        emit Transfered(transfer, address(0), amount);
    }

    /**
     * @dev Transfer ERC20 token and split to payees.
     * @param token The address of ERC20.
     * @param amount The amount of the transferred token.
     * @param payees The list of payee.
     */
    function addPayment(
        address token,
        uint256 amount,
        address[] memory payees
    ) external {
        address transfer = msg.sender;

        IERC20(token).transferFrom(transfer, address(this), amount);

        uint256 unitAmount = (amount * 999) / 1000 / payees.length;

        require(unitAmount > 0, "Splitter: insufficient balance");
        for (uint256 i; i < payees.length; i++) {
            _safeTransfer(token, payees[i], unitAmount);
        }

        emit Transfered(transfer, token, amount);
    }

    /**
     * @dev Withdraw assets
     * @param token The address of ERC20.
     */
    function withdraw(address token) external onlyOwner{
        if (token == address(0)) {
            uint amount = address(this).balance;
            require(amount > 0, "Splitter: insufficient balance");
            (bool success, ) = _owner.call{value: amount}("");
            require(
                success,
                "Splitter: unable to send value, owner may have reverted"
            );
            emit Withdrawn(address(0), amount);
        } else {
            uint amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, "Splitter: insufficient balance");
            _safeTransfer(token, _owner, amount);
            emit Withdrawn(token, amount);
        }
    }

    /**
     * @dev Safe transfer of ERC20 token.
     * @param token The address of ERC20.
     * @param to The receiver address.
     * @param value The amount of token.
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Splitter: TRANSFER_FAILED"
        );
    }
}
