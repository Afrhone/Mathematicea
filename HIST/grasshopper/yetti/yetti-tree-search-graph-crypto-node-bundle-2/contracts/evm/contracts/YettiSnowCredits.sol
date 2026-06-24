// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YettiSnowCredits {
    string public name = "YETTI Snow Credits";
    string public symbol = "YETTI";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    bool public mintLocked;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public minters;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event MinterSet(address indexed account, bool allowed);
    event MintLocked();

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier canMint() { require(msg.sender == owner || minters[msg.sender], "not minter"); require(!mintLocked, "mint locked"); _; }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function setMinter(address account, bool allowed) external onlyOwner { minters[account] = allowed; emit MinterSet(account, allowed); }
    function lockMint() external onlyOwner { mintLocked = true; emit MintLocked(); }
    function mint(address to, uint256 amount) external canMint { _mint(to, amount); }

    function transfer(address to, uint256 amount) external returns (bool) { _transfer(msg.sender, to, amount); return true; }
    function approve(address spender, uint256 amount) external returns (bool) { allowance[msg.sender][spender] = amount; emit Approval(msg.sender, spender, amount); return true; }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal { totalSupply += amount; balanceOf[to] += amount; emit Transfer(address(0), to, amount); }
    function _transfer(address from, address to, uint256 amount) internal { require(balanceOf[from] >= amount, "balance"); balanceOf[from] -= amount; balanceOf[to] += amount; emit Transfer(from, to, amount); }
}
