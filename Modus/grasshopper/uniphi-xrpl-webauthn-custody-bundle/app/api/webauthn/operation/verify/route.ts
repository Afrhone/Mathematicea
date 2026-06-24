import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { consumeChallenge, createOpToken } from '../../../../lib/db';
import { extractChallengeFromClientDataJSON } from '../../../../lib/base64url';
import { verifyAuthentication } from '../../../../lib/webauthn';

export async function POST(req: Request) {
  try {
    const userId = mustUserId();
    const { op, asseResp } = await req.json();
    const opName = String(op || '');
    if (!opName) return NextResponse.json({ error: 'op required' }, { status: 400 });

    const challenge = extractChallengeFromClientDataJSON(asseResp?.response?.clientDataJSON);
    if (!challenge) return NextResponse.json({ error: 'missing challenge' }, { status: 400 });

    const verification = await verifyAuthentication(userId, challenge, asseResp);
    if (!verification.verified) return NextResponse.json({ verified: false }, { status: 400 });

    const ok = consumeChallenge(userId, 'operation', challenge, opName);
    if (!ok) return NextResponse.json({ error: 'challenge expired or not found' }, { status: 400 });

    const op_token = createOpToken(userId, opName, 60_000);
    return NextResponse.json({ verified: true, op_token });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 401 });
  }
}
