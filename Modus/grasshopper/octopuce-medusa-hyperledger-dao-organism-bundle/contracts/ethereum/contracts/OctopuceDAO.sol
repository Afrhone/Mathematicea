// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OctopuceDAO {
    struct Proposal {
        address proposer;
        string uri;
        uint256 yes;
        uint256 no;
        bool executed;
        uint256 deadline;
    }

    mapping(address => bool) public members;
    Proposal[] public proposals;
    address public owner;

    event MemberSet(address indexed member, bool allowed);
    event ProposalCreated(uint256 indexed id, address indexed proposer, string uri);
    event Voted(uint256 indexed id, address indexed voter, bool support);
    event Executed(uint256 indexed id);

    modifier onlyMember() { require(members[msg.sender], "not member"); _; }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
    }

    function setMember(address m, bool allowed) external {
        require(msg.sender == owner, "not owner");
        members[m] = allowed;
        emit MemberSet(m, allowed);
    }

    function propose(string calldata uri, uint256 duration) external onlyMember returns (uint256 id) {
        id = proposals.length;
        proposals.push(Proposal(msg.sender, uri, 0, 0, false, block.timestamp + duration));
        emit ProposalCreated(id, msg.sender, uri);
    }

    function vote(uint256 id, bool support) external onlyMember {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.deadline, "closed");
        if (support) p.yes += 1; else p.no += 1;
        emit Voted(id, msg.sender, support);
    }

    function execute(uint256 id) external onlyMember {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.deadline, "not closed");
        require(!p.executed, "done");
        require(p.yes > p.no, "rejected");
        p.executed = true;
        emit Executed(id);
    }
}
