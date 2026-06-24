import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { getUserByUsername, consumeChallenge, createSession } from '../../../../lib/db';
import { extractChallengeFromClientDataJSON } from '../../../../lib/base64url';
import { verifyAuthentication } from '../../../../lib/webauthn';
import { setSessionCookie } from '../../../../lib/http';

export async function POST(req: Request) {
  try {
    const { username, asseResp } = await req.json();
    const user = getUserByUsername(String(username));
    if (!user) return NextResponse.json({ error: 'unknown user' }, { status: 404 });

    const challenge = extractChallengeFromClientDataJSON(asseResp?.response?.clientDataJSON);
    if (!challenge) return NextResponse.json({ error: 'missing challenge' }, { status: 400 });

    const verification = await verifyAuthentication(user.id, challenge, asseResp);
    if (!verification.verified) return NextResponse.json({ verified: false }, { status: 400 });

    const ok = consumeChallenge(user.id, 'auth', challenge, null);
    if (!ok) return NextResponse.json({ error: 'challenge expired or not found' }, { status: 400 });

    const token = createSession(user.id, 7 * 24 * 60 * 60 * 1000);
    setSessionCookie(token);

    return NextResponse.json({ verified: true });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
