'use client';

import React, { useState } from 'react';
import { X, Sparkles, Send } from 'lucide-react';

interface BrainDumpModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (text: string) => Promise<void>;
}

export const BrainDumpModal: React.FC<BrainDumpModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
}) => {
  const [text, setText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || isLoading) return;

    setIsLoading(true);
    setError(null);
    try {
      await onSubmit(text.trim());
      setText('');
      onClose();
    } catch (err: any) {
      setError(err.message || 'Gagal memproses brain-dump.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4">
      <div className="w-full max-w-lg bg-alur-bg border border-alur-border rounded-xl shadow-lg overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="px-5 py-4 border-b border-alur-border flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Sparkles size={18} className="text-alur-ink" />
            <h3 className="font-bold text-base text-alur-charcoal">Brain-dump AI</h3>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-alur-warmgray hover:text-alur-charcoal rounded transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-5">
          <p className="text-xs text-alur-warmgray mb-3">
            Tulis rencana acakmu dalam bahasa bebas. AI akan mengekstrak task, memperkirakan durasi, dan menjadwalkannya secara otomatis.
          </p>

          <textarea
            rows={4}
            value={text}
            onChange={(e) => setText(e.target.value)}
            disabled={isLoading}
            placeholder="Contoh: Besok review PR 30 menit, hari kamis mau olahraga 1 jam, selasa meeting klien..."
            className="w-full p-3 text-sm bg-alur-surface/50 border border-alur-border rounded-lg focus:border-alur-ink focus:outline-none placeholder:text-alur-warmgray/60 resize-none"
            autoFocus
          />

          {error && (
            <div className="mt-2 text-xs text-alur-alert font-medium">
              {error}
            </div>
          )}

          <div className="mt-4 flex items-center justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              disabled={isLoading}
              className="px-3.5 py-1.5 text-xs font-semibold rounded border border-alur-border text-alur-charcoal hover:bg-alur-surface transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={isLoading || !text.trim()}
              className="inline-flex items-center gap-1.5 px-4 py-1.5 text-xs font-semibold rounded bg-alur-ink text-alur-bg hover:bg-alur-charcoal disabled:opacity-50 transition-colors"
            >
              {isLoading ? (
                <span>Menganalisis...</span>
              ) : (
                <>
                  <Send size={12} />
                  <span>Jadwalkan</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
