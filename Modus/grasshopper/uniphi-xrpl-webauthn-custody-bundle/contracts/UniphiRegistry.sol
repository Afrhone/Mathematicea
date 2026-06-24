// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title UniphiRegistry
/// @notice Minimal immutable registry: publish a digest once, forever.
///         (Deploy to XRPL EVM sidechain, not the classic XRPL L1.)
contract UniphiRegistry {
    event Published(bytes32 indexed digest, address indexed publisher, string uri);

    mapping(bytes32 => address) public publisherOf;
    mapping(bytes32 => string) public uriOf;

    function publish(bytes32 digest, string calldata uri) external {
        require(digest != bytes32(0), "digest=0");
        require(publisherOf[digest] == address(0), "already");
        publisherOf[digest] = msg.sender;
        uriOf[digest] = uri;
        emit Published(digest, msg.sender, uri);
    }
}
