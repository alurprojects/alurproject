'use client';

export type TaskStatus = 'PENDING' | 'DONE' | 'MISSED';
export type TaskSource = 'MANUAL' | 'BRAIN_DUMP' | 'CHAT_ROOM' | 'GOAL_PLAN';
export type MissedFollowUp = 'NONE' | 'PENDING' | 'FORGOT' | 'SKIPPED' | 'RESCHEDULED';

// UI task for Target Harian. Mirrors backend Task + goal label.
export interface PlannerTask {
  id: string;
  title: string;
  completed: boolean; // status === 'DONE'
  dateStr: string; // YYYY-MM-DD
  status: TaskStatus;
  estimatedMinutes: number | null;
  isAmbiguous: boolean;
  source: TaskSource;
  goalId: string | null;
  goalTitle?: string | null;
  missedFollowUp: MissedFollowUp;
  order: number;
}

export interface DayInfo {
  dateStr: string;
  dayName: string;
  dayNumber: string;
  monthName: string;
  isToday: boolean;
  isWeekend: boolean;
  fullDateText: string;
}

export function toPlannerTask(apiTask: {
  id: string;
  title: string;
  status: TaskStatus;
  assigned_date: string;
  estimated_minutes: number | null;
  is_ambiguous: boolean;
  source: TaskSource;
  goal_id: string | null;
  goal_title?: string | null;
  missed_follow_up: MissedFollowUp;
  created_at?: string;
}): PlannerTask {
  return {
    id: apiTask.id,
    title: apiTask.title,
    completed: apiTask.status === 'DONE',
    dateStr: apiTask.assigned_date,
    status: apiTask.status,
    estimatedMinutes: apiTask.estimated_minutes,
    isAmbiguous: apiTask.is_ambiguous,
    source: apiTask.source,
    goalId: apiTask.goal_id,
    goalTitle: apiTask.goal_title ?? null,
    missedFollowUp: apiTask.missed_follow_up,
    order: apiTask.created_at ? Date.parse(apiTask.created_at) : 0,
  };
}

export function formatEstimate(minutes: number | null): string | null {
  if (minutes == null) return null;
  if (minutes < 60) return `${minutes}m`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m === 0 ? `${h}j` : `${h}j ${m}m`;
}
