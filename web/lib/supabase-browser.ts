'use client';

import { createBrowserClient } from '@supabase/ssr';

let browserClient: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabaseBrowser() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
  if (!url || !anonKey) {
    throw new Error(
      'Supabase env belum dikonfigurasi. Isi .env di root (PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY) lalu restart `next dev`.'
    );
  }
  if (!browserClient) {
    browserClient = createBrowserClient(url, anonKey);
  }
  return browserClient;
}

export const JWT_STORAGE_KEY = 'alur_jwt';

export function persistAccessToken(token: string | null) {
  if (typeof window === 'undefined') return;
  if (token) window.localStorage.setItem(JWT_STORAGE_KEY, token);
  else window.localStorage.removeItem(JWT_STORAGE_KEY);
}
