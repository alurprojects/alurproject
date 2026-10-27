'use client';

import React, { useState } from 'react';
import { getSupabaseBrowser } from '../../lib/supabase-browser';

function GoogleMark() {
  return (
    <span
      aria-hidden="true"
      className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-white shrink-0"
    >
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
        <path
          d="M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z"
          fill="#4285F4"
        />
        <path
          d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z"
          fill="#34A853"
        />
        <path
          d="M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29C.47 8.24 0 10.06 0 12s.47 3.76 1.29 5.38l3.98-3.09z"
          fill="#FBBC05"
        />
        <path
          d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09C6.22 6.86 8.87 4.75 12 4.75z"
          fill="#EA4335"
        />
      </svg>
    </span>
  );
}

function PeopleStrip() {
  return (
    <div aria-hidden="true" className="mt-10 w-full overflow-hidden">
      <svg
        viewBox="0 0 560 120"
        fill="none"
        className="mx-auto h-28 w-full max-w-lg"
        stroke="#1A1A1A"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        preserveAspectRatio="xMidYMax meet"
      >
        <path d="M8 112h544" stroke="#DEDBD6" />
        {/* standing figure */}
        <circle cx="60" cy="38" r="8" fill="#FAF9F7" />
        <path d="M48 58c4-6 8-8 12-8s8 2 12 8l4 22-6 20-6-20-4 20-6-20z" />
        {/* seated figure */}
        <circle cx="150" cy="66" r="7" fill="#FAF9F7" />
        <path d="M138 84c4-5 8-7 12-7s8 2 12 7l10 16h-44z" />
        {/* figure with phone */}
        <rect x="222" y="30" width="34" height="58" rx="6" fill="#F0EFED" />
        <circle cx="239" cy="50" r="7" fill="#FAF9F7" />
        <path d="M229 70c3-5 6-7 10-7s7 2 10 7" />
        {/* wheelchair figure */}
        <circle cx="330" cy="44" r="7" fill="#FAF9F7" />
        <path d="M320 60c3-4 7-6 10-6s7 2 10 6l6 14" />
        <circle cx="322" cy="94" r="12" />
        <circle cx="348" cy="100" r="6" />
        {/* walking pair */}
        <circle cx="420" cy="36" r="7" fill="#FAF9F7" />
        <path d="M410 54c3-5 7-7 10-7s7 2 10 7l3 24-5 18-5-18-3 18-5-18z" />
        <circle cx="458" cy="40" r="7" fill="#FAF9F7" />
        <path d="M448 58c3-5 7-7 10-7s7 2 10 7l2 22-5 18-4-18-3 18-5-18z" />
        {/* bicycle */}
        <circle cx="508" cy="94" r="14" />
        <circle cx="540" cy="94" r="14" />
        <path d="M508 94l10-26h12l10 26M518 68l-6-14" />
        <circle cx="512" cy="52" r="6" fill="#FAF9F7" />
      </svg>
    </div>
  );
}

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
    <main className="min-h-screen bg-alur-bg text-alur-charcoal flex items-center justify-center px-6 py-12" style={{
      backgroundColor: '#FAF9F7',
      backgroundImage:
        'linear-gradient(#E9E6E1 1px, transparent 1px), linear-gradient(90deg, #E9E6E1 1px, transparent 1px)',
      backgroundSize: '24px 24px',
    }}>
      <div
        className="w-full max-w-[880px] h-full text-center"

      >
        <p className="text-xs font-black tracking-[0.2em] uppercase text-alur-warmgray">
          ALUR
        </p>
        <h1 className="font-display mt-4 text-4xl md:text-5xl font-bold text-alur-charcoal">
          Welcome to ALUR
        </h1>
        <p className="mx-auto mt-3 max-w-md text-sm leading-relaxed text-alur-warmgray">
          Your realistic daily planner.
        </p>

        <div className="mx-auto mt-8 w-full max-w-sm">
          <button
            type="button"
            onClick={handleGoogle}
            disabled={loading}
            aria-busy={loading}
            className="w-full inline-flex items-center justify-center gap-2.5 px-4 py-3.5 text-sm font-bold rounded-lg bg-alur-ink text-white hover:opacity-90 active:opacity-80 disabled:opacity-60 disabled:cursor-not-allowed transition-opacity"
          >
            {loading ? (
              <span
                aria-hidden="true"
                className="w-5 h-5 rounded-full border-2 border-white/40 border-t-white animate-spin"
              />
            ) : (
              <GoogleMark />
            )}
            {loading ? 'Menghubungkan...' : 'Continue with Google'}
          </button>

          {(error || authError) && (
            <p role="alert" className="mt-3 text-xs leading-relaxed text-alur-alert">
              {error || 'Login gagal atau dibatalkan. Coba lagi.'}
            </p>
          )}
          <p className="mt-6 text-[11px] leading-relaxed text-alur-warmgray">
            By continuing, you agree to our Terms.
          </p>
        </div>
      </div>
    </main>
  );
};
