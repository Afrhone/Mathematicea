import { NextResponse } from 'next/server';
export const runtime = 'nodejs';

import { mustUserId } from '../../../../lib/http';
import { getCustodyWallet, getCredentialByUserId } from '../../../../lib/db';
import { accountInfo } from '../../../../lib/xrpl';

export async function GET() {
  try {
    const userId = mustUserId();
    const cred = getCredentialByUserId(userId);
    const wallet = getCustodyWallet(userId);
    let info: any = null;
    if (wallet) {
      try { info = await accountInfo(wallet.xrpl_address); } catch (e) { info = { error: String((e as any)?.message || e) }; }
    }
    return NextResponse.json({
      auth: { hasCredential: !!cred, hasSession: true },
      wallet: wallet ? { address: wallet.xrpl_address, created_at: wallet.created_at } : null,
      account_info: info
    });
  } catch (e: any) {
    return NextResponse.json({ auth: { hasSession: false }, error: e?.message || 'not authenticated' }, { status: 401 });
  }
}
