import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { saveChallenge } from '../../../../lib/db';
import { makeAuthenticationOptions } from '../../../../lib/webauthn';

export async function POST(req: Request) {
  try {
    const userId = mustUserId();
    const { op } = await req.json();
    const opName = String(op || '');
    if (!opName) return NextResponse.json({ error: 'op required' }, { status: 400 });

    const opts = await makeAuthenticationOptions(userId);
    saveChallenge(userId, 'operation', opts.challenge, 60_000, opName);
    return NextResponse.json(opts);
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || 'error' }, { status: 401 });
  }
}
