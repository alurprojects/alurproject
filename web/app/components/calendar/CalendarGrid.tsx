import React from 'react';
import EventCard from './EventCard';

const days = [
  { name: 'MONDAY', date: '11/05' },
  { name: 'TUESDAY', date: '12/05' },
  { name: 'WEDNESDAY', date: '13/05' },
  { name: 'THU', date: '14/05', active: true },
  { name: 'FR', date: '15/05' },
  { name: 'SA', date: '16/05' },
  { name: 'SU', date: '17/05', faded: true },
];

const times = ['07:00', '07:30', '08:00', '08:30', '09:00', '09:30'];

export default function CalendarGrid() {
  return (
    <div className="flex flex-col mt-4 w-full">
      {/* Top Days Header Row */}
      <div className="grid grid-cols-[60px_repeat(7,1fr)] gap-4 mb-6">
        <div className="col-span-1 flex flex-col items-center justify-center text-xs text-[#7A7772]">
          <span className="font-medium">W</span>
          <span className="font-medium">24</span>
        </div>
        
        {days.map((day, idx) => (
          <div key={idx} className={`col-span-1 flex flex-col items-center justify-center py-3 rounded-2xl ${
            day.active ? 'bg-[#111111] text-white' : day.faded ? 'text-[#DEDBD6]' : 'text-[#1A1A1A]'
          }`}>
            <span className="text-[11px] font-bold tracking-widest">{day.name}</span>
            <span className="text-xl font-black mt-0.5 tracking-tight">{day.date}</span>
          </div>
        ))}
      </div>

      {/* Grid Content Area */}
      <div className="grid grid-cols-[60px_repeat(7,1fr)] gap-4 relative">
         
         {/* Current Time Indicator Line */}
         <div className="absolute top-[40px] left-0 right-0 h-px border-t border-dashed border-[#F9C3D6] z-10">
            <span className="bg-[#F9C3D6] text-[10px] font-bold px-1.5 py-0.5 rounded-full text-[#1A1A1A] absolute -left-2 -translate-y-1/2">
              07:21
            </span>
         </div>

         {/* Time Column (Y-Axis) */}
         <div className="col-span-1 flex flex-col text-[11px] text-[#7A7772] font-semibold pt-2">
            {times.map(t => <div key={t} className="h-24 relative"><span className="absolute -top-2">{t}</span></div>)}
         </div>

         {/* Monday Column Example */}
         <div className="col-span-1 flex flex-col gap-3 relative pt-2">
            <div className="h-28">
               <EventCard title="Emergency visit" location="West camp, Room 312" time="07:00 - 07:30" color="gray" type="Stethoscope" />
            </div>
            <div className="h-20">
               <EventCard title="Diagnostic test" time="07:30 - 07:55" color="gray" type="Syringe" />
            </div>
            <div className="h-32 mt-2">
               <EventCard title="Team planning" location="East camp, Room 200" time="08:00 - 09:00" color="yellow" type="People" participants={true} />
            </div>
         </div>

         {/* Tuesday Column */}
         <div className="col-span-1 flex flex-col gap-3 pt-2">
            <div className="h-32">
               <EventCard title="Online visit" location="West camp, Room 312" time="07:00 - 08:00" color="gray" participants={true} type="Camera" />
            </div>
            <div className="h-16">
               <EventCard title="Diagnostic test" time="08:00 - 08:15" color="gray" type="Syringe" />
            </div>
         </div>
         
         {/* Wednesday Column */}
         <div className="col-span-1 flex flex-col gap-3 pt-2">
            <div className="mt-[7rem] h-20">
               <EventCard title="Follow-up" location="West camp, Room 312" time="09:00 - 09:30" color="gray" />
            </div>
            <div className="h-32">
               <EventCard title="Interns visit" location="West camp, Conference room 404" time="08:30 - 09:30" color="blue" participants={true} />
            </div>
         </div>

         {/* Thursday Column (Active) */}
         <div className="col-span-1 flex flex-col gap-3 pt-2">
             <div className="h-32">
               <EventCard title="Online visit" location="West camp, Room 312" time="07:00 - 08:00" color="gray" type="Camera" />
            </div>
         </div>

         {/* Friday Column */}
         <div className="col-span-1 flex flex-col gap-3 pt-2">
             <div className="h-[9rem]">
               <EventCard title="Team results" location="East camp, Room 200" time="07:00 - 08:00" color="yellow" participants={true} />
            </div>
         </div>

         <div className="col-span-1"></div>
         <div className="col-span-1"></div>
      </div>
    </div>
  );
}
