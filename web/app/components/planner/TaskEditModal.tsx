'use client';

import React, { useState, useEffect, useRef } from 'react';
import { PlannerTask, formatEstimate } from './types';
import { Calendar as CalendarIcon, Trash2, CheckCircle2, Circle, X } from 'lucide-react';

interface TaskEditModalProps {
  task: PlannerTask | null;
  isOpen: boolean;
  dateLabel: string;
  goals: { id: string; title: string }[];
  onClose: () => void;
  onUpdateTask: (id: string, patch: { title?: string; assigned_date?: string; estimated_minutes?: number | null; goal_id?: string | null }) => void;
  onDeleteTask: (id: string) => void;
}

// v1 minimal: judul + tanggal + checkbox + estimasi + goal. Tanpa rich-text,
// stabilo, subtask, lampiran, pengingat (Won't v1).
export const TaskEditModal: React.FC<TaskEditModalProps> = ({
  task,
  isOpen,
  dateLabel,
  goals,
  onClose,
  onUpdateTask,
  onDeleteTask,
}) => {
  const [title, setTitle] = useState('');
  const [completed, setCompleted] = useState(false);
  const [dateStr, setDateStr] = useState('');
  const [estimate, setEstimate] = useState('');
  const [goalId, setGoalId] = useState('');
  const titleInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (task) {
      setTitle(task.title);
      setCompleted(task.completed);
      setDateStr(task.dateStr);
      setEstimate(task.estimatedMinutes != null ? String(task.estimatedMinutes) : '');
      setGoalId(task.goalId ?? '');
    }
  }, [task]);

  useEffect(() => {
    if (isOpen) setTimeout(() => titleInputRef.current?.focus(), 50);
  }, [isOpen ]);

  if (!isOpen || !task) return null;

  const minutes = estimate.trim() === '' ? null : Number(estimate);
  const minutesValid = estimate.trim() === '' || (Number.isInteger(minutes) && (minutes as number) > 0);

  const handleSaveAndClose = () => {
    if (!minutesValid) return;
    onUpdateTask(task.id, {
      title: title.trim() || task.title,
      assigned_date: dateStr || task.dateStr,
      estimated_minutes: minutes,
      goal_id: goalId === '' ? null : goalId,
    });
    onClose();
  };

  return (
    <div
      onClick={handleSaveAndClose}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-in fade-in duration-150"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-xl rounded-2xl p-6 bg-white text-alur-charcoal border border-alur-border"
      >
        <div className="flex items-center justify-between pb-3.5 border-b border-alur-border text-xs text-alur-warmgray">
          <div className="flex items-center gap-2 font-semibold text-alur-charcoal">
            <CalendarIcon size={14} />
            <span>{dateLabel}</span>
          </div>
          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={() => {
                onDeleteTask(task.id);
                onClose();
              }}
              className="p-1.5 rounded-lg hover:text-alur-alert hover:bg-red-50 text-alur-warmgray transition-colors"
              title="Hapus Tugas"
            >
              <Trash2 size={15} />
            </button>
            <button
              type="button"
              onClick={handleSaveAndClose}
              className="p-1.5 rounded-lg hover:text-alur-charcoal hover:bg-alur-surface text-alur-warmgray transition-colors"
              title="Tutup & Simpan"
            >
              <X size={15} />
            </button>
          </div>
        </div>

        <div className="flex items-center gap-3 pt-5 pb-3.5 border-b border-alur-border">
          <input
            ref={titleInputRef}
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSaveAndClose();
            }}
            placeholder="Judul tugas..."
            className={`w-full bg-transparent text-xl font-black tracking-tight outline-none text-alur-charcoal placeholder-alur-warmgray/50 ${
              completed ? 'line-through opacity-50' : ''
            }`}
          />
          <span
            className={`flex-shrink-0 ${completed ? 'text-alur-ink' : 'text-alur-warmgray'}`}
            title={completed ? 'Selesai' : 'Belum selesai'}
          >
            {completed ? <CheckCircle2 size={24} /> : <Circle size={24} strokeWidth={2} />}
          </span>
        </div>

        <div className="grid gap-3 pt-4 text-sm">
          <label className="grid gap-1">
            <span className="text-xs font-semibold text-alur-warmgray">Tanggal</span>
            <input
              type="date"
              value={dateStr}
              onChange={(e) => setDateStr(e.target.value)}
              className="w-full bg-alur-surface/40 rounded-lg border border-alur-border px-2.5 py-2 outline-none focus:border-alur-ink"
            />
          </label>

          <label className="grid gap-1">
            <span className="text-xs font-semibold text-alur-warmgray">
              Estimasi (menit){task.isAmbiguous ? ' — wajib diisi' : ''} {formatEstimate(task.estimatedMinutes) ? `(saat ini ${formatEstimate(task.estimatedMinutes)})` : ''}
            </span>
            <input
              type="number"
              min={1}
              value={estimate}
              onChange={(e) => setEstimate(e.target.value)}
              placeholder="cth. 30"
              className="w-full bg-alur-surface/40 rounded-lg border border-alur-border px-2.5 py-2 outline-none focus:border-alur-ink"
            />
            {!minutesValid && <span className="text-xs text-alur-alert">Isi bilangan bulat &gt; 0 atau kosongkan.</span>}
          </label>

          {goals.length > 0 && (
            <label className="grid gap-1">
              <span className="text-xs font-semibold text-alur-warmgray">Goal terkait (opsional)</span>
              <select
                value={goalId}
                onChange={(e) => setGoalId(e.target.value)}
                className="w-full bg-alur-surface/40 rounded-lg border border-alur-border px-2.5 py-2 outline-none focus:border-alur-ink"
              >
                <option value="">Tanpa goal</option>
                {goals.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.title}
                  </option>
                ))}
              </select>
            </label>
          )}

          <button
            type="button"
            onClick={handleSaveAndClose}
            disabled={!minutesValid}
            className="mt-1 px-4 py-2 text-sm font-bold rounded-lg bg-alur-ink text-white hover:opacity-90 disabled:opacity-40 transition-opacity"
          >
            Simpan
          </button>
        </div>
      </div>
    </div>
  );
};
