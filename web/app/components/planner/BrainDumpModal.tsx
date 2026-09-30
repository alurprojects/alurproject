'use client';

import React, { useState } from 'react';
import { Sparkles, X, CornerDownLeft } from 'lucide-react';

interface BrainDumpModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (items: string[], targetDateStr: string) => void;
  todayDateStr: string;
}

export const BrainDumpModal: React.FC<BrainDumpModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  todayDateStr,
}) => {
  const [content, setContent] = useState('');
  const [target, setTarget] = useState<'today' | 'someday'>('today');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const lines = content
      .split('\n')
      .map((l) => l.replace(/^[-*•\d.]\s*/, '').trim())
      .filter((l) => l.length > 0);

    if (lines.length > 0) {
      onSubmit(lines, target === 'today' ? todayDateStr : 'someday');
      setContent('');
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-alur-ink/40 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="bg-white rounded-2xl border border-alur-border w-full max-w-lg shadow-xl overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-alur-border flex items-center justify-between bg-alur-surface/30">
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-alur-ink text-white">
              <Sparkles size={16} />
            </span>
            <div>
              <h2 className="text-base font-bold text-alur-charcoal font-title">
                AI Quick Brain-dump
              </h2>
              <p className="text-xs text-alur-warmgray">
                Tumpahkan semua isi pikiran Anda, satu baris per tugas.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 text-alur-warmgray hover:text-alur-charcoal rounded-full hover:bg-alur-surface transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-6">
          <textarea
            autoFocus
            rows={5}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder={"Contoh:\n- Beli bahan makanan di supermarket\n- Kirim laporan keuangan ke tim\n- Baca artikel riset 20 menit"}
            className="w-full p-3.5 text-sm bg-alur-surface/40 rounded-xl border border-alur-border focus:border-alur-ink outline-none text-alur-charcoal placeholder-alur-warmgray resize-none leading-relaxed"
          />

          <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
            {/* Target Selector */}
            <div className="flex items-center gap-1 bg-alur-surface p-1 rounded-lg text-xs font-semibold">
              <button
                type="button"
                onClick={() => setTarget('today')}
                className={`px-3 py-1 rounded-md transition-colors ${
                  target === 'today'
                    ? 'bg-alur-ink text-white'
                    : 'text-alur-warmgray hover:text-alur-charcoal'
                }`}
              >
                Masukkan ke Hari Ini
              </button>
              <button
                type="button"
                onClick={() => setTarget('someday')}
                className={`px-3 py-1 rounded-md transition-colors ${
                  target === 'someday'
                    ? 'bg-alur-ink text-white'
                    : 'text-alur-warmgray hover:text-alur-charcoal'
                }`}
              >
                Masukkan ke Someday
              </button>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={!content.trim()}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold rounded-lg bg-alur-ink text-white hover:opacity-90 disabled:opacity-40 transition-opacity"
            >
              <span>Urai Jadi Tugas</span>
              <CornerDownLeft size={13} />
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
