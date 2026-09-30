'use client';

import React from 'react';
import { DayInfo, PlannerTask } from './types';
import { DayColumn } from './DayColumn';

interface WeekGridProps {
  days: DayInfo[];
  tasks: PlannerTask[];
  onAddTask: (dateStr: string, title: string) => void;
  onToggleTask: (id: string) => void;
  onOpenEdit: (task: PlannerTask) => void;
  onDropTask: (taskId: string, targetDateStr: string) => void;
}

export const WeekGrid: React.FC<WeekGridProps> = ({
  days,
  tasks,
  onAddTask,
  onToggleTask,
  onOpenEdit,
  onDropTask,
}) => {
  return (
    <div className="flex-1 overflow-x-auto min-h-[520px]">
      <div className="flex min-w-[1050px] w-full border-b border-alur-border">
        {days.map((day) => {
          const dayTasks = tasks.filter((t) => t.dateStr === day.dateStr);
          return (
            <DayColumn
              key={day.dateStr}
              day={day}
              tasks={dayTasks}
              onAddTask={onAddTask}
              onToggleTask={onToggleTask}
              onOpenEdit={onOpenEdit}
              onDropTask={onDropTask}
            />
          );
        })}
      </div>
    </div>
  );
};
