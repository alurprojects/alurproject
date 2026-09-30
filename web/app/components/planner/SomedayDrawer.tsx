'use client';

import React, { useState, useRef } from 'react';
import { PlannerTask } from './types';
import { TaskItem } from './TaskItem';
import { ChevronDown, ChevronUp, CornerDownLeft } from 'lucide-react';

interface SomedayDrawerProps {
  tasks: PlannerTask[];
  isOpen: boolean;
  onToggleOpen: () => void;
  onAddTask: (title: string) => void;
  onToggleTask: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
  onMoveToDate: (taskId: string, targetDateStr: string) => void;
  todayDateStr: string;
}

export const SomedayDrawer: React.FC<SomedayDrawerProps> = ({
  tasks,
  isOpen,
  onToggleOpen,
  onAddTask,
  onToggleTask,
  onOpenEdit,
  onMoveToDate,
  todayDateStr,
}) => {
  const [newTitle, setNewTitle] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  const handleAdd = () => {
    const trimmed = newTitle.trim();
    if (trimmed) {
      onAddTask(trimmed);
      setNewTitle('');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleAdd();
    }
  };

  return (
    <div className="border-t border-alur-border bg-alur-surface/30">
      {/* Header Bar */}
      <div
        onClick={onToggleOpen}
        className="px-6 py-3.5 flex items-center justify-between cursor-pointer hover:bg-alur-surface/60 transition-colors select-none"
      >
        <div className="flex items-center gap-3">
          <span className="text-sm font-black font-title tracking-wider uppercase text-alur-ink">
            Someday
          </span>
          <span className="text-xs text-alur-warmgray">
            (Tugas belum dijadwalkan)
          </span>
          <span className="px-2 py-0.5 text-xs font-bold rounded-full bg-alur-surface border border-alur-border text-alur-charcoal">
            {tasks.length}
          </span>
        </div>

        <div className="flex items-center gap-2 text-alur-warmgray text-xs">
          <span>{isOpen ? 'Sembunyikan' : 'Buka'}</span>
          {isOpen ? <ChevronDown size={16} /> : <ChevronUp size={16} />}
        </div>
      </div>

      {/* Drawer Content */}
      {isOpen && (
        <div className="px-6 pb-6 pt-2">
          {/* Quick Input Row */}
          <div className="flex items-center gap-2 mb-4 max-w-xl">
            <div className="relative flex-1">
              <input
                ref={inputRef}
                type="text"
                placeholder="Tambah ide/tugas ke Someday... lalu tekan Enter"
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                onKeyDown={handleKeyDown}
                className="w-full pl-3 pr-8 py-2 text-sm bg-white rounded-lg border border-alur-border focus:border-alur-ink outline-none text-alur-charcoal shadow-2xs"
              />
              <button
                type="button"
                onClick={handleAdd}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-alur-warmgray hover:text-alur-ink p-1"
                title="Simpan"
              >
                <CornerDownLeft size={14} />
              </button>
            </div>
          </div>

          {/* Grid of Someday Tasks */}
          {tasks.length === 0 ? (
            <div className="py-6 text-center text-xs text-alur-warmgray">
              Belum ada tugas di daftar Someday.
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2.5">
              {tasks.map((task) => (
                <div
                  key={task.id}
                  className="bg-white rounded-xl border border-alur-border p-2.5 shadow-2xs flex flex-col justify-between"
                >
                  <TaskItem
                    task={task}
                    onToggle={onToggleTask}
                    onOpenEdit={onOpenEdit}
                  />

                  {/* Action: Move to Today */}
                  <div className="mt-2 pt-2 border-t border-alur-border/40 flex justify-end">
                    <button
                      type="button"
                      onClick={() => onMoveToDate(task.id, todayDateStr)}
                      className="text-[11px] font-semibold text-alur-warmgray hover:text-alur-ink flex items-center gap-1 transition-colors"
                    >
                      Pindah ke Hari Ini &rarr;
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
