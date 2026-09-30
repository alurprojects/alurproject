'use client';

import React, { useState, useRef } from 'react';
import { DayInfo, PlannerTask } from './types';
import { TaskItem } from './TaskItem';
import { Plus } from 'lucide-react';

interface DayColumnProps {
  day: DayInfo;
  tasks: PlannerTask[];
  onAddTask: (dateStr: string, title: string) => void;
  onToggleTask: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
  onDropTask: (taskId: string, targetDateStr: string) => void;
}

export const DayColumn: React.FC<DayColumnProps> = ({
  day,
  tasks,
  onAddTask,
  onToggleTask,
  onOpenEdit,
  onDropTask,
}) => {
  const [isAdding, setIsAdding] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [isDragOver, setIsDragOver] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const completedCount = tasks.filter((t) => t.completed).length;
  const totalCount = tasks.length;

  const handleStartAdd = () => {
    setIsAdding(true);
    setTimeout(() => {
      inputRef.current?.focus();
    }, 50);
  };

  const handleSaveNew = () => {
    const trimmed = newTitle.trim();
    if (trimmed) {
      onAddTask(day.dateStr, trimmed);
    }
    setNewTitle('');
    setIsAdding(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      const trimmed = newTitle.trim();
      if (trimmed) {
        onAddTask(day.dateStr, trimmed);
        setNewTitle(''); // keep open for rapid entry
      }
    } else if (e.key === 'Escape') {
      setIsAdding(false);
      setNewTitle('');
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (!isDragOver) setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    const taskId = e.dataTransfer.getData('text/plain');
    if (taskId) {
      onDropTask(taskId, day.dateStr);
    }
  };

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      className={`flex flex-col min-w-[170px] flex-1 border-r border-alur-border/70 last:border-r-0 transition-colors ${
        day.isWeekend ? 'bg-alur-surface/20' : 'bg-transparent'
      } ${isDragOver ? 'bg-alur-surface/80 ring-1 ring-alur-ink/30' : ''}`}
    >
      {/* Day Header - Fixed height h-12 for identical alignment across all days */}
      <div
        className={`h-12 px-3.5 border-b border-alur-border sticky top-0 z-10 backdrop-blur-xs flex items-center justify-between transition-colors ${
          day.isToday ? 'bg-alur-surface/90' : 'bg-alur-bg/95'
        }`}
      >
        <div className="flex items-center gap-1.5">
          <span
            className={`text-xs font-black tracking-wider uppercase font-title leading-none ${
              day.isToday ? 'text-alur-ink' : 'text-alur-charcoal'
            }`}
          >
            {day.dayName}
          </span>
          <span
            className={`text-xs font-bold leading-none inline-flex items-center px-1.5 py-1 rounded-md transition-all ${
              day.isToday
                ? 'bg-alur-ink text-alur-bg shadow-xs'
                : 'text-alur-warmgray'
            }`}
          >
            {day.dayNumber} {day.monthName}
          </span>
        </div>

        {/* Counter Badge */}
        {totalCount > 0 && (
          <span
            className="text-[10px] font-semibold text-alur-warmgray"
            title={`${completedCount} selesai dari ${totalCount} tugas`}
          >
            {completedCount}/{totalCount}
          </span>
        )}
      </div>

      {/* Task List / Full-width Ruled Lines Area */}
      <div className="flex-1 flex flex-col min-h-[380px]">
        {tasks.map((task) => (
          <TaskItem
            key={task.id}
            task={task}
            onToggle={onToggleTask}
            onOpenEdit={onOpenEdit}
          />
        ))}

        {/* Quick Inline Input */}
        {isAdding ? (
          <div className="p-2 border-b border-alur-border/30">
            <input
              ref={inputRef}
              type="text"
              placeholder="Tulis tugas & tekan Enter..."
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              onBlur={handleSaveNew}
              onKeyDown={handleKeyDown}
              className="w-full bg-white px-2.5 py-2 text-sm rounded-lg border border-alur-ink outline-none text-alur-charcoal shadow-xs"
            />
          </div>
        ) : (
          /* Blank Ruled Area */
          <div
            onClick={handleStartAdd}
            className="flex-1 min-h-[160px] flex flex-col justify-start cursor-text group"
            title="Klik untuk tambah tugas di sini"
          >
            <div className="h-10 border-b border-alur-border/30 group-hover:border-alur-border/70 transition-colors flex items-center px-3.5">
              <span className="opacity-0 group-hover:opacity-50 text-xs text-alur-warmgray flex items-center gap-1">
                <Plus size={12} /> Tambah tugas
              </span>
            </div>
            <div className="h-10 border-b border-alur-border/20" />
            <div className="h-10 border-b border-alur-border/20" />
            <div className="h-10 border-b border-alur-border/20" />
          </div>
        )}
      </div>
    </div>
  );
};
