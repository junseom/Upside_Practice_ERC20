// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    address internal owner;
    uint256 constant initialSupply = 500 ether;

    uint256 internal _totalSupply;
    
    string public name;
    string public symbol;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public nonces;

    bool internal isPaused;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        _totalSupply = initialSupply;
        balances[owner] = _totalSupply;
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isPaused, "Paused");
        
        return _transfer(msg.sender, _to, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer from the zero address");
        require(balances[_from] >= _value, "Insufficient balance");

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return _approve(msg.sender, _spender, _value);
    }

    function _approve(address _owner, address _spender, uint256 _value) internal returns (bool) {
        require(balanceOf(_owner) >= _value, "Insufficient balance");
        allowances[_owner][_spender] = _value;

        emit Approval(_owner, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isPaused, "Paused");
        uint256 currentAllowance = allowance(_from, msg.sender);
        require(currentAllowance >= _value, "insufficient allowance");

        _approve(_from, _to, currentAllowance - _value);

        return _transfer(_from, _to, _value);
    }

    function pause() public {
        require(msg.sender == owner, "Owner Only");

        isPaused = true;
    }

    function resume() public {
        require(msg.sender == owner, "Owner Only");

        isPaused = false;
    }

    function _toTypedDataHash(bytes32 _hash) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
    }

    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
        require(_deadline >= block.timestamp, "Expired permit");
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            _owner,
            _spender,
            _value,
            nonces[_owner]++,
            _deadline
            ));
        bytes32 hash = _toTypedDataHash(structHash);
        require(_owner == ecrecover(hash, _v, _r, _s), "INVALID_SIGNER");

        return _approve(_owner, _spender, _value);
    }
}