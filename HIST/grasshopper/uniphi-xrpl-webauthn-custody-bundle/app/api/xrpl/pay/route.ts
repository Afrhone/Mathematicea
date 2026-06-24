import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { consumeOpToken } from '../../../../lib/db';
import { sendPayment } from '../../../../lib/xrpl';

export async function POST(req: Request) {
  try {
    const userId = mustUserId();
    const { op_token, destination, xrp, memo } = await req.json();
    if (!consumeOpToken(userId, 'sign_payment', String(op_token || ''))) {
      return NextResponse.json({ error: 'invalid op_token' }, { status: 403 });
    }
    const dest = String(destination || '').trim();
    if (!dest) return NextResponse.json({ error: 'destination required' }, { status: 400 });

    const res = await sendPayment({
      userId,
      destination: dest,
      xrp: String(xrp || '0.000001'),
      memoType: String(memo || 'uniphi'),
    });

    return NextResponse.json({ ok: true, engine_result: res.engine_result, tx_json: res.tx_json, hash: res.tx_json?.hash });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
