// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GenerativeEntityNFT {
    string public name = "Octopuce Medusa Generative Entity";
    string public symbol = "OMG";
    uint256 public totalSupply;
    address public authority;

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Minted(uint256 indexed tokenId, address indexed to, string uri, bytes32 stateHash);

    modifier onlyAuthority() { require(msg.sender == authority, "not authority"); _; }

    constructor(address _authority) {
        authority = _authority;
    }

    function mint(address to, string calldata uri, bytes32 stateHash) external onlyAuthority returns (uint256 id) {
        id = ++totalSupply;
        ownerOf[id] = to;
        tokenURI[id] = uri;
        balanceOf[to] += 1;
        emit Transfer(address(0), to, id);
        emit Minted(id, to, uri, stateHash);
    }
}
