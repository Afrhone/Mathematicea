import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { getUserByUsername, saveChallenge } from '../../../../lib/db';
import { makeAuthenticationOptions } from '../../../../lib/webauthn';

export async function POST(req: Request) {
  try {
    const { username } = await req.json();
    const user = getUserByUsername(String(username));
    if (!user) return NextResponse.json({ error: 'unknown user' }, { status: 404 });

    const opts = await makeAuthenticationOptions(user.id);
    saveChallenge(user.id, 'auth', opts.challenge, 60_000, null);
    return NextResponse.json(opts);
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
