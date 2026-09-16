'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { api, Task, AIInsight } from '@/lib/api';
import { DayBlock } from './components/DayBlock';
import { BrainDumpModal } from './components/BrainDumpModal';
import { InsightBanner } from './components/InsightBanner';
import { Sparkles, ChevronLeft, ChevronRight, RotateCcw } from 'lucide-react';

const DAY_NAMES = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];

function getMonday(d: Date): Date {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(date.setDate(diff));
}

function formatDateISO(date: Date): string {
  return date.toISOString().split('T')[0];
}

function formatDateShort(date: Date): string {
  const options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short' };
  return date.toLocaleDateString('id-ID', options);
}

export default function WeeklyPlannerPage() {
  const [currentMonday, setCurrentMonday] = useState<Date>(() => getMonday(new Date()));
  const [tasks, setTasks] = useState<Task[]>([]);
  const [insight, setInsight] = useState<AIInsight | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isBrainDumpOpen, setIsBrainDumpOpen] = useState<boolean>(false);

  const todayStr = formatDateISO(new Date());
  const weekStartStr = formatDateISO(currentMonday);

  // Generate 7 days for the current week
  const weekDays = Array.from({ length: 7 }).map((_, i) => {
    const d = new Date(currentMonday);
    d.setDate(currentMonday.getDate() + i);
    const dateStr = formatDateISO(d);
    return {
      dayName: DAY_NAMES[i],
      dateStr,
      formattedDate: formatDateShort(d),
      isToday: dateStr === todayStr,
    };
  });

  const loadData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [fetchedTasks, insights] = await Promise.all([
        api.getTasks(weekStartStr),
        api.getSurfacedInsights().catch(() => []),
      ]);
      setTasks(fetchedTasks || []);
      setInsight(insights && insights.length > 0 ? insights[0] : null);
    } catch (err) {
      console.error('Failed to load tasks:', err);
    } finally {
      setIsLoading(false);
    }
  }, [weekStartStr]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Week navigation
  const prevWeek = () => {
    const next = new Date(currentMonday);
    next.setDate(currentMonday.getDate() - 7);
    setCurrentMonday(next);
  };

  const nextWeek = () => {
    const next = new Date(currentMonday);
    next.setDate(currentMonday.getDate() + 7);
    setCurrentMonday(next);
  };

  const resetToToday = () => {
    setCurrentMonday(getMonday(new Date()));
  };

  // Task actions
  const handleToggleTask = async (id: string, status: string) => {
    await api.toggleTask(id, status);
    await loadData();
  };

  const handleDeleteTask = async (id: string) => {
    await api.deleteTask(id);
    await loadData();
  };

  const handleClarifyTask = async (id: string, minutes: number) => {
    await api.clarifyTask(id, minutes);
    await loadData();
  };

  const handleFollowUpTask = async (id: string, action: 'LUPA' | 'SKIP' | 'PINDAH') => {
    await api.followUpTask(id, action);
    await loadData();
  };

  const handleRescheduleTask = async (
    id: string,
    action: 'ACCEPT' | 'REJECT',
    targetDate?: string,
    suggestionId?: string
  ) => {
    await api.rescheduleTask(id, action, targetDate, suggestionId);
    await loadData();
  };

  const handleAddTask = async (title: string, assignedDate: string) => {
    await api.createTask(title, assignedDate);
    await loadData();
  };

  const handleBrainDumpSubmit = async (text: string) => {
    await api.brainDump(text);
    await loadData();
  };

  return (
    <main className="max-w-3xl mx-auto px-4 py-8 sm:py-12">
      {/* Top Bar / Header */}
      <header className="mb-8 flex items-center justify-between gap-4 border-b border-alur-border pb-6">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-alur-ink">
            ALUR
          </h1>
          <p className="text-xs font-medium text-alur-warmgray mt-0.5">
            Quiet Monochrome Weekly Notebook
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2">
          {/* Week Selector */}
          <div className="flex items-center rounded-lg border border-alur-border bg-alur-surface/60 p-0.5 text-xs">
            <button
              onClick={prevWeek}
              className="p-1.5 hover:bg-alur-bg rounded text-alur-warmgray hover:text-alur-charcoal transition-colors"
              title="Minggu Sebelumnya"
            >
              <ChevronLeft size={16} />
            </button>
            <button
              onClick={resetToToday}
              className="px-2.5 py-1 font-semibold text-alur-charcoal hover:bg-alur-bg rounded transition-colors"
              title="Kembali ke Hari Ini"
            >
              Hari Ini
            </button>
            <button
              onClick={nextWeek}
              className="p-1.5 hover:bg-alur-bg rounded text-alur-warmgray hover:text-alur-charcoal transition-colors"
              title="Minggu Depan"
            >
              <ChevronRight size={16} />
            </button>
          </div>

          {/* Brain-dump FAB */}
          <button
            onClick={() => setIsBrainDumpOpen(true)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold rounded-lg bg-alur-ink text-alur-bg hover:bg-alur-charcoal transition-colors shadow-xs"
          >
            <Sparkles size={14} />
            <span className="hidden sm:inline">Brain-dump</span>
          </button>
        </div>
      </header>

      {/* Surfaced Weekly Insight Banner */}
      <InsightBanner insight={insight} />

      {/* 7-Day Accordion Container */}
      <section className="space-y-3">
        {weekDays.map((day) => {
          const dayTasks = tasks.filter((t) => t.assigned_date === day.dateStr);
          return (
            <DayBlock
              key={day.dateStr}
              dayName={day.dayName}
              dateStr={day.dateStr}
              formattedDate={day.formattedDate}
              isToday={day.isToday}
              tasks={dayTasks}
              onToggleTask={handleToggleTask}
              onDeleteTask={handleDeleteTask}
              onClarifyTask={handleClarifyTask}
              onFollowUpTask={handleFollowUpTask}
              onRescheduleTask={handleRescheduleTask}
              onAddTask={handleAddTask}
              onOpenBrainDump={() => setIsBrainDumpOpen(true)}
            />
          );
        })}
      </section>

      {/* Brain Dump Modal Dialog */}
      <BrainDumpModal
        isOpen={isBrainDumpOpen}
        onClose={() => setIsBrainDumpOpen(false)}
        onSubmit={handleBrainDumpSubmit}
      />
    </main>
  );
}
