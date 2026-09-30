'use client';

import React, { useState, useEffect, useRef } from 'react';
import { PlannerTask, HighlightColor, SubTask } from './types';
import {
  Calendar as CalendarIcon,
  Trash2,
  RotateCw,
  Bell,
  MoreHorizontal,
  CheckCircle2,
  Circle,
  Heading,
  Bold,
  Italic,
  List,
  AlignLeft,
  Link2,
  Paperclip,
  X,
  Plus,
  Sun,
  Moon,
} from 'lucide-react';

interface TaskEditModalProps {
  task: PlannerTask | null;
  isOpen: boolean;
  onClose: () => void;
  onUpdateTask: (updated: PlannerTask) => void;
  onDeleteTask: (id: string) => void;
  dateLabel: string;
}

const COLOR_OPTIONS: { color: HighlightColor; hex: string; label: string }[] = [
  { color: 'none', hex: '#DEDBD6', label: 'Polos' },
  { color: 'yellow', hex: '#FEF08A', label: 'Kuning' },
  { color: 'green', hex: '#BBF7D0', label: 'Hijau' },
  { color: 'blue', hex: '#BAE6FD', label: 'Biru' },
  { color: 'pink', hex: '#FBCFE8', label: 'Pink' },
  { color: 'peach', hex: '#FED7AA', label: 'Peach' },
];

export const TaskEditModal: React.FC<TaskEditModalProps> = ({
  task,
  isOpen,
  onClose,
  onUpdateTask,
  onDeleteTask,
  dateLabel,
}) => {
  const [title, setTitle] = useState('');
  const [completed, setCompleted] = useState(false);
  const [color, setColor] = useState<HighlightColor>('none');
  const [notes, setNotes] = useState('');
  const [subtasks, setSubtasks] = useState<SubTask[]>([]);
  const [newSubtaskTitle, setNewSubtaskTitle] = useState('');
  const [showColorPicker, setShowColorPicker] = useState(false);
  // Default to 'light' mode matching the ALUR paper aesthetic
  const [isDarkMode, setIsDarkMode] = useState(false);

  const titleInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (task) {
      setTitle(task.title);
      setCompleted(task.completed);
      setColor(task.color || 'none');
      setNotes(task.notes || '');
      setSubtasks(task.subtasks || []);
    }
  }, [task]);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        titleInputRef.current?.focus();
      }, 50);
    }
  }, [isOpen]);

  if (!isOpen || !task) return null;

  const handleSaveAndClose = () => {
    onUpdateTask({
      ...task,
      title: title.trim() || task.title,
      completed,
      color,
      notes,
      subtasks,
    });
    onClose();
  };

  const handleToggleComplete = () => {
    const nextState = !completed;
    setCompleted(nextState);
    onUpdateTask({
      ...task,
      title,
      completed: nextState,
      color,
      notes,
      subtasks,
    });
  };

  const handleColorSelect = (newColor: HighlightColor) => {
    setColor(newColor);
    setShowColorPicker(false);
    onUpdateTask({
      ...task,
      title,
      completed,
      color: newColor,
      notes,
      subtasks,
    });
  };

  const handleAddSubtask = () => {
    if (!newSubtaskTitle.trim()) return;
    const newSub: SubTask = {
      id: `sub-${Date.now()}`,
      title: newSubtaskTitle.trim(),
      completed: false,
    };
    const updated = [...subtasks, newSub];
    setSubtasks(updated);
    setNewSubtaskTitle('');
    onUpdateTask({
      ...task,
      title,
      completed,
      color,
      notes,
      subtasks: updated,
    });
  };

  const handleToggleSubtask = (subId: string) => {
    const updated = subtasks.map((s) =>
      s.id === subId ? { ...s, completed: !s.completed } : s
    );
    setSubtasks(updated);
    onUpdateTask({
      ...task,
      title,
      completed,
      color,
      notes,
      subtasks: updated,
    });
  };

  const handleDeleteSubtask = (subId: string) => {
    const updated = subtasks.filter((s) => s.id !== subId);
    setSubtasks(updated);
    onUpdateTask({
      ...task,
      title,
      completed,
      color,
      notes,
      subtasks: updated,
    });
  };

  const currentColorHex =
    COLOR_OPTIONS.find((c) => c.color === color)?.hex || (isDarkMode ? '#3F3F46' : '#DEDBD6');

  return (
    <div
      onClick={handleSaveAndClose}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-in fade-in duration-150"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className={`relative w-full max-w-xl rounded-3xl p-6 shadow-2xl transition-colors duration-200 animate-in zoom-in-95 border ${
          isDarkMode
            ? 'bg-[#18181B] text-zinc-100 border-zinc-800'
            : 'bg-white text-alur-charcoal border-alur-border'
        }`}
      >
        {/* Top Action Bar */}
        <div
          className={`flex items-center justify-between pb-3.5 border-b text-xs ${
            isDarkMode
              ? 'border-zinc-800 text-zinc-400'
              : 'border-alur-border text-alur-warmgray'
          }`}
        >
          {/* Left: Date Display */}
          <div
            className={`flex items-center gap-2 font-semibold ${
              isDarkMode ? 'text-zinc-200' : 'text-alur-charcoal'
            }`}
          >
            <CalendarIcon size={14} className={isDarkMode ? 'text-zinc-400' : 'text-alur-warmgray'} />
            <span>{dateLabel}</span>
          </div>

          {/* Right Action Icons */}
          <div className="flex items-center gap-1.5 sm:gap-2">
            {/* Theme Toggle Button (Light / Dark) */}
            <button
              type="button"
              onClick={() => setIsDarkMode(!isDarkMode)}
              className={`p-1.5 rounded-lg transition-colors ${
                isDarkMode
                  ? 'hover:bg-zinc-800 text-zinc-400 hover:text-amber-300'
                  : 'hover:bg-alur-surface text-alur-warmgray hover:text-alur-charcoal'
              }`}
              title={isDarkMode ? 'Beralih ke Light Mode' : 'Beralih ke Dark Mode'}
            >
              {isDarkMode ? <Sun size={15} /> : <Moon size={15} />}
            </button>

            {/* Delete */}
            <button
              type="button"
              onClick={() => {
                onDeleteTask(task.id);
                onClose();
              }}
              className={`p-1.5 rounded-lg transition-colors ${
                isDarkMode
                  ? 'hover:text-red-400 hover:bg-zinc-800 text-zinc-400'
                  : 'hover:text-alur-alert hover:bg-red-50 text-alur-warmgray'
              }`}
              title="Hapus Tugas"
            >
              <Trash2 size={15} />
            </button>

            {/* Repeat */}
            <button
              type="button"
              className={`p-1.5 rounded-lg transition-colors ${
                isDarkMode
                  ? 'hover:text-zinc-200 hover:bg-zinc-800 text-zinc-400'
                  : 'hover:text-alur-charcoal hover:bg-alur-surface text-alur-warmgray'
              }`}
              title="Ulangi (Repeat)"
            >
              <RotateCw size={15} />
            </button>

            {/* Color Picker Indicator */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setShowColorPicker(!showColorPicker)}
                className={`w-5 h-5 rounded-full border flex items-center justify-center hover:scale-110 transition-transform ${
                  isDarkMode ? 'border-zinc-700' : 'border-alur-border'
                }`}
                style={{ backgroundColor: currentColorHex }}
                title="Pilih Warna Stabilo"
              />

              {showColorPicker && (
                <div
                  className={`absolute right-0 top-7 z-20 flex items-center gap-1.5 p-2 rounded-xl shadow-xl border ${
                    isDarkMode
                      ? 'bg-[#27272A] border-zinc-700'
                      : 'bg-white border-alur-border'
                  }`}
                >
                  {COLOR_OPTIONS.map((opt) => (
                    <button
                      key={opt.color}
                      type="button"
                      onClick={() => handleColorSelect(opt.color)}
                      className={`w-5 h-5 rounded-full border transition-transform hover:scale-125 ${
                        isDarkMode ? 'border-zinc-700' : 'border-alur-border'
                      } ${color === opt.color ? 'ring-2 ring-alur-ink scale-110' : ''}`}
                      style={{ backgroundColor: opt.hex }}
                      title={opt.label}
                    />
                  ))}
                </div>
              )}
            </div>

            {/* Reminder Bell */}
            <button
              type="button"
              className={`p-1.5 rounded-lg transition-colors ${
                isDarkMode
                  ? 'hover:text-zinc-200 hover:bg-zinc-800 text-zinc-400'
                  : 'hover:text-alur-charcoal hover:bg-alur-surface text-alur-warmgray'
              }`}
              title="Pengingat"
            >
              <Bell size={15} />
            </button>

            {/* More */}
            <button
              type="button"
              className={`p-1.5 rounded-lg transition-colors ${
                isDarkMode
                  ? 'hover:text-zinc-200 hover:bg-zinc-800 text-zinc-400'
                  : 'hover:text-alur-charcoal hover:bg-alur-surface text-alur-warmgray'
              }`}
              title="Lainnya"
            >
              <MoreHorizontal size={15} />
            </button>

            {/* Close */}
            <button
              type="button"
              onClick={handleSaveAndClose}
              className={`p-1.5 rounded-lg transition-colors ml-1 ${
                isDarkMode
                  ? 'hover:text-zinc-200 hover:bg-zinc-800 text-zinc-400'
                  : 'hover:text-alur-charcoal hover:bg-alur-surface text-alur-warmgray'
              }`}
              title="Tutup & Simpan"
            >
              <X size={15} />
            </button>
          </div>
        </div>

        {/* Task Title + Checkbox with explicit BORDER BOTTOM */}
        <div
          className={`flex items-center gap-3 pt-5 pb-3.5 border-b ${
            isDarkMode ? 'border-zinc-800' : 'border-alur-border'
          }`}
        >
          <input
            ref={titleInputRef}
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSaveAndClose();
            }}
            placeholder="Judul tugas..."
            className={`w-full bg-transparent text-xl sm:text-2xl font-black font-title tracking-tight outline-none ${
              isDarkMode
                ? 'text-white placeholder-zinc-600'
                : 'text-alur-charcoal placeholder-alur-warmgray/50'
            } ${completed ? 'line-through opacity-50' : ''}`}
          />

          <button
            type="button"
            onClick={handleToggleComplete}
            className={`flex-shrink-0 p-1 rounded-full transition-transform hover:scale-110 ${
              isDarkMode
                ? completed
                  ? 'text-white'
                  : 'text-zinc-500 hover:text-white'
                : completed
                ? 'text-alur-ink'
                : 'text-alur-warmgray hover:text-alur-ink'
            }`}
            title={completed ? 'Tandai belum selesai' : 'Tandai selesai'}
          >
            {completed ? (
              <CheckCircle2 size={24} className="fill-current text-current" />
            ) : (
              <Circle size={24} strokeWidth={2} />
            )}
          </button>
        </div>

        {/* Rich Text Format Toolbar */}
        <div
          className={`flex items-center gap-1 pt-3 pb-2 text-sm ${
            isDarkMode ? 'text-zinc-400' : 'text-alur-warmgray'
          }`}
        >
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Heading"
          >
            <Heading size={16} />
          </button>
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Bold"
          >
            <Bold size={16} />
          </button>
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Italic"
          >
            <Italic size={16} />
          </button>
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Bullet List"
          >
            <List size={16} />
          </button>
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Align"
          >
            <AlignLeft size={16} />
          </button>
          <button
            type="button"
            className={`p-1.5 rounded transition-colors ${
              isDarkMode ? 'hover:text-white hover:bg-zinc-800' : 'hover:text-alur-charcoal hover:bg-alur-surface'
            }`}
            title="Link"
          >
            <Link2 size={16} />
          </button>
        </div>

        {/* Extra Notes Input */}
        <div className="pb-3">
          <textarea
            rows={3}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Add some extra notes here..."
            className={`w-full bg-transparent text-sm outline-none resize-none leading-relaxed ${
              isDarkMode
                ? 'text-zinc-200 placeholder-zinc-600'
                : 'text-alur-charcoal placeholder-alur-warmgray/60'
            }`}
          />
        </div>

        {/* Subtasks Section */}
        <div
          className={`pt-3 border-t space-y-2 ${
            isDarkMode ? 'border-zinc-800' : 'border-alur-border'
          }`}
        >
          {subtasks.map((sub) => (
            <div
              key={sub.id}
              className={`flex items-center justify-between gap-2 py-1 px-1.5 rounded group transition-colors ${
                isDarkMode ? 'hover:bg-zinc-800/50' : 'hover:bg-alur-surface/50'
              }`}
            >
              <div className="flex items-center gap-2 flex-1 min-w-0">
                <button
                  type="button"
                  onClick={() => handleToggleSubtask(sub.id)}
                  className={`flex-shrink-0 w-3.5 h-3.5 rounded border flex items-center justify-center transition-colors ${
                    sub.completed
                      ? isDarkMode
                        ? 'bg-zinc-200 border-zinc-200 text-black'
                        : 'bg-alur-ink border-alur-ink text-white'
                      : isDarkMode
                      ? 'border-zinc-600 hover:border-zinc-400'
                      : 'border-alur-warmgray/60 hover:border-alur-ink'
                  }`}
                >
                  {sub.completed && <CheckCircle2 size={10} />}
                </button>
                <span
                  className={`text-xs ${
                    sub.completed
                      ? 'line-through text-alur-warmgray opacity-60'
                      : isDarkMode
                      ? 'text-zinc-300'
                      : 'text-alur-charcoal'
                  }`}
                >
                  {sub.title}
                </span>
              </div>
              <button
                type="button"
                onClick={() => handleDeleteSubtask(sub.id)}
                className={`opacity-0 group-hover:opacity-100 p-1 transition-opacity ${
                  isDarkMode
                    ? 'text-zinc-500 hover:text-red-400'
                    : 'text-alur-warmgray hover:text-alur-alert'
                }`}
              >
                <X size={12} />
              </button>
            </div>
          ))}

          {/* Add Subtask Input */}
          <div
            className={`flex items-center gap-2 pt-1.5 ${
              isDarkMode ? 'text-zinc-500' : 'text-alur-warmgray'
            }`}
          >
            <Plus size={14} />
            <input
              type="text"
              value={newSubtaskTitle}
              onChange={(e) => setNewSubtaskTitle(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  handleAddSubtask();
                }
              }}
              placeholder="Add subtask... (press Enter)"
              className={`w-full bg-transparent text-xs outline-none ${
                isDarkMode
                  ? 'text-zinc-300 placeholder-zinc-600'
                  : 'text-alur-charcoal placeholder-alur-warmgray/60'
              }`}
            />
            <Paperclip
              size={14}
              className={`cursor-pointer transition-colors ${
                isDarkMode ? 'hover:text-zinc-300' : 'hover:text-alur-charcoal'
              }`}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
