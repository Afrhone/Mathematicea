# Hyperledger Fabric Network Scaffold

This folder is intentionally a scaffold. Use `fabric-samples/test-network` as the base network, then copy the chaincode:

```bash
cp -a contracts/fabric/chaincode/octopuce_medusa fabric-samples/asset-transfer-octopuce
```

Deploy example:

```bash
./network.sh up createChannel -c octopuce-channel -ca
./network.sh deployCC -ccn octopuce_medusa -ccp ../asset-transfer-octopuce -ccl javascript
```

The chaincode stores hypergraph nodes and hyperedges with hash lineage.
