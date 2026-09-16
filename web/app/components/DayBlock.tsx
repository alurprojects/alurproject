'use client';

import React, { useState } from 'react';
import { Task } from '@/lib/api';
import { TaskRow } from './TaskRow';
import { ChevronDown, ChevronRight, Plus, Sparkles } from 'lucide-react';

interface DayBlockProps {
  dayName: string;
  dateStr: string;
  formattedDate: string;
  isToday: boolean;
  tasks: Task[];
  onToggleTask: (id: string, status: string) => Promise<void>;
  onDeleteTask: (id: string) => Promise<void>;
  onClarifyTask: (id: string, minutes: number) => Promise<void>;
  onFollowUpTask: (id: string, action: 'LUPA' | 'SKIP' | 'PINDAH') => Promise<void>;
  onRescheduleTask: (id: string, action: 'ACCEPT' | 'REJECT', targetDate?: string, suggestionId?: string) => Promise<void>;
  onAddTask: (title: string, assignedDate: string) => Promise<void>;
  onOpenBrainDump: () => void;
}

export const DayBlock: React.FC<DayBlockProps> = ({
  dayName,
  dateStr,
  formattedDate,
  isToday,
  tasks,
  onToggleTask,
  onDeleteTask,
  onClarifyTask,
  onFollowUpTask,
  onRescheduleTask,
  onAddTask,
  onOpenBrainDump,
}) => {
  const [isExpanded, setIsExpanded] = useState(isToday);
  const [newTitle, setNewTitle] = useState('');
  const [isAdding, setIsAdding] = useState(false);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    setIsAdding(true);
    try {
      await onAddTask(newTitle.trim(), dateStr);
      setNewTitle('');
    } finally {
      setIsAdding(false);
    }
  };

  const doneCount = tasks.filter((t) => t.status === 'DONE').length;

  return (
    <div
      className={`border rounded-lg transition-all duration-200 ${
        isToday
          ? 'bg-alur-bg border-alur-ink/80 shadow-xs'
          : isExpanded
          ? 'bg-alur-bg border-alur-border'
          : 'bg-alur-surface/60 border-alur-border/50 hover:bg-alur-surface'
      }`}
    >
      {/* Day Header */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full px-5 py-4 flex items-center justify-between text-left focus:outline-none"
      >
        <div className="flex items-baseline gap-3">
          <h2
            className={`text-2xl font-extrabold tracking-tight uppercase ${
              isToday ? 'text-alur-ink' : 'text-alur-charcoal'
            }`}
          >
            {dayName}
          </h2>
          <span className="text-sm font-medium text-alur-warmgray">
            {formattedDate}
          </span>
          {isToday && (
            <span className="text-xs font-semibold px-2 py-0.5 rounded bg-alur-ink text-alur-bg tracking-wide">
              HARI INI
            </span>
          )}
        </div>

        <div className="flex items-center gap-3">
          {tasks.length > 0 && (
            <span className="text-xs font-medium text-alur-warmgray">
              {doneCount}/{tasks.length}
            </span>
          )}
          <span className="text-alur-warmgray">
            {isExpanded ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
          </span>
        </div>
      </button>

      {/* Expanded Content */}
      {isExpanded && (
        <div className="px-5 pb-5 pt-1 border-t border-alur-border/40">
          {/* Task List */}
          {tasks.length === 0 ? (
            <div className="py-4 text-sm text-alur-warmgray/80 italic">
              Belum ada task untuk hari ini.
            </div>
          ) : (
            <div className="divide-y divide-transparent">
              {tasks.map((task) => (
                <TaskRow
                  key={task.id}
                  task={task}
                  onToggle={onToggleTask}
                  onDelete={onDeleteTask}
                  onClarify={onClarifyTask}
                  onFollowUp={onFollowUpTask}
                  onReschedule={onRescheduleTask}
                />
              ))}
            </div>
          )}

          {/* Quick Input + Brain Dump Button */}
          <div className="mt-4 pt-3 flex flex-wrap items-center gap-2">
            <form onSubmit={handleCreate} className="flex-1 min-w-[240px] flex items-center gap-2">
              <input
                type="text"
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                placeholder="+ Tambah task baru..."
                disabled={isAdding}
                className="flex-1 bg-transparent px-3 py-1.5 text-sm border-b border-alur-border focus:border-alur-ink focus:outline-none transition-colors placeholder:text-alur-warmgray/70"
              />
              <button
                type="submit"
                disabled={isAdding || !newTitle.trim()}
                className="px-3 py-1.5 text-xs font-semibold rounded bg-alur-surface hover:bg-alur-ink hover:text-white disabled:opacity-40 transition-colors"
              >
                Simpan
              </button>
            </form>

            <button
              onClick={onOpenBrainDump}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded border border-alur-border hover:border-alur-ink hover:bg-alur-surface text-alur-charcoal transition-colors"
              title="Input bebas via AI Brain-dump"
            >
              <Sparkles size={13} className="text-alur-warmgray" />
              <span>Brain-dump</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
