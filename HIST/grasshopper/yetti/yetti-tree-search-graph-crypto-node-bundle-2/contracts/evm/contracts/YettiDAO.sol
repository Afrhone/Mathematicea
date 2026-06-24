// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YettiDAO {
    struct Proposal { address proposer; string uri; uint256 yes; uint256 no; uint256 deadline; bool executed; }
    address public owner;
    mapping(address => bool) public members;
    Proposal[] public proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string uri);
    event Voted(uint256 indexed id, address indexed voter, bool support);
    event Executed(uint256 indexed id);
    event MemberSet(address indexed account, bool allowed);

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier onlyMember() { require(members[msg.sender], "not member"); _; }

    constructor() { owner = msg.sender; members[msg.sender] = true; }
    function setMember(address account, bool allowed) external onlyOwner { members[account] = allowed; emit MemberSet(account, allowed); }
    function propose(string calldata uri, uint256 duration) external onlyMember returns (uint256 id) { id = proposals.length; proposals.push(Proposal(msg.sender, uri, 0, 0, block.timestamp + duration, false)); emit ProposalCreated(id, msg.sender, uri); }
    function vote(uint256 id, bool support) external onlyMember { Proposal storage p = proposals[id]; require(block.timestamp < p.deadline, "closed"); if (support) p.yes += 1; else p.no += 1; emit Voted(id, msg.sender, support); }
    function execute(uint256 id) external onlyMember { Proposal storage p = proposals[id]; require(block.timestamp >= p.deadline, "not closed"); require(!p.executed, "executed"); require(p.yes > p.no, "rejected"); p.executed = true; emit Executed(id); }
}
