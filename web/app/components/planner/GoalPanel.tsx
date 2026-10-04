'use client';

import React, { useState } from 'react';
import { Goal } from '../../../lib/api';
import { X, Plus, Trash2 } from 'lucide-react';

interface GoalPanelProps {
  isOpen: boolean;
  goals: Goal[];
  error: string | null;
  onClose: () => void;
  onCreate: (input: { title: string; deadline?: string; target_hours_per_week?: number }) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

export const GoalPanel: React.FC<GoalPanelProps> = ({ isOpen, goals, error, onClose, onCreate, onDelete }) => {
  const [title, setTitle] = useState('');
  const [deadline, setDeadline] = useState('');
  const [hours, setHours] = useState('');
  const [saving, setSaving] = useState(false);

  if (!isOpen) return null;

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = title.trim();
    if (!trimmed || saving) return;
    setSaving(true);
    try {
      await onCreate({
        title: trimmed,
        deadline: deadline || undefined,
        target_hours_per_week: hours ? Number(hours) : undefined,
      });
      setTitle('');
      setDeadline('');
      setHours('');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40" onClick={onClose}>
      <div
        className="w-full max-w-lg rounded-2xl bg-white border border-alur-border p-6 text-alur-charcoal"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between pb-3 border-b border-alur-border">
          <div>
            <h2 className="text-base font-black tracking-tight">Goal</h2>
            <p className="text-xs text-alur-warmgray">Sumber Target Harian. M14-manual: tanpa AI dulu.</p>
          </div>
          <button type="button" onClick={onClose} className="p-1.5 rounded-lg hover:bg-alur-surface text-alur-warmgray" title="Tutup">
            <X size={16} />
          </button>
        </div>

        {error && <p className="mt-3 text-xs text-alur-alert">{error}</p>}

        <form onSubmit={handleCreate} className="mt-4 grid gap-2">
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Goal baru, cth. Lari 5K sebelum Desember"
            className="w-full bg-alur-surface/40 rounded-lg border border-alur-border px-3 py-2 text-sm outline-none focus:border-alur-ink"
          />
          <div className="flex gap-2">
            <input
              type="date"
              value={deadline}
              onChange={(e) => setDeadline(e.target.value)}
              className="flex-1 bg-alur-surface/40 rounded-lg border border-alur-border px-3 py-2 text-sm outline-none focus:border-alur-ink"
            />
            <input
              type="number"
              min={1}
              max={168}
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              placeholder="Jam/minggu"
              className="w-36 bg-alur-surface/40 rounded-lg border border-alur-border px-3 py-2 text-sm outline-none focus:border-alur-ink"
            />
            <button
              type="submit"
              disabled={!title.trim() || saving}
              className="inline-flex items-center gap-1 px-4 py-2 text-xs font-bold rounded-lg bg-alur-ink text-white hover:opacity-90 disabled:opacity-40"
            >
              <Plus size={13} /> Tambah
            </button>
          </div>
        </form>

        <div className="mt-4 space-y-2 max-h-72 overflow-y-auto">
          {goals.length === 0 && (
            <p className="text-xs text-alur-warmgray">
              Belum ada goal. Tambahkan 1 goal agar Target Harian tidak kosong — M5 butuh bahan untuk memilih Top 3.
            </p>
          )}
          {goals.map((g) => (
            <div key={g.id} className="flex items-center justify-between gap-3 rounded-lg border border-alur-border px-3 py-2">
              <div className="min-w-0">
                <p className="text-sm font-semibold truncate">{g.title}</p>
                <p className="text-[11px] text-alur-warmgray">
                  {g.deadline ? `Deadline ${g.deadline}` : 'Tanpa deadline'}
                  {g.target_hours_per_week ? ` · ${g.target_hours_per_week} jam/minggu` : ''}
                </p>
              </div>
              <button
                type="button"
                onClick={() => onDelete(g.id)}
                className="p-1.5 rounded-lg text-alur-warmgray hover:text-alur-alert hover:bg-red-50"
                title="Hapus goal"
              >
                <Trash2 size={14} />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
