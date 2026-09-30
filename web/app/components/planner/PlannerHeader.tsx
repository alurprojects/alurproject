'use client';

import React from 'react';
import { ChevronLeft, ChevronRight, Calendar, Sparkles, Inbox } from 'lucide-react';

interface PlannerHeaderProps {
  currentMonthYear: string;
  weekRangeText: string;
  onPrevWeek: () => void;
  onNextWeek: () => void;
  onResetToday: () => void;
  onOpenBrainDump: () => void;
  onToggleSomeday: () => void;
  isSomedayOpen: boolean;
  somedayCount: number;
  totalWeekTasks: number;
  completedWeekTasks: number;
}

export const PlannerHeader: React.FC<PlannerHeaderProps> = ({
  currentMonthYear,
  weekRangeText,
  onPrevWeek,
  onNextWeek,
  onResetToday,
  onOpenBrainDump,
  onToggleSomeday,
  isSomedayOpen,
  somedayCount,
  totalWeekTasks,
  completedWeekTasks,
}) => {
  return (
    <header className="flex flex-wrap items-center justify-between gap-4 py-5 px-6 border-b border-alur-border bg-alur-bg sticky top-0 z-20">
      {/* Left: Month Year Display & Range */}
      <div className="flex items-baseline gap-3">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-alur-ink font-title">
          {currentMonthYear}
        </h1>
        <span className="text-xs font-semibold text-alur-warmgray tracking-wide hidden sm:inline-block">
          {weekRangeText}
        </span>
      </div>

      {/* Right Controls: Navigation & Actions */}
      <div className="flex items-center gap-3">
        {/* Week Summary Badge */}
        {totalWeekTasks > 0 && (
          <div className="hidden md:flex items-center gap-1.5 px-3 py-1 rounded-full bg-alur-surface text-xs font-medium text-alur-charcoal">
            <span className="w-1.5 h-1.5 rounded-full bg-alur-ink" />
            <span>
              {completedWeekTasks} / {totalWeekTasks} selesai
            </span>
          </div>
        )}

        {/* Someday Drawer Trigger */}
        <button
          type="button"
          onClick={onToggleSomeday}
          className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-full border transition-all ${
            isSomedayOpen
              ? 'bg-alur-ink text-white border-alur-ink'
              : 'bg-alur-surface/60 text-alur-charcoal border-alur-border hover:bg-alur-surface'
          }`}
          title="Tampilkan daftar Belum Terjadwal (Someday)"
        >
          <Inbox size={13} />
          <span>Someday</span>
          {somedayCount > 0 && (
            <span
              className={`px-1.5 py-0.2 rounded-full text-[10px] font-bold ${
                isSomedayOpen ? 'bg-white text-alur-ink' : 'bg-alur-border text-alur-charcoal'
              }`}
            >
              {somedayCount}
            </span>
          )}
        </button>

        {/* Brain Dump AI Button */}
        <button
          type="button"
          onClick={onOpenBrainDump}
          className="flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-bold rounded-full bg-alur-ink text-alur-bg hover:opacity-90 transition-opacity shadow-xs"
          title="Tulis banyak tugas sekaligus atau curhat untuk diurai AI"
        >
          <Sparkles size={13} />
          <span>Brain-dump</span>
        </button>

        {/* Week Navigation Buttons */}
        <div className="flex items-center rounded-full border border-alur-border bg-alur-surface/60 p-0.5">
          <button
            type="button"
            onClick={onPrevWeek}
            className="p-1.5 hover:bg-alur-bg rounded-full text-alur-warmgray hover:text-alur-charcoal transition-colors"
            title="Minggu Sebelumnya"
          >
            <ChevronLeft size={16} />
          </button>
          <button
            type="button"
            onClick={onResetToday}
            className="px-3 py-1 text-xs font-bold text-alur-charcoal hover:bg-alur-bg rounded-full transition-colors"
            title="Lompat ke Hari Ini"
          >
            Hari Ini
          </button>
          <button
            type="button"
            onClick={onNextWeek}
            className="p-1.5 hover:bg-alur-bg rounded-full text-alur-warmgray hover:text-alur-charcoal transition-colors"
            title="Minggu Berikutnya"
          >
            <ChevronRight size={16} />
          </button>
        </div>
      </div>
    </header>
  );
};
