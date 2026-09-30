import React from 'react';

export default function CalendarHeader() {
  return (
    <header className="flex items-center justify-between mb-8">
      <div className="flex-1">
        <h1 className="text-[32px] font-black tracking-tight text-[#1A1A1A]">
          Stay up to date, Dr.Olivia
        </h1>
      </div>
      <div className="flex items-center gap-6">
        {/* Search Bar - Menggunakan Paper Gray agar tidak mencolok */}
        <div className="hidden md:flex items-center bg-[#F0EFED] rounded-full px-5 py-2.5 w-96">
          <span className="text-[#7A7772] mr-3 font-medium text-sm">🔍 Search</span>
          <input 
            type="text" 
            placeholder="In: Patients | Education | Prescriptions | Test results" 
            className="bg-transparent outline-none text-xs w-full text-[#1A1A1A] placeholder-[#7A7772]" 
          />
        </div>
        
        {/* Action Buttons */}
        <button className="bg-[#111111] text-white px-5 py-2.5 rounded-full font-bold text-sm hover:opacity-90 transition-opacity">
          Add event
        </button>
        
        {/* Profile / Icons Dummy */}
        <div className="flex items-center gap-3">
          <button className="w-10 h-10 bg-[#F0EFED] rounded-full flex items-center justify-center hover:bg-[#DEDBD6] transition-colors">
            🔄
          </button>
          <button className="w-10 h-10 bg-[#F0EFED] rounded-full flex items-center justify-center hover:bg-[#DEDBD6] transition-colors">
            ✏️
          </button>
        </div>
      </div>
    </header>
  );
}
