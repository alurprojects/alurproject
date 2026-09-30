import React from 'react';

type EventCardProps = {
  title: string;
  time: string;
  color: 'yellow' | 'pink' | 'blue' | 'gray' | 'dark';
  location?: string;
  participants?: boolean;
  type?: string;
};

export default function EventCard({ title, time, color, location, participants, type }: EventCardProps) {
  // Palet Colorful Option sesuai persetujuan pengguna
  const colorClasses = {
    yellow: 'bg-[#FCE181] text-[#1A1A1A]',
    pink: 'bg-[#F9C3D6] text-[#1A1A1A]',
    blue: 'bg-[#A9C7F0] text-[#1A1A1A]',
    gray: 'bg-[#EAE8E3] text-[#1A1A1A]',
    dark: 'bg-[#111111] text-white',
  };
  
  const cardClass = colorClasses[color] || colorClasses.gray;

  return (
    <div className={`rounded-[14px] p-4 flex flex-col gap-1 w-full h-full text-sm hover:scale-[1.02] transition-transform cursor-pointer ${cardClass}`}>
      {/* Optional Top Metadata */}
      {type && (
        <div className="flex items-center gap-1.5 mb-1 text-xs opacity-70 font-semibold">
          <span className="w-4 h-4 bg-black bg-opacity-10 rounded-full flex items-center justify-center">✨</span>
          {type}
        </div>
      )}

      {/* Main Content */}
      <h3 className="font-bold text-[15px] leading-tight tracking-tight mt-1">{title}</h3>
      {location && <p className="text-xs opacity-75 font-medium leading-tight">{location}</p>}
      
      {/* Time & Participants at the bottom */}
      <div className="mt-auto pt-2">
        <div className="text-[11px] font-semibold opacity-60 mb-2">{time}</div>
        
        {participants && (
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-bold opacity-60 uppercase tracking-wide">Participants</span>
            <div className="flex -space-x-1.5">
              <div className="w-6 h-6 rounded-full bg-black bg-opacity-20 flex items-center justify-center text-[9px] font-black">TY</div>
              <div className="w-6 h-6 rounded-full bg-black bg-opacity-20 flex items-center justify-center text-[9px] font-black">AB</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
