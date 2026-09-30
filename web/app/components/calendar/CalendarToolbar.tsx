import React from 'react';

export default function CalendarToolbar() {
  return (
    <div className="flex items-center justify-between mb-8">
      {/* Date Range Selector */}
      <button className="bg-[#111111] text-white px-5 py-2.5 rounded-full text-sm font-bold flex items-center gap-2 hover:opacity-90">
        May 11/05 - 17/05 <span className="text-xs opacity-80">▼</span>
      </button>
      
      {/* View Toggles */}
      <div className="flex bg-[#F0EFED] rounded-full p-1.5 gap-1">
        <button className="px-6 py-2 text-sm font-bold rounded-full text-[#7A7772] hover:text-[#1A1A1A] transition-colors">
          Today
        </button>
        <button className="px-6 py-2 text-sm font-bold rounded-full bg-[#111111] text-white shadow-sm transition-all">
          Week
        </button>
        <button className="px-6 py-2 text-sm font-bold rounded-full text-[#7A7772] hover:text-[#1A1A1A] transition-colors">
          Month
        </button>
      </div>
    </div>
  );
}
