import { NextResponse } from 'next/server';
export async function GET() {
  const base = process.env.NEXT_PUBLIC_GATEWAY_URL || process.env.GATEWAY_URL || 'http://gateway:8787';
  try {
    const res = await fetch(`${base}/api/network`, { cache: 'no-store' });
    return NextResponse.json(await res.json());
  } catch (error) {
    return NextResponse.json({ ok:false, error:String(error), nodes:[], edges:[] }, { status: 502 });
  }
}
