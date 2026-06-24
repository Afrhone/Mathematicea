import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { consumeOpToken } from '../../../../lib/db';
import { publishMemoPayment } from '../../../../lib/xrpl';

export async function POST(req: Request) {
  try {
    const userId = mustUserId();
    const { op_token, hash, memo } = await req.json();
    if (!consumeOpToken(userId, 'publish_hash', String(op_token || ''))) {
      return NextResponse.json({ error: 'invalid op_token' }, { status: 403 });
    }

    const payload = {
      t: 'uniphi_registry',
      memo: String(memo || 'uniphi'),
      data: String(hash || ''),
      ts: Date.now(),
    };

    const res = await publishMemoPayment({
      userId,
      memoType: String(memo || 'uniphi:immutable-registry'),
      memoData: JSON.stringify(payload),
      drops: '1',
    });

    return NextResponse.json({ ok: true, engine_result: res.engine_result, tx_json: res.tx_json, hash: res.tx_json?.hash });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
