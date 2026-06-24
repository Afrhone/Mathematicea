// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract NamespaceAuthority {
    address public owner;
    mapping(bytes32 => address) public namespaceOwner;
    mapping(address => bool) public admins;
    mapping(address => bool) public whitelisted;

    event NamespaceClaimed(bytes32 indexed namespace, address indexed account);
    event AdminSet(address indexed account, bool allowed);
    event WhitelistSet(address indexed account, bool allowed);

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier onlyAdmin() { require(admins[msg.sender] || msg.sender == owner, "not admin"); _; }

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function setAdmin(address account, bool allowed) external onlyOwner {
        admins[account] = allowed;
        emit AdminSet(account, allowed);
    }

    function setWhitelist(address account, bool allowed) external onlyAdmin {
        whitelisted[account] = allowed;
        emit WhitelistSet(account, allowed);
    }

    function claimNamespace(bytes32 ns) external {
        require(whitelisted[msg.sender] || msg.sender == owner, "not whitelisted");
        require(namespaceOwner[ns] == address(0), "claimed");
        namespaceOwner[ns] = msg.sender;
        emit NamespaceClaimed(ns, msg.sender);
    }
}
