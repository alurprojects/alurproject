'use client';

import React from 'react';
import { Task } from '@/lib/api';
import { Calendar, Clock, ArrowRight } from 'lucide-react';

interface CalendarViewProps {
  tasks: Task[];
  onNavigateToTodo?: () => void;
}

export function CalendarView({ tasks, onNavigateToTodo }: CalendarViewProps) {
  // 06:00 to 22:00 (17 hours)
  const hours = Array.from({ length: 17 }, (_, i) => 6 + i);

  // Group tasks that have an assigned estimated time or keep unscheduled
  const unscheduledTasks = tasks.filter((t) => !t.estimated_minutes || t.estimated_minutes === 0);
  const scheduledTasks = tasks.filter((t) => t.estimated_minutes && t.estimated_minutes > 0);

  // Mock slot distribution for demo preview
  const getTasksForHour = (hour: number) => {
    if (hour === 9) {
      return scheduledTasks.slice(0, 1);
    }
    if (hour === 14) {
      return scheduledTasks.slice(1, 2);
    }
    return [];
  };

  return (
    <div className="w-full max-w-4xl mx-auto pb-16">
      {/* Header Banner */}
      <div className="mb-6 p-4 rounded-lg bg-[#F0EFED] border border-[#DEDBD6] flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-md bg-[#111111] text-white flex items-center justify-center">
            <Calendar className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-sm font-bold uppercase tracking-wider text-[#1A1A1A]">
              Calendar Time-Block View (Read-Only)
            </h2>
            <p className="text-xs text-[#7A7772]">
              Representasi visual agenda harian dari jam 06:00 hingga 22:00
            </p>
          </div>
        </div>
        {onNavigateToTodo && (
          <button
            onClick={onNavigateToTodo}
            className="text-xs font-semibold text-[#111111] hover:underline flex items-center gap-1.5"
          >
            Buka Tab To-do <ArrowRight className="w-3.5 h-3.5" />
          </button>
        )}
      </div>

      {/* Unscheduled Tasks Section */}
      <div className="mb-6 p-4 rounded-lg bg-[#FAF9F7] border border-[#DEDBD6]">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#7A7772]" />
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#1A1A1A]">
              Tugas Tanpa Jadwal Waktu ({unscheduledTasks.length})
            </h3>
          </div>
          <span className="text-[11px] text-[#7A7772]">
            Tentukan durasi tugas di To-do untuk memetakan ke jam
          </span>
        </div>
        {unscheduledTasks.length === 0 ? (
          <p className="text-xs text-[#7A7772] italic">Semua tugas telah terjadwal.</p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {unscheduledTasks.map((t) => (
              <div
                key={t.id}
                onClick={onNavigateToTodo}
                className="cursor-pointer text-xs px-2.5 py-1.5 rounded bg-[#F0EFED] border border-[#DEDBD6] text-[#1A1A1A] hover:border-[#111111] transition-colors"
              >
                {t.title}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Time block vertical grid (06:00 - 22:00) */}
      <div className="bg-[#FAF9F7] rounded-lg border border-[#DEDBD6] overflow-hidden">
        {hours.map((hour) => {
          const timeLabel = `${hour.toString().padStart(2, '0')}:00`;
          const slotTasks = getTasksForHour(hour);

          return (
            <div
              key={hour}
              className="flex items-start min-h-[56px] border-b border-[#DEDBD6]/60 last:border-b-0"
            >
              <div className="w-20 py-2.5 pr-4 text-right text-xs font-semibold text-[#7A7772] select-none">
                {timeLabel}
              </div>
              <div className="w-[1px] bg-[#DEDBD6] self-stretch" />
              <div className="flex-1 p-2">
                {slotTasks.length > 0 ? (
                  <div className="space-y-1.5">
                    {slotTasks.map((st) => (
                      <div
                        key={st.id}
                        onClick={onNavigateToTodo}
                        className="cursor-pointer p-2.5 rounded bg-[#F0EFED] border border-[#DEDBD6] hover:border-[#111111] transition-colors flex items-center justify-between"
                      >
                        <div>
                          <p className="text-xs font-bold text-[#1A1A1A]">{st.title}</p>
                          <p className="text-[10px] text-[#7A7772]">
                            Estimasi: {st.estimated_minutes} menit • Read-only
                          </p>
                        </div>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-[#111111] text-white font-medium">
                          Fokus
                        </span>
                      </div>
                    ))}
                  </div>
                ) : null}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
