import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { getUserByUsername, consumeChallenge, saveCredential } from '../../../../lib/db';
import { extractChallengeFromClientDataJSON } from '../../../../lib/base64url';
import { verifyRegistration, packCredential } from '../../../../lib/webauthn';

export async function POST(req: Request) {
  try {
    const { username, attResp } = await req.json();
    const user = getUserByUsername(String(username));
    if (!user) return NextResponse.json({ error: 'unknown user' }, { status: 404 });

    const challenge = extractChallengeFromClientDataJSON(attResp?.response?.clientDataJSON);
    if (!challenge) return NextResponse.json({ error: 'missing challenge' }, { status: 400 });

    // Verify cryptographically
    const verification = await verifyRegistration(user.id, challenge, attResp);
    if (!verification.verified) return NextResponse.json({ verified: false }, { status: 400 });

    // Consume stored challenge
    const ok = consumeChallenge(user.id, 'register', challenge, null);
    if (!ok) return NextResponse.json({ error: 'challenge expired or not found' }, { status: 400 });

    const packed = packCredential(verification);
    saveCredential(user.id, packed, packed.counter || 0);
    return NextResponse.json({ verified: true });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
