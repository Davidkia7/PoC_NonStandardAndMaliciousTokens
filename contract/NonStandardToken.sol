// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract NonStandardToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "NonStandardToken";
    string private _symbol = "NST";
    uint8 private _decimals = 18;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10**_decimals;
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Tidak mengembalikan bool, tidak standar ERC-20
    function transfer(address recipient, uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true; // Standar, tapi transfer tidak
    }

    // Tidak mengembalikan bool, tidak standar ERC-20
    function transferFrom(address sender, address recipient, uint256 amount) public {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
    }
}
