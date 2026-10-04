import { NextResponse } from 'next/server';
import { getSupabaseServer } from '../../../lib/supabase-server';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get('code');
  const next = url.searchParams.get('next') ?? '/';
  // Hanya izinkan redirect internal agar tidak open-redirect.
  const safeNext = next.startsWith('/') && !next.startsWith('//') ? next : '/';

  if (code) {
    const supabase = getSupabaseServer();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${url.origin}${safeNext}`);
    }
  }
  return NextResponse.redirect(`${url.origin}/?auth_error=1`);
}
