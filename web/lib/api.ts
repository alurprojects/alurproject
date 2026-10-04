export type TaskStatus = 'PENDING' | 'DONE' | 'MISSED';
export type TaskSource = 'MANUAL' | 'BRAIN_DUMP' | 'CHAT_ROOM' | 'GOAL_PLAN';
export type MissedFollowUp = 'NONE' | 'PENDING' | 'FORGOT' | 'SKIPPED' | 'RESCHEDULED';

export interface Task {
  id: string;
  user_id: string;
  goal_id: string | null;
  goal_title?: string | null;
  title: string;
  status: TaskStatus;
  assigned_date: string;
  estimated_minutes: number | null;
  is_ambiguous: boolean;
  ai_generated: boolean;
  source: TaskSource;
  missed_follow_up: MissedFollowUp;
  recurrence_rule?: string | null;
  suggestion?: {
    id: string;
    suggested_date: string;
    reason: string | null;
  } | null;
}

export interface DayTasks {
  date: string;
  day_name: string;
  is_today: boolean;
  tasks: Task[];
}

export interface WeekTasksResponse {
  week_start: string;
  week_end: string;
  days: DayTasks[];
}

export type GoalStatus = 'ACTIVE' | 'DONE' | 'ARCHIVED';
export type PlanStatus = 'NONE' | 'GENERATING' | 'DRAFT' | 'ACCEPTED';

export interface Goal {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  deadline: string | null;
  target_hours_per_week: number | null;
  definition_of_done: string | null;
  status: GoalStatus;
  plan: Record<string, unknown>;
  plan_draft: Record<string, unknown>;
  plan_status: PlanStatus;
}

export interface GoalPlan {
  goal_id: string;
  plan_status: PlanStatus;
  plan: Record<string, unknown>;
  plan_draft: Record<string, unknown>;
}

export interface Me {
  id: string;
  email: string;
  name: string;
  timezone: string;
  daily_capacity_hours: number;
  preferences: Record<string, unknown>;
}

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || '/api';

function getAuthHeaders(): Record<string, string> {
  if (typeof window === 'undefined') return {};
  const token = window.localStorage.getItem('alur_jwt');
  if (token) return { Authorization: `Bearer ${token}` };
  return {};
}

async function fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders(),
      ...(options.headers || {}),
    },
  });

  if (response.status === 204) return undefined as T;
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API Error ${response.status}: ${errorText}`);
  }
  return response.json();
}

function flattenWeek(week: WeekTasksResponse, goalMap: Map<string, string>): Task[] {
  return week.days.flatMap((d) =>
    d.tasks.map((t) => ({
      ...t,
      goal_title: t.goal_id ? goalMap.get(t.goal_id) || null : null,
    }))
  );
}

export const api = {
  // --- Tasks (Target Harian) ---
  getWeek: async (weekStart?: string): Promise<WeekTasksResponse> => {
    const query = weekStart ? `?week=${weekStart}` : '';
    return fetchAPI<WeekTasksResponse>(`/tasks${query}`);
  },

  getWeekFlat: async (weekStart: string | undefined, goals: Goal[]): Promise<Task[]> => {
    const week = await api.getWeek(weekStart);
    return flattenWeek(week, new Map(goals.map((g) => [g.id, g.title])));
  },

  createTask: async (title: string, assignedDate: string, estimatedMinutes?: number, goalId?: string): Promise<Task> => {
    return fetchAPI<Task>('/tasks', {
      method: 'POST',
      body: JSON.stringify({
        title,
        assigned_date: assignedDate,
        estimated_minutes: estimatedMinutes ?? null,
        goal_id: goalId ?? null,
      }),
    });
  },

  toggleTask: async (id: string, currentStatus: TaskStatus): Promise<Task> => {
    const newStatus: TaskStatus = currentStatus === 'DONE' ? 'PENDING' : 'DONE';
    return fetchAPI<Task>(`/tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ status: newStatus }),
    });
  },

  updateTask: async (id: string, patch: { title?: string; assigned_date?: string; estimated_minutes?: number | null; goal_id?: string | null }): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(patch),
    });
  },

  moveTask: async (id: string, assignedDate: string): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ assigned_date: assignedDate }),
    });
  },

  deleteTask: async (id: string): Promise<void> => {
    await fetchAPI<unknown>(`/tasks/${id}`, { method: 'DELETE' });
  },

  clarifyTask: async (id: string, estimatedMinutes: number): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/clarify`, {
      method: 'PATCH',
      body: JSON.stringify({ estimated_minutes: estimatedMinutes }),
    });
  },

  followUpTask: async (id: string, action: 'FORGOT' | 'SKIPPED' | 'RESCHEDULED'): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/follow-up`, {
      method: 'PATCH',
      body: JSON.stringify({ action }),
    });
  },

  rescheduleTask: async (id: string, suggestionId: string, action: 'ACCEPT' | 'REJECT'): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/reschedule`, {
      method: 'PATCH',
      body: JSON.stringify({ suggestion_id: suggestionId, action }),
    });
  },

  brainDump: async (text: string): Promise<Task[]> => {
    return fetchAPI<Task[]>('/brain-dump', {
      method: 'POST',
      body: JSON.stringify({ text }),
    });
  },

  getSurfacedInsights: async (): Promise<{ id: string; content: string }[]> => {
    return fetchAPI<{ id: string; content: string }[]>('/insights?surfaced=true');
  },

  // --- Goals (M14-manual) ---
  listGoals: async (): Promise<Goal[]> => {
    return fetchAPI<Goal[]>('/goals');
  },

  createGoal: async (input: { title: string; description?: string; deadline?: string; target_hours_per_week?: number }): Promise<Goal> => {
    return fetchAPI<Goal>('/goals', {
      method: 'POST',
      body: JSON.stringify(input),
    });
  },

  updateGoal: async (id: string, patch: Partial<Goal>): Promise<Goal> => {
    return fetchAPI<Goal>(`/goals/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(patch),
    });
  },

  deleteGoal: async (id: string): Promise<void> => {
    await fetchAPI<unknown>(`/goals/${id}`, { method: 'DELETE' });
  },

  requestGoalPlan: async (id: string): Promise<GoalPlan> => {
    return fetchAPI<GoalPlan>(`/goals/${id}/plan`, { method: 'POST' });
  },

  getGoalPlan: async (id: string): Promise<GoalPlan> => {
    return fetchAPI<GoalPlan>(`/goals/${id}/plan`);
  },

  acceptGoalPlan: async (id: string, planDraft?: Record<string, unknown>, onlyMilestones = false): Promise<GoalPlan> => {
    return fetchAPI<GoalPlan>(`/goals/${id}/plan/accept`, {
      method: 'POST',
      body: JSON.stringify({ plan_draft: planDraft ?? null, only_milestones: onlyMilestones }),
    });
  },

  // --- Users / preferences ---
  getMe: async (): Promise<Me> => {
    return fetchAPI<Me>('/users/me');
  },

  updatePreferences: async (patch: { daily_capacity_hours?: number; timezone?: string; fixed_blocks?: { label?: string; days?: number[]; start: string; end: string }[]; todo_default_view?: 'daily' | 'weekly'; onboarding_completed_at?: string }): Promise<Me> => {
    return fetchAPI<Me>('/users/me/preferences', {
      method: 'PATCH',
      body: JSON.stringify(patch),
    });
  },
};
