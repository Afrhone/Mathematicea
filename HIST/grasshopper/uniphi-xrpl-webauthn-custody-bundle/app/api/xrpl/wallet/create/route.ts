import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { consumeOpToken, saveCustodyWallet } from '../../../../lib/db';
import { encryptString } from '../../../../lib/crypto';
import { withClient } from '../../../../lib/xrpl';
import { Wallet } from 'xrpl';

export async function POST(req: Request) {
  try {
    const userId = mustUserId();
    const { op_token } = await req.json();
    if (!consumeOpToken(userId, 'create_wallet', String(op_token || ''))) {
      return NextResponse.json({ error: 'invalid op_token' }, { status: 403 });
    }

    const out = await withClient(async (c) => {
      // Creates + funds a testnet wallet using the faucet linked to this server.
      const funded = await c.fundWallet();
      const wallet = funded.wallet;
      return { address: wallet.classicAddress, seed: wallet.seed, balance: funded.balance };
    });

    const encrypted = encryptString(out.seed);
    saveCustodyWallet(userId, out.address, encrypted);

    return NextResponse.json({ ok: true, address: out.address, balance: out.balance });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
