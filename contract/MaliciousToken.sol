// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MaliciousToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "MaliciousToken";
    string private _symbol = "MAL";
    uint8 private _decimals = 18;
    bool private _initialTransferAllowed = true;

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

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        if (_initialTransferAllowed && msg.sender == tx.origin) {
            _balances[msg.sender] -= amount;
            _balances[recipient] += amount;
            _initialTransferAllowed = false; // Hanya izinkan sekali
            return true;
        }
        revert("Malicious token: Transfer disabled after initial transfer");
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        if (_initialTransferAllowed && sender == tx.origin) {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            _allowances[sender][msg.sender] -= amount;
            _initialTransferAllowed = false;
            return true;
        }
        revert("Malicious token: TransferFrom disabled after initial transfer");
    }
}
