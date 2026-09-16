export interface Task {
  id: string;
  user_id: string;
  title: string;
  status: 'PENDING' | 'DONE' | 'MISSED' | 'CANCELLED';
  assigned_date: string;
  estimated_minutes: number | null;
  is_ambiguous: boolean;
  missed_follow_up?: 'PENDING' | 'RESOLVED' | null;
  recurrence_rule?: string | null;
  recurrence_group_id?: string | null;
  source: 'MANUAL' | 'BRAIN_DUMP' | 'RECURRENCE' | 'FOLLOW_UP';
  reschedule_suggestion?: {
    id: string;
    suggested_date: string;
    reason: string;
  } | null;
}

export interface AIInsight {
  id: string;
  user_id: string;
  week_start_date: string;
  content: string;
  surfaced: boolean;
  created_at?: string;
}

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || '';

async function fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    'X-User-Id': '00000000-0000-0000-0000-000000000001',
    ...(options.headers || {}),
  };

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API Error ${response.status}: ${errorText}`);
  }

  return response.json();
}

export const api = {
  // 1. Fetch 7 days of tasks for a given week start (YYYY-MM-DD)
  getTasks: async (weekStart?: string): Promise<Task[]> => {
    const query = weekStart ? `?week=${weekStart}` : '';
    return fetchAPI<Task[]>(`/tasks${query}`);
  },

  // 2. Create manual task
  createTask: async (title: string, assignedDate: string, estimatedMinutes?: number): Promise<Task> => {
    return fetchAPI<Task>('/tasks', {
      method: 'POST',
      body: JSON.stringify({
        title,
        assigned_date: assignedDate,
        estimated_minutes: estimatedMinutes || null,
      }),
    });
  },

  // 3. Toggle task status (PENDING <-> DONE)
  toggleTask: async (id: string, currentStatus: string): Promise<Task> => {
    const newStatus = currentStatus === 'DONE' ? 'PENDING' : 'DONE';
    return fetchAPI<Task>(`/tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ status: newStatus }),
    });
  },

  // 4. Delete task
  deleteTask: async (id: string): Promise<void> => {
    await fetchAPI<{ message: string }>(`/tasks/${id}`, {
      method: 'DELETE',
    });
  },

  // 5. Clarify duration for ambiguous task
  clarifyTask: async (id: string, estimatedMinutes: number): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/clarify`, {
      method: 'PATCH',
      body: JSON.stringify({ estimated_minutes: estimatedMinutes }),
    });
  },

  // 6. Handle missed follow up (LUPA, SKIP, PINDAH)
  followUpTask: async (id: string, action: 'LUPA' | 'SKIP' | 'PINDAH', targetDate?: string): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/follow-up`, {
      method: 'PATCH',
      body: JSON.stringify({
        action,
        target_date: targetDate || null,
      }),
    });
  },

  // 7. Handle reschedule suggestion (ACCEPT, REJECT)
  rescheduleTask: async (
    id: string,
    action: 'ACCEPT' | 'REJECT',
    targetDate?: string,
    suggestionId?: string
  ): Promise<Task> => {
    return fetchAPI<Task>(`/tasks/${id}/reschedule`, {
      method: 'PATCH',
      body: JSON.stringify({
        action,
        target_date: targetDate || null,
        suggestion_id: suggestionId || null,
      }),
    });
  },

  // 8. Brain dump (free text into LangGraph pipeline)
  brainDump: async (text: string): Promise<{ created_tasks: Task[]; raw_extracted?: any[] }> => {
    return fetchAPI<{ created_tasks: Task[]; raw_extracted?: any[] }>('/brain-dump', {
      method: 'POST',
      body: JSON.stringify({ text }),
    });
  },

  // 9. Get surfaced AI reflection insights
  getSurfacedInsights: async (): Promise<AIInsight[]> => {
    return fetchAPI<AIInsight[]>('/insights?surfaced=true');
  },
};
