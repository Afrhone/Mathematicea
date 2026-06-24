import { NextRequest, NextResponse } from 'next/server';
export async function POST(req: NextRequest) {
  const base = process.env.NEXT_PUBLIC_GATEWAY_URL || process.env.GATEWAY_URL || 'http://gateway:8787';
  const body = await req.json();
  const res = await fetch(`${base}/v1/chat/completions`, { method:'POST', headers:{'content-type':'application/json','authorization': req.headers.get('authorization') || 'Bearer local-rhiz'}, body: JSON.stringify(body) });
  return NextResponse.json(await res.json(), { status: res.status });
}
