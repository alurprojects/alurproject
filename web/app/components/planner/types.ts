export type HighlightColor = 'none' | 'yellow' | 'green' | 'blue' | 'pink' | 'peach';

export interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

export interface PlannerTask {
  id: string;
  title: string;
  completed: boolean;
  dateStr: string; // 'YYYY-MM-DD' or 'someday'
  color?: HighlightColor;
  timeEstimate?: string; // e.g. '30m', '1h'
  notes?: string;
  subtasks?: SubTask[];
  order: number;
}

export interface DayInfo {
  dateStr: string;
  dayName: string;
  dayNumber: string;
  monthName: string;
  isToday: boolean;
  isWeekend: boolean;
  fullDateText: string; // e.g. 'Tue, 29 Sep 2026'
}
