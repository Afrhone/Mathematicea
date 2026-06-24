import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { makeRegistrationOptions } from '../../../../lib/webauthn';
import { saveChallenge, upsertUser } from '../../../../lib/db';

export async function POST(req: Request) {
  try {
    const { username } = await req.json();
    if (!username) return NextResponse.json({ error: 'username required' }, { status: 400 });
    const user = upsertUser(String(username));
    const opts = await makeRegistrationOptions(user);
    saveChallenge(user.id, 'register', opts.challenge, 60_000, null);
    return NextResponse.json(opts);
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 500 });
  }
}
