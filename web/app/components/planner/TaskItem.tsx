'use client';

import React from 'react';
import { PlannerTask, HighlightColor } from './types';
import { Clock, AlignLeft, CheckSquare2, CheckCircle2 } from 'lucide-react';

interface TaskItemProps {
  task: PlannerTask;
  onToggle: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
}

const CARD_COLOR_STYLES: Record<HighlightColor, { bg: string; text: string; border: string; checkBorder: string }> = {
  none: {
    bg: 'bg-transparent hover:bg-alur-surface/60',
    text: 'text-alur-charcoal',
    border: 'border-b border-alur-border/50',
    checkBorder: 'border-alur-warmgray/50 hover:border-alur-ink bg-white/80',
  },
  yellow: {
    bg: 'bg-[#FEF08A] hover:bg-[#FDE047]/90 shadow-2xs',
    text: 'text-[#713F12]',
    border: 'border border-[#FDE047]/80',
    checkBorder: 'border-[#A16207]/60 bg-white/70 hover:border-[#713F12]',
  },
  green: {
    bg: 'bg-[#BBF7D0] hover:bg-[#86EFAC]/90 shadow-2xs',
    text: 'text-[#14532D]',
    border: 'border border-[#86EFAC]/80',
    checkBorder: 'border-[#15803D]/60 bg-white/70 hover:border-[#14532D]',
  },
  blue: {
    bg: 'bg-[#BAE6FD] hover:bg-[#7DD3FC]/90 shadow-2xs',
    text: 'text-[#0C4A6E]',
    border: 'border border-[#7DD3FC]/80',
    checkBorder: 'border-[#0369A1]/60 bg-white/70 hover:border-[#0C4A6E]',
  },
  pink: {
    bg: 'bg-[#FBCFE8] hover:bg-[#F9A8D4]/90 shadow-2xs',
    text: 'text-[#831843]',
    border: 'border border-[#F9A8D4]/80',
    checkBorder: 'border-[#BE185D]/60 bg-white/70 hover:border-[#831843]',
  },
  peach: {
    bg: 'bg-[#FED7AA] hover:bg-[#FDBA74]/90 shadow-2xs',
    text: 'text-[#7C2D12]',
    border: 'border border-[#FDBA74]/80',
    checkBorder: 'border-[#C2410C]/60 bg-white/70 hover:border-[#7C2D12]',
  },
};

export const TaskItem: React.FC<TaskItemProps> = ({
  task,
  onToggle,
  onOpenEdit,
}) => {
  const isColored = task.color && task.color !== 'none';
  const style = CARD_COLOR_STYLES[task.color || 'none'];

  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.setData('text/plain', task.id);
    e.dataTransfer.effectAllowed = 'move';
  };

  const completedSubtasks = task.subtasks?.filter((s) => s.completed).length || 0;
  const totalSubtasks = task.subtasks?.length || 0;

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      onClick={() => onOpenEdit(task)}
      className={`group w-full flex items-center justify-between gap-3 transition-all cursor-pointer select-none ${isColored ? 'p-2.5' : 'py-2 px-2'
        } ${style.bg} ${style.border} ${task.completed ? 'opacity-50' : ''}`}
      title="Klik untuk membuka detail tugas & edit"
    >
      {/* Task Content (Left Side) */}
      <div className="flex-1 min-w-0">
        <div
          className={`text-sm font-medium leading-snug break-words ${style.text
            } ${task.completed ? 'line-through opacity-70' : ''}`}
        >
          {task.title}
        </div>

        {/* Micro Meta (Notes / Subtasks / Time) */}
        {(task.notes || (task.subtasks && task.subtasks.length > 0) || task.timeEstimate) && (
          <div className="flex items-center gap-2 mt-1 text-[11px] opacity-75">
            {task.timeEstimate && (
              <span className="flex items-center gap-1 font-semibold">
                <Clock size={11} />
                <span>{task.timeEstimate}</span>
              </span>
            )}

            {task.notes && (
              <span className="flex items-center gap-0.5" title="Ada catatan">
                <AlignLeft size={11} />
              </span>
            )}

            {totalSubtasks > 0 && (
              <span className="flex items-center gap-1 font-semibold" title="Subtugas">
                <CheckSquare2 size={11} />
                <span>
                  {completedSubtasks}/{totalSubtasks}
                </span>
              </span>
            )}
          </div>
        )}
      </div>

      {/* Checkbox Button on the Right (appears bold on hover, stays visible when completed) */}
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          onToggle(task.id);
        }}
        className={`flex-shrink-0 transition-all rounded-full p-0.5 flex items-center justify-center ${task.completed
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
