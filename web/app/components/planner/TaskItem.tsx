'use client';

import React from 'react';
import { PlannerTask, formatEstimate } from './types';
import { Clock, CheckCircle2 } from 'lucide-react';

interface TaskItemProps {
  task: PlannerTask;
  onToggle: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
  onClarify?: (task: PlannerTask) => void;
}

export const TaskItem: React.FC<TaskItemProps> = ({ task, onToggle, onOpenEdit, onClarify }) => {
  const estimate = formatEstimate(task.estimatedMinutes);

  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.setData('text/plain', task.id);
    e.dataTransfer.effectAllowed = 'move';
  };

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      onClick={() => onOpenEdit(task)}
      className={`group w-full flex items-center justify-between gap-3 transition-all cursor-pointer select-none py-2 px-2 bg-transparent hover:bg-alur-surface/60 border-b border-alur-border/50 ${
        task.completed ? 'opacity-50' : ''
      }`}
      title="Klik untuk membuka detail tugas"
    >
      <div className="flex-1 min-w-0">
        <div
          className={`text-sm font-medium leading-snug break-words text-alur-charcoal ${
            task.completed ? 'line-through opacity-70' : ''
          }`}
        >
          {task.title}
        </div>

        <div className="flex flex-wrap items-center gap-2 mt-1 text-[11px] text-alur-warmgray">
          {estimate && (
            <span className="flex items-center gap-1 font-semibold">
              <Clock size={11} />
              <span>{estimate}</span>
            </span>
          )}
          {task.isAmbiguous && !task.completed && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onClarify?.(task);
              }}
              className="font-bold text-alur-alert hover:underline"
              title="Durasi belum diketahui — klik untuk isi estimasi"
            >
              (?)
            </button>
          )}
          {task.goalTitle && (
            <span className="truncate font-medium" title={`dari Goal: ${task.goalTitle}`}>
              dari Goal: {task.goalTitle}
            </span>
          )}
          {task.status === 'MISSED' && task.missedFollowUp !== 'NONE' && task.missedFollowUp !== 'PENDING' && (
            <span className="font-semibold">{task.missedFollowUp === 'FORGOT' ? 'Lupa' : task.missedFollowUp === 'SKIPPED' ? 'Dilewati' : 'Dijadwalkan ulang'}</span>
          )}
        </div>
      </div>

      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          onToggle(task.id);
        }}
        className={`flex-shrink-0 transition-all rounded-full p-0.5 flex items-center justify-center ${
          task.completed
            ? 'opacity-100 text-alur-ink'
            : 'opacity-0 group-hover:opacity-100 text-alur-charcoal hover:scale-110'
        }`}
        title={task.completed ? 'Batalkan selesai' : 'Tandai selesai'}
      >
        <CheckCircle2
          size={19}
          strokeWidth={2.5}
          className={task.completed ? 'fill-alur-ink/15 text-alur-ink' : 'stroke-[2.5]'}
        />
      </button>
    </div>
  );
};
