'use strict';

const { Contract } = require('fabric-contract-api');
const crypto = require('crypto');

class OctopuceMedusaContract extends Contract {
  async InitLedger(ctx) {
    const h0 = crypto.createHash('sha256').update('octopuce-medusa-h0').digest('hex');
    await ctx.stub.putState('h0', Buffer.from(JSON.stringify({
      id: 'h0',
      kind: 'zeroth_anchor',
      hash: h0,
      owner: 'phiiiiv3i4',
      createdAt: new Date().toISOString()
    })));
    return h0;
  }

  async PutNode(ctx, id, kind, owner, stateJson) {
    const state = JSON.parse(stateJson);
    const hash = crypto.createHash('sha256').update(JSON.stringify({id, kind, owner, state})).digest('hex');
    const node = { id, kind, owner, state, hash, updatedAt: new Date().toISOString() };
    await ctx.stub.putState(`node:${id}`, Buffer.from(JSON.stringify(node)));
    return JSON.stringify(node);
  }

  async PutHyperedge(ctx, id, kind, sourcesJson, targetsJson, proofJson) {
    const edge = {
      id,
      kind,
      sources: JSON.parse(sourcesJson),
      targets: JSON.parse(targetsJson),
      proof: JSON.parse(proofJson),
      updatedAt: new Date().toISOString()
    };
    edge.hash = crypto.createHash('sha256').update(JSON.stringify(edge)).digest('hex');
    await ctx.stub.putState(`edge:${id}`, Buffer.from(JSON.stringify(edge)));
    return JSON.stringify(edge);
  }

  async Read(ctx, key) {
    const data = await ctx.stub.getState(key);
    if (!data || data.length === 0) throw new Error(`missing ${key}`);
    return data.toString();
  }
}

module.exports = OctopuceMedusaContract;
