'use client';

import React, { useState } from 'react';
import { Task } from '@/lib/api';
import { Check, Trash2, HelpCircle, ArrowRight } from 'lucide-react';

interface TaskRowProps {
  task: Task;
  onToggle: (id: string, status: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  onClarify: (id: string, minutes: number) => Promise<void>;
  onFollowUp: (id: string, action: 'LUPA' | 'SKIP' | 'PINDAH') => Promise<void>;
  onReschedule: (id: string, action: 'ACCEPT' | 'REJECT', targetDate?: string, suggestionId?: string) => Promise<void>;
}

export const TaskRow: React.FC<TaskRowProps> = ({
  task,
  onToggle,
  onDelete,
  onClarify,
  onFollowUp,
  onReschedule,
}) => {
  const [showClarifyOptions, setShowClarifyOptions] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isDone = task.status === 'DONE';
  const isMissed = task.status === 'MISSED';
  const showFollowUp = task.missed_follow_up === 'PENDING';
  const suggestion = task.reschedule_suggestion;

  const handleClarifySubmit = async (minutes: number) => {
    setIsSubmitting(true);
    try {
      await onClarify(task.id, minutes);
      setShowClarifyOptions(false);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="group border-b border-alur-border/60 py-3.5 transition-colors">
      <div className="flex items-center justify-between gap-3">
        {/* Left: Checkbox + Title */}
        <div className="flex items-center gap-3.5 flex-1 min-w-0">
          <button
            onClick={() => onToggle(task.id, task.status)}
            className={`w-5 h-5 rounded-sm border flex items-center justify-center transition-colors ${
              isDone
                ? 'bg-alur-ink border-alur-ink text-alur-bg'
                : isMissed
                ? 'border-alur-alert/80 text-transparent'
                : 'border-alur-charcoal/40 hover:border-alur-ink text-transparent'
            }`}
          >
            <Check size={14} strokeWidth={2.5} />
          </button>

          <span
            className={`text-base font-medium truncate transition-all ${
              isDone
                ? 'line-through text-alur-warmgray'
                : isMissed
                ? 'text-alur-charcoal/90'
                : 'text-alur-charcoal'
            }`}
          >
            {task.title}
          </span>

          {/* Ambiguous duration badge (?) */}
          {task.is_ambiguous && (
            <button
              onClick={() => setShowClarifyOptions(!showClarifyOptions)}
              className="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs font-semibold rounded bg-alur-surface border border-alur-border text-alur-warmgray hover:text-alur-ink hover:border-alur-ink transition-colors"
              title="Perjelas durasi task ini"
            >
              <HelpCircle size={12} />
              <span>?</span>
            </button>
          )}

          {/* Duration Badge */}
          {task.estimated_minutes && !task.is_ambiguous && (
            <span className="text-xs font-normal text-alur-warmgray">
              {task.estimated_minutes}m
            </span>
          )}
        </div>

        {/* Right: Delete action on hover */}
        <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={() => onDelete(task.id)}
            className="p-1 text-alur-warmgray hover:text-alur-alert transition-colors"
            title="Hapus task"
          >
            <Trash2 size={16} />
          </button>
        </div>
      </div>

      {/* Inline Clarification Expansion */}
      {showClarifyOptions && (
        <div className="mt-2.5 ml-8.5 pl-3 border-l-2 border-alur-ink flex items-center gap-2 text-xs">
          <span className="text-alur-warmgray font-medium">Berapa lama perkiraan task ini?</span>
          {[15, 30, 45, 60].map((mins) => (
            <button
              key={mins}
              disabled={isSubmitting}
              onClick={() => handleClarifySubmit(mins)}
              className="px-2 py-0.5 rounded border border-alur-border hover:border-alur-ink hover:bg-alur-ink hover:text-white transition-colors"
            >
              {mins}m
            </button>
          ))}
          <button
            onClick={() => setShowClarifyOptions(false)}
            className="text-alur-warmgray hover:text-alur-charcoal underline ml-1"
          >
            Batal
          </button>
        </div>
      )}

      {/* Follow-up Chips for Missed Tasks (Lupa / Skip / Pindah) */}
      {showFollowUp && (
        <div className="mt-2.5 ml-8.5 pl-3 border-l-2 border-alur-alert flex items-center gap-2 text-xs">
          <span className="text-alur-alert font-medium">Task terlewat:</span>
          <button
            onClick={() => onFollowUp(task.id, 'LUPA')}
            className="px-2 py-0.5 rounded border border-alur-border hover:border-alur-ink hover:bg-alur-ink hover:text-white transition-colors"
          >
            Lupa dicentang
          </button>
          <button
            onClick={() => onFollowUp(task.id, 'SKIP')}
            className="px-2 py-0.5 rounded border border-alur-border hover:border-alur-ink hover:bg-alur-ink hover:text-white transition-colors"
          >
            Skip minggu ini
          </button>
          <button
            onClick={() => onFollowUp(task.id, 'PINDAH')}
            className="px-2 py-0.5 rounded border border-alur-border hover:border-alur-ink hover:bg-alur-ink hover:text-white transition-colors"
          >
            Pindah hari lain
          </button>
        </div>
      )}

      {/* Reschedule Suggestion Banner */}
      {suggestion && (
        <div className="mt-2 ml-8.5 p-2 rounded bg-alur-surface border border-alur-border flex items-center justify-between text-xs">
          <div className="flex items-center gap-1.5 text-alur-info">
            <span>Saran ALUR: Pindah ke {suggestion.suggested_date} ({suggestion.reason})</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => onReschedule(task.id, 'ACCEPT', suggestion.suggested_date, suggestion.id)}
              className="font-semibold text-alur-ink hover:underline"
            >
              Terima
            </button>
            <button
              onClick={() => onReschedule(task.id, 'REJECT', undefined, suggestion.id)}
              className="text-alur-warmgray hover:text-alur-charcoal"
            >
              Abaikan
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
