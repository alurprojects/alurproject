'use client';

import React, { Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { AuthScreen } from '../components/AuthScreen';
import { getSupabaseBrowser } from '../../lib/supabase-browser';

const ENV_READY = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

function LoginInner() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const authError = searchParams.get('auth_error') === '1';

  useEffect(() => {
    if (!ENV_READY) return;
    let cancelled = false;
    getSupabaseBrowser()
      .auth.getSession()
      .then(({ data }: { data: { session: unknown | null } }) => {
        if (!cancelled && data.session) router.replace('/');
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [router]);

  return <AuthScreen envReady={ENV_READY} authError={authError} />;
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <p className="px-6 py-10 text-sm text-alur-warmgray">Memuat...</p>
      }
    >
      <LoginInner />
    </Suspense>
  );
}
