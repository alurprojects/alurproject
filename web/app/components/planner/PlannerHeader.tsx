'use client';

import React from 'react';
import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react';

interface PlannerHeaderProps {
  currentMonthYear: string;
  weekRangeText: string;
  capacityLine: string | null;
  isOverload: boolean;
  onPrevWeek: () => void;
  onNextWeek: () => void;
  onResetToday: () => void;
  onOpenGoals: () => void;
  goalsCount: number;
  totalWeekTasks: number;
  completedWeekTasks: number;
  userEmail?: string | null;
  onLogout?: () => void;
}

export const PlannerHeader: React.FC<PlannerHeaderProps> = ({
  currentMonthYear,
  weekRangeText,
  capacityLine,
  isOverload,
  onPrevWeek,
  onNextWeek,
  onResetToday,
  onOpenGoals,
  goalsCount,
  totalWeekTasks,
  completedWeekTasks,
  userEmail,
  onLogout,
}) => {
  return (
    <header className="flex flex-wrap items-center justify-between gap-4 py-5 px-6 border-b border-alur-border bg-alur-bg sticky top-0 z-20">
      <div className="flex items-baseline gap-3">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-alur-ink font-title">
          {currentMonthYear}
        </h1>
        <span className="text-xs font-semibold text-alur-warmgray tracking-wide hidden sm:inline-block">
          {weekRangeText}
        </span>
      </div>

      <div className="flex items-center gap-3">
        {capacityLine && (
          <div
            className={`hidden md:flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${
              isOverload ? 'bg-red-50 text-alur-alert border border-alur-alert/30' : 'bg-alur-surface text-alur-charcoal'
            }`}
            title="Total estimasi tugas hari ini dibanding kapasitas harian"
          >
            <span className={`w-1.5 h-1.5 rounded-full ${isOverload ? 'bg-alur-alert' : 'bg-alur-ink'}`} />
            <span>{capacityLine}</span>
          </div>
        )}

        {totalWeekTasks > 0 && (
          <div className="hidden md:flex items-center gap-1.5 px-3 py-1 rounded-full bg-alur-surface text-xs font-medium text-alur-charcoal">
            <span className="w-1.5 h-1.5 rounded-full bg-alur-ink" />
            <span>
              {completedWeekTasks} / {totalWeekTasks} selesai
            </span>
          </div>
        )}

        <button
          type="button"
          onClick={onOpenGoals}
          className="flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-bold rounded-full bg-alur-ink text-alur-bg hover:opacity-90 transition-opacity shadow-xs"
          title="Kelola Goal — sumber Target Harian"
        >
          <Calendar size={13} />
          <span>Goal{goalsCount > 0 ? ` (${goalsCount})` : ''}</span>
        </button>

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

        {userEmail && (
          <div className="flex items-center gap-2">
            <span className="hidden lg:inline max-w-[180px] truncate text-[11px] text-alur-warmgray" title={userEmail}>
              {userEmail}
            </span>
            <button
              type="button"
              onClick={onLogout}
              className="px-3 py-1.5 text-[11px] font-bold rounded-full border border-alur-border text-alur-warmgray hover:text-alur-charcoal hover:bg-alur-surface transition-colors"
              title="Keluar"
            >
              Keluar
            </button>
          </div>
        )}
      </div>
    </header>
  );
};
