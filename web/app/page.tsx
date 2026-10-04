'use client';

import React, { useState, useEffect, useMemo, useCallback, useRef, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { Plus } from 'lucide-react';
import { PlannerHeader } from './components/planner/PlannerHeader';
import { TaskItem } from './components/planner/TaskItem';
import { TaskEditModal } from './components/planner/TaskEditModal';
import { GoalPanel } from './components/planner/GoalPanel';
import { AuthScreen } from './components/AuthScreen';
import { PlannerTask, DayInfo, toPlannerTask } from './components/planner/types';
import { api, Goal, Task } from '../lib/api';
import { getSupabaseBrowser, persistAccessToken } from '../lib/supabase-browser';

const DAY_NAMES = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
const DAY_SHORT_EN = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
const FULL_MONTH_NAMES = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

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

// Fase 1 web-first: Target Harian tersambung API. Tanpa localStorage,
// tanpa Someday, tanpa BrainDumpModal (quick-add 1 baris per kolom).
const ENV_READY = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

function PlannerGate() {
  const searchParams = useSearchParams();
  const authError = searchParams.get('auth_error') === '1';
  const [authChecked, setAuthChecked] = useState(false);
  const [authed, setAuthed] = useState(false);
  const [authEmail, setAuthEmail] = useState<string | null>(null);
  const [currentMonday, setCurrentMonday] = useState<Date>(() => getMonday(new Date()));
  const [tasks, setTasks] = useState<PlannerTask[]>([]);
  const [goals, setGoals] = useState<Goal[]>([]);
  const [capacityHours, setCapacityHours] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingTask, setEditingTask] = useState<PlannerTask | null>(null);
  const [clarifyTask, setClarifyTask] = useState<PlannerTask | null>(null);
  const [clarifyMinutes, setClarifyMinutes] = useState('');
  const [isGoalOpen, setIsGoalOpen] = useState(false);
  const [goalError, setGoalError] = useState<string | null>(null);

  const today = useMemo(() => new Date(), []);
  const todayStr = useMemo(() => formatDateISO(today), [today]);
  const mondayStr = useMemo(() => formatDateISO(currentMonday), [currentMonday]);

  useEffect(() => {
    let cancelled = false;
    async function checkAuth() {
      if (!ENV_READY) {
        setAuthChecked(true);
        setAuthed(false);
        return;
      }
      try {
        const supabase = getSupabaseBrowser();
        const { data } = await supabase.auth.getSession();
        const session = data.session;
        if (!cancelled) {
          persistAccessToken(session?.access_token ?? null);
          setAuthed(Boolean(session));
          setAuthEmail(session?.user?.email ?? null);
        }
      } catch {
        if (!cancelled) setAuthed(false);
      } finally {
        if (!cancelled) setAuthChecked(true);
      }
    }
    checkAuth();
    if (!ENV_READY) return () => {};
    const supabase = getSupabaseBrowser();
    const { data: listener } = supabase.auth.onAuthStateChange(
      (
        _event: string,
        session: { access_token?: string; user?: { email?: string } } | null
      ) => {
        if (cancelled) return;
        persistAccessToken(session?.access_token ?? null);
        setAuthed(Boolean(session));
        setAuthEmail(session?.user?.email ?? null);
        setAuthChecked(true);
      }
    );
    return () => {
      cancelled = true;
      listener.subscription.unsubscribe();
    };
  }, []);

  const handleLogout = useCallback(async () => {
    try {
      const supabase = getSupabaseBrowser();
      await supabase.auth.signOut();
    } finally {
      persistAccessToken(null);
      setAuthed(false);
      setAuthEmail(null);
      setTasks([]);
      setGoals([]);
    }
  }, []);

  const load = useCallback(async () => {
    if (!authed) return;
    setLoading(true);
    setError(null);
    try {
      const [week, goalList] = await Promise.all([api.getWeek(mondayStr), api.listGoals().catch(() => [] as Goal[])]);
      const goalMap = new Map(goalList.map((g) => [g.id, g.title]));
      const flat: PlannerTask[] = week.days.flatMap((d) =>
        d.tasks.map((t) => toPlannerTask({ ...t, goal_title: t.goal_id ? goalMap.get(t.goal_id) ?? null : null }))
      );
      setTasks(flat);
      setGoals(goalList);
      try {
        const me = await api.getMe();
        setCapacityHours(me.daily_capacity_hours ?? null);
      } catch {
        setCapacityHours(null);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Gagal memuat Target Harian');
    } finally {
      setLoading(false);
    }
  }, [mondayStr, authed]);

  useEffect(() => {
    load();
  }, [load]);

  const weekDays = useMemo<DayInfo[]>(() => {
    return Array.from({ length: 7 }).map((_, i) => {
      const d = new Date(currentMonday);
      d.setDate(currentMonday.getDate() + i);
      const dateStr = formatDateISO(d);
      return {
        dateStr,
        dayName: DAY_NAMES[i],
        dayNumber: String(d.getDate()),
        monthName: MONTH_NAMES[d.getMonth()],
        isToday: dateStr === todayStr,
        isWeekend: i === 5 || i === 6,
        fullDateText: `${DAY_SHORT_EN[i]}, ${d.getDate()} ${MONTH_NAMES[d.getMonth()]} ${d.getFullYear()}`,
      };
    });
  }, [currentMonday, todayStr]);

  const currentMonthYear = useMemo(
    () => `${FULL_MONTH_NAMES[currentMonday.getMonth()]} ${currentMonday.getFullYear()}`,
    [currentMonday]
  );
  const weekRangeText = useMemo(() => {
    const end = new Date(currentMonday);
    end.setDate(currentMonday.getDate() + 6);
    return `${currentMonday.getDate()} ${MONTH_NAMES[currentMonday.getMonth()]} – ${end.getDate()} ${MONTH_NAMES[end.getMonth()]}`;
  }, [currentMonday]);

  const weekDateSet = useMemo(() => new Set(weekDays.map((d) => d.dateStr)), [weekDays]);
  const currentWeekTasks = useMemo(() => tasks.filter((t) => weekDateSet.has(t.dateStr)), [tasks, weekDateSet]);
  const completedWeekTasks = useMemo(() => currentWeekTasks.filter((t) => t.completed).length, [currentWeekTasks]);

  const todayTasks = useMemo(() => tasks.filter((t) => t.dateStr === todayStr && !t.completed), [tasks, todayStr]);
  const todayMinutes = useMemo(
    () => todayTasks.reduce((sum, t) => sum + (t.estimatedMinutes ?? 0), 0),
    [todayTasks]
  );
  const capacityLine = useMemo(() => {
    if (capacityHours == null) return null;
    const h = (todayMinutes / 60).toFixed(1).replace('.', ',');
    const cap = String(capacityHours).replace('.', ',');
    return `${h} dari ${cap} jam`;
  }, [todayMinutes, capacityHours]);
  const isOverload = capacityHours != null && todayMinutes > capacityHours * 60;

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
  const handleResetToday = () => setCurrentMonday(getMonday(new Date()));

  const refreshTasks = useCallback(
    async (updated: Task) => {
      setTasks((prev) => {
        const goalTitle = updated.goal_id ? goals.find((g) => g.id === updated.goal_id)?.title ?? null : null;
        const mapped = toPlannerTask({ ...updated, goal_title: goalTitle });
        if (!weekDateSet.has(mapped.dateStr)) return prev.filter((t) => t.id !== mapped.id);
        const exists = prev.some((t) => t.id === mapped.id);
        return exists ? prev.map((t) => (t.id === mapped.id ? mapped : t)) : [...prev, mapped];
      });
    },
    [goals, weekDateSet]
  );

  const handleAddTask = useCallback(
    async (dateStr: string, title: string) => {
      const created = await api.createTask(title, dateStr);
      await refreshTasks(created);
    },
    [refreshTasks]
  );

  const handleToggleTask = useCallback(
    async (id: string) => {
      const current = tasks.find((t) => t.id === id);
      if (!current) return;
      const updated = await api.toggleTask(id, current.status);
      await refreshTasks(updated);
    },
    [tasks, refreshTasks]
  );

  const handleUpdateTask = useCallback(
    async (id: string, patch: { title?: string; assigned_date?: string; estimated_minutes?: number | null; goal_id?: string | null }) => {
      const updated = await api.updateTask(id, patch);
      await refreshTasks(updated);
      setEditingTask(null);
    },
    [refreshTasks]
  );

  const handleDeleteTask = useCallback(async (id: string) => {
    await api.deleteTask(id);
    setTasks((prev) => prev.filter((t) => t.id !== id));
    setEditingTask(null);
  }, []);

  const handleMoveToDate = useCallback(
    async (taskId: string, targetDateStr: string) => {
      const updated = await api.moveTask(taskId, targetDateStr);
      await refreshTasks(updated);
    },
    [refreshTasks]
  );

  const handleClarify = useCallback(
    async () => {
      if (!clarifyTask) return;
      const minutes = Number(clarifyMinutes);
      if (!Number.isInteger(minutes) || minutes <= 0) return;
      const updated = await api.clarifyTask(clarifyTask.id, minutes);
      await refreshTasks(updated);
      setClarifyTask(null);
      setClarifyMinutes('');
    },
    [clarifyTask, clarifyMinutes, refreshTasks]
  );

  const handleCreateGoal = useCallback(async (input: { title: string; deadline?: string; target_hours_per_week?: number }) => {
    setGoalError(null);
    try {
      const created = await api.createGoal(input);
      setGoals((prev) => [...prev, created]);
    } catch (e) {
      setGoalError(e instanceof Error ? e.message : 'Gagal membuat goal');
      throw e;
    }
  }, []);

  const handleDeleteGoal = useCallback(async (id: string) => {
    await api.deleteGoal(id);
    setGoals((prev) => prev.filter((g) => g.id !== id));
  }, []);

  const editingDateLabel = useMemo(() => {
    if (!editingTask) return '';
    const day = weekDays.find((d) => d.dateStr === editingTask.dateStr);
    return day ? day.fullDateText : editingTask.dateStr;
  }, [editingTask, weekDays]);

  if (!authChecked) {
    return (
      <p className="px-6 py-10 text-sm text-alur-warmgray">Memeriksa sesi...</p>
    );
  }

  if (!authed) {
    return <AuthScreen envReady={ENV_READY} authError={authError} />;
  }

  return (
    <main className="min-h-screen bg-alur-bg font-sans flex flex-col text-alur-charcoal selection:bg-alur-ink selection:text-white">
      <PlannerHeader
        currentMonthYear={currentMonthYear}
        weekRangeText={weekRangeText}
        capacityLine={capacityLine}
        isOverload={isOverload}
        onPrevWeek={handlePrevWeek}
        onNextWeek={handleNextWeek}
        onResetToday={handleResetToday}
        onOpenGoals={() => setIsGoalOpen(true)}
        goalsCount={goals.length}
        totalWeekTasks={currentWeekTasks.length}
        completedWeekTasks={completedWeekTasks}
        userEmail={authEmail}
        onLogout={handleLogout}
      />

      {isOverload && (
        <div className="px-6 pt-4">
          <p className="text-xs font-semibold text-alur-alert bg-red-50 border border-alur-alert/30 rounded-lg px-3 py-2">
            Beban hari ini melebihi kapasitas. Kurangi atau pindahkan tugas agar Target Harian tetap realistis.
          </p>
        </div>
      )}

      {loading ? (
        <p className="px-6 py-10 text-sm text-alur-warmgray">Memuat Target Harian...</p>
      ) : error ? (
        <div className="px-6 py-10">
          <p className="text-sm text-alur-alert">{error}</p>
          <button type="button" onClick={load} className="mt-3 px-4 py-2 text-xs font-bold rounded-lg bg-alur-ink text-white">
            Coba lagi
          </button>
        </div>
      ) : (
        <>
          <div className="flex-1 overflow-x-auto min-h-[520px]">
            <div className="flex min-w-[1050px] w-full border-b border-alur-border">
              {weekDays.map((day) => (
                <div key={day.dateStr} className="flex-1">
                  {/* DayColumn inline agar tidak bawa Someday/BrainDump */}
                  <DayColumnInline
                    day={day}
                    tasks={tasks.filter((t) => t.dateStr === day.dateStr)}
                    onAddTask={handleAddTask}
                    onToggleTask={handleToggleTask}
                    onOpenEdit={setEditingTask}
                    onDropTask={handleMoveToDate}
                    onClarify={(t) => {
                      setClarifyTask(t);
                      setClarifyMinutes('');
                    }}
                  />
                </div>
              ))}
            </div>
          </div>

          {currentWeekTasks.length === 0 && (
            <div className="px-6 py-10 text-center">
              <p className="text-sm font-bold">Target Harian masih kosong</p>
              <p className="mt-1 text-xs text-alur-warmgray">
                Tambahkan 1 goal atau tulis tugas pertama di kolom hari ini. Morning Brief butuh bahan untuk memilih Top 3.
              </p>
              <button
                type="button"
                onClick={() => setIsGoalOpen(true)}
                className="mt-4 px-4 py-2 text-xs font-bold rounded-lg bg-alur-ink text-white"
              >
                Buat Goal pertama
              </button>
            </div>
          )}
        </>
      )}

      <TaskEditModal
        task={editingTask}
        isOpen={!!editingTask}
        onClose={() => setEditingTask(null)}
        onUpdateTask={handleUpdateTask}
        onDeleteTask={handleDeleteTask}
        dateLabel={editingDateLabel}
        goals={goals.map((g) => ({ id: g.id, title: g.title }))}
      />

      <GoalPanel
        isOpen={isGoalOpen}
        goals={goals}
        error={goalError}
        onClose={() => setIsGoalOpen(false)}
        onCreate={handleCreateGoal}
        onDelete={handleDeleteGoal}
      />

      {clarifyTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40" onClick={() => setClarifyTask(null)}>
          <div className="w-full max-w-sm rounded-2xl bg-white border border-alur-border p-5" onClick={(e) => e.stopPropagation()}>
            <p className="text-sm font-bold">Berapa lama kira-kira?</p>
            <p className="mt-1 text-xs text-alur-warmgray truncate">{clarifyTask.title}</p>
            <input
              autoFocus
              type="number"
              min={1}
              value={clarifyMinutes}
              onChange={(e) => setClarifyMinutes(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleClarify();
              }}
              placeholder="cth. 30"
              className="mt-3 w-full bg-alur-surface/40 rounded-lg border border-alur-border px-3 py-2 text-sm outline-none focus:border-alur-ink"
            />
            <div className="mt-3 flex justify-end gap-2">
              <button type="button" onClick={() => setClarifyTask(null)} className="px-3 py-1.5 text-xs font-semibold text-alur-warmgray">
                Batal
              </button>
              <button
                type="button"
                onClick={handleClarify}
                className="px-4 py-1.5 text-xs font-bold rounded-lg bg-alur-ink text-white"
              >
                Simpan
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <p className="px-6 py-10 text-sm text-alur-warmgray">Memuat Target Harian...</p>
      }
    >
      <PlannerGateInner />
    </Suspense>
  );
}

function PlannerGateInner() {
  return <PlannerGate />;
}

function DayColumnInline({
  day,
  tasks,
  onAddTask,
  onToggleTask,
  onOpenEdit,
  onDropTask,
  onClarify,
}: {
  day: DayInfo;
  tasks: PlannerTask[];
  onAddTask: (dateStr: string, title: string) => void;
  onToggleTask: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
  onDropTask: (taskId: string, targetDateStr: string) => void;
  onClarify: (task: PlannerTask) => void;
}) {
  const [isAdding, setIsAdding] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSave = async () => {
    const trimmed = newTitle.trim();
    setNewTitle('');
    setIsAdding(false);
    if (trimmed) await onAddTask(day.dateStr, trimmed);
  };

  return (
    <div className="flex flex-col min-w-[170px] flex-1 border-r border-alur-border/70 last:border-r-0">
      <div className={`h-12 px-3.5 border-b border-alur-border flex items-center justify-between ${day.isToday ? 'bg-alur-surface/90' : 'bg-alur-bg/95'}`}>
        <div className="flex items-center gap-1.5">
          <span className="text-xs font-black tracking-wider uppercase">{day.dayName}</span>
          <span className={`text-xs font-bold px-1.5 py-1 rounded-md ${day.isToday ? 'bg-alur-ink text-alur-bg' : 'text-alur-warmgray'}`}>
            {day.dayNumber} {day.monthName}
          </span>
        </div>
        {tasks.length > 0 && (
          <span className="text-[10px] font-semibold text-alur-warmgray">
            {tasks.filter((t) => t.completed).length}/{tasks.length}
          </span>
        )}
      </div>
      <div className="flex-1 flex flex-col min-h-[380px]">
        {tasks.map((task) => (
          <TaskItem key={task.id} task={task} onToggle={onToggleTask} onOpenEdit={onOpenEdit} onClarify={onClarify} />
        ))}
        {isAdding ? (
          <div className="p-2 border-b border-alur-border/30">
            <input
              ref={inputRef}
              type="text"
              placeholder="Tulis tugas & tekan Enter..."
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              onBlur={handleSave}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleSave();
                if (e.key === 'Escape') {
                  setIsAdding(false);
                  setNewTitle('');
                }
              }}
              className="w-full bg-white px-2.5 py-2 text-sm rounded-lg border border-alur-ink outline-none text-alur-charcoal"
            />
          </div>
        ) : (
          <div onClick={() => { setIsAdding(true); setTimeout(() => inputRef.current?.focus(), 50); }} className="flex-1 min-h-[160px] cursor-text group">
            <div className="h-10 border-b border-alur-border/30 flex items-center px-3.5">
              <span className="opacity-0 group-hover:opacity-50 text-xs text-alur-warmgray flex items-center gap-1">
                <Plus size={12} /> Tambah tugas
              </span>
            </div>
            <div className="h-10 border-b border-alur-border/20" />
          </div>
        )}
      </div>
    </div>
  );
}
