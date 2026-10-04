'use client';

import React, { useState } from 'react';
import { getSupabaseBrowser } from '../../lib/supabase-browser';

export const AuthScreen: React.FC<{ envReady: boolean; authError: boolean }> = ({
  envReady,
  authError,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGoogle = async () => {
    setError(null);
    if (!envReady) {
      setError('Supabase env belum dikonfigurasi.');
      return;
    }
    setLoading(true);
    try {
      const supabase = getSupabaseBrowser();
      // redirectTo dinamis ikut domain prod agar tidak mental ke localhost.
      const siteUrl = (
        process.env.NEXT_PUBLIC_SITE_URL || window.location.origin
      ).replace(/\/$/, '');
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${siteUrl}/auth/callback`,
        },
      });
      if (oauthError) {
        setError(oauthError.message);
        setLoading(false);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Gagal login Google');
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-alur-bg text-alur-charcoal flex items-center justify-center px-6">
      <div className="w-full max-w-sm text-center">
        <p className="text-xs font-black tracking-[0.2em] uppercase text-alur-warmgray">
          ALUR
        </p>
        <h1 className="mt-3 text-3xl font-black tracking-tight">
          Welcome to ALUR
        </h1>
        <p className="mt-2 text-sm text-alur-warmgray">
          Your realistic daily planner.
        </p>

        <button
          type="button"
          onClick={handleGoogle}
          disabled={loading}
          className="mt-8 w-full inline-flex items-center justify-center gap-2 px-4 py-3.5 text-sm font-bold rounded-lg bg-alur-ink text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
        >
          <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-white text-xs font-black text-alur-ink">
            G
          </span>
          {loading ? 'Menghubungkan...' : 'Continue with Google'}
        </button>

        {(error || authError) && (
          <p className="mt-3 text-xs text-alur-alert">
            {error || 'Login gagal atau dibatalkan. Coba lagi.'}
          </p>
        )}
        <p className="mt-6 text-[11px] leading-relaxed text-alur-warmgray">
          By continuing, you agree to our Terms.
          <br />
          Satu metode login untuk MVP sesuai auth.md.
        </p>
      </div>
    </main>
  );
};
