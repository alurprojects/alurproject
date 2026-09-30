'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { PlannerHeader } from './components/planner/PlannerHeader';
import { WeekGrid } from './components/planner/WeekGrid';
import { SomedayDrawer } from './components/planner/SomedayDrawer';
import { BrainDumpModal } from './components/planner/BrainDumpModal';
import { TaskEditModal } from './components/planner/TaskEditModal';
import { PlannerTask, DayInfo } from './components/planner/types';

const DAY_NAMES = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
const DAY_SHORT_EN = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
];
const FULL_MONTH_NAMES = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

function getMonday(d: Date): Date {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(date.setDate(diff));
}

function formatDateISO(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

const STORAGE_KEY = 'alur_planner_tasks_v3';

export default function HomePage() {
  const [currentMonday, setCurrentMonday] = useState<Date>(() => getMonday(new Date()));
  const [tasks, setTasks] = useState<PlannerTask[]>([]);
  const [isSomedayOpen, setIsSomedayOpen] = useState(true);
  const [isBrainDumpOpen, setIsBrainDumpOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<PlannerTask | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);

  const today = useMemo(() => new Date(), []);
  const todayStr = useMemo(() => formatDateISO(today), [today]);

  // Load initial tasks or generate full-width mockup
  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        setTasks(JSON.parse(saved));
      } else {
        const mon = getMonday(new Date());
        const d1 = formatDateISO(mon);
        const d2 = formatDateISO(new Date(mon.getTime() + 1 * 86400000));
        const d3 = formatDateISO(new Date(mon.getTime() + 2 * 86400000));
        const d5 = formatDateISO(new Date(mon.getTime() + 4 * 86400000));

        const initial: PlannerTask[] = [
          {
            id: 't-1',
            title: 'Arahkan kursor untuk centang tugas',
            completed: false,
            dateStr: d1,
            color: 'none',
            timeEstimate: '15m',
            order: 0,
          },
          {
            id: 't-2',
            title: 'Klik teks langsung untuk membuka popup edit',
            completed: false,
            dateStr: d1,
            color: 'none',
            order: 1,
          },
          {
            id: 't-3',
            title: 'Seret (drag) tugas ke hari lain',
            completed: false,
            dateStr: d1,
            color: 'none',
            order: 2,
          },
          {
            id: 't-4',
            title: 'Pilih warna stabilo untuk prioritas',
            completed: false,
            dateStr: d2,
            color: 'yellow',
            notes: 'Catatan tambahan untuk tugas penting ini bisa ditulis di dalam popup edit.',
            subtasks: [
              { id: 'sub-1', title: 'Subtugas bagian A', completed: true },
              { id: 'sub-2', title: 'Subtugas bagian B', completed: false },
            ],
            order: 0,
          },
          {
            id: 't-5',
            title: 'Fokus tenang tanpa distraksi',
            completed: false,
            dateStr: d2,
            color: 'peach',
            timeEstimate: '45m',
            order: 1,
          },
          {
            id: 't-6',
            title: 'Minimalis & rapi!',
            completed: false,
            dateStr: d3,
            color: 'green',
            order: 0,
          },
          {
            id: 't-7',
            title: 'Tumpahkan ide ke AI Brain-dump',
            completed: false,
            dateStr: d5,
            color: 'blue',
            order: 0,
          },
          {
            id: 't-8',
            title: 'Rencana jangka panjang kuartal depan',
            completed: false,
            dateStr: 'someday',
            color: 'none',
            order: 0,
          },
        ];
        setTasks(initial);
      }
    } catch (e) {
      console.error('Error loading planner tasks', e);
    } finally {
      setIsInitialized(true);
    }
  }, []);

  // Save to localStorage
  useEffect(() => {
    if (isInitialized) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
      } catch (e) {
        console.error('Error saving planner tasks', e);
      }
    }
  }, [tasks, isInitialized]);

  // Generate 7 days for current week
  const weekDays = useMemo<DayInfo[]>(() => {
    return Array.from({ length: 7 }).map((_, i) => {
      const d = new Date(currentMonday);
      d.setDate(currentMonday.getDate() + i);
      const dateStr = formatDateISO(d);
      const isWeekend = i === 5 || i === 6;

      const fullDateText = `${DAY_SHORT_EN[i]}, ${d.getDate()} ${MONTH_NAMES[d.getMonth()]} ${d.getFullYear()}`;

      return {
        dateStr,
        dayName: DAY_NAMES[i],
        dayNumber: String(d.getDate()),
        monthName: MONTH_NAMES[d.getMonth()],
        isToday: dateStr === todayStr,
        isWeekend,
        fullDateText,
      };
    });
  }, [currentMonday, todayStr]);

  // Header texts
  const currentMonthYear = useMemo(() => {
    const month = FULL_MONTH_NAMES[currentMonday.getMonth()];
    const year = currentMonday.getFullYear();
    return `${month} ${year}`;
  }, [currentMonday]);

  const weekRangeText = useMemo(() => {
    const endOfWeek = new Date(currentMonday);
    endOfWeek.setDate(currentMonday.getDate() + 6);
    return `${currentMonday.getDate()} ${MONTH_NAMES[currentMonday.getMonth()]} – ${endOfWeek.getDate()} ${MONTH_NAMES[endOfWeek.getMonth()]}`;
  }, [currentMonday]);

  // Task stats
  const weekDateSet = useMemo(() => new Set(weekDays.map((d) => d.dateStr)), [weekDays]);
  const currentWeekTasks = useMemo(() => tasks.filter((t) => weekDateSet.has(t.dateStr)), [tasks, weekDateSet]);
  const completedWeekTasks = useMemo(() => currentWeekTasks.filter((t) => t.completed).length, [currentWeekTasks]);
  const somedayTasks = useMemo(() => tasks.filter((t) => t.dateStr === 'someday'), [tasks]);

  // Navigation
  const handlePrevWeek = () => {
    const next = new Date(currentMonday);
    next.setDate(currentMonday.getDate() - 7);
    setCurrentMonday(next);
  };

  const handleNextWeek = () => {
    const next = new Date(currentMonday);
    next.setDate(currentMonday.getDate() + 7);
    setCurrentMonday(next);
  };

  const handleResetToday = () => {
    setCurrentMonday(getMonday(new Date()));
  };

  // Task Mutations
  const handleAddTask = useCallback((dateStr: string, title: string) => {
    const newTask: PlannerTask = {
      id: `task-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      title,
      completed: false,
      dateStr,
      color: 'none',
      order: Date.now(),
    };
    setTasks((prev) => [...prev, newTask]);
  }, []);

  const handleToggleTask = useCallback((id: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t))
    );
  }, []);

  const handleUpdateTask = useCallback((updated: PlannerTask) => {
    setTasks((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
    setEditingTask(null);
  }, []);

  const handleDeleteTask = useCallback((id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
    setEditingTask(null);
  }, []);

  const handleMoveToDate = useCallback((taskId: string, targetDateStr: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === taskId ? { ...t, dateStr: targetDateStr } : t))
    );
  }, []);

  const handleBrainDumpSubmit = useCallback((items: string[], targetDateStr: string) => {
    const newItems: PlannerTask[] = items.map((title, idx) => ({
      id: `task-${Date.now()}-${idx}`,
      title,
      completed: false,
      dateStr: targetDateStr,
      color: 'none',
      order: Date.now() + idx,
    }));
    setTasks((prev) => [...prev, ...newItems]);
  }, []);

  // Compute date label for modal
  const editingDateLabel = useMemo(() => {
    if (!editingTask) return '';
    if (editingTask.dateStr === 'someday') return 'Someday (Belum Terjadwal)';
    const day = weekDays.find((d) => d.dateStr === editingTask.dateStr);
    if (day) return day.fullDateText;
    return editingTask.dateStr;
  }, [editingTask, weekDays]);

  return (
    <main className="min-h-screen bg-alur-bg font-sans flex flex-col text-alur-charcoal selection:bg-alur-ink selection:text-white">
      {/* Header */}
      <PlannerHeader
        currentMonthYear={currentMonthYear}
        weekRangeText={weekRangeText}
        onPrevWeek={handlePrevWeek}
        onNextWeek={handleNextWeek}
        onResetToday={handleResetToday}
        onOpenBrainDump={() => setIsBrainDumpOpen(true)}
        onToggleSomeday={() => setIsSomedayOpen(!isSomedayOpen)}
        isSomedayOpen={isSomedayOpen}
        somedayCount={somedayTasks.length}
        totalWeekTasks={currentWeekTasks.length}
        completedWeekTasks={completedWeekTasks}
      />

      {/* Week Grid with Full-Width Cards */}
      <WeekGrid
        days={weekDays}
        tasks={tasks}
        onAddTask={handleAddTask}
        onToggleTask={handleToggleTask}
        onOpenEdit={(task) => setEditingTask(task)}
        onDropTask={handleMoveToDate}
      />

      {/* Someday Drawer */}
      <SomedayDrawer
        tasks={somedayTasks}
        isOpen={isSomedayOpen}
        onToggleOpen={() => setIsSomedayOpen(!isSomedayOpen)}
        onAddTask={(title) => handleAddTask('someday', title)}
        onToggleTask={handleToggleTask}
        onOpenEdit={(task) => setEditingTask(task)}
        onMoveToDate={handleMoveToDate}
        todayDateStr={todayStr}
      />

      {/* Quick AI Brain-dump Modal */}
      <BrainDumpModal
        isOpen={isBrainDumpOpen}
        onClose={() => setIsBrainDumpOpen(false)}
        onSubmit={handleBrainDumpSubmit}
        todayDateStr={todayStr}
      />

      {/* Tweek-style Task Edit Popup Modal */}
      <TaskEditModal
        task={editingTask}
        isOpen={!!editingTask}
        onClose={() => setEditingTask(null)}
        onUpdateTask={handleUpdateTask}
        onDeleteTask={handleDeleteTask}
        dateLabel={editingDateLabel}
      />
    </main>
  );
}
