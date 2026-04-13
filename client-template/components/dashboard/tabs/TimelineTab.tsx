
import React, { useMemo, useRef, useEffect } from 'react';
import { Plus, Check, X, Pill, ChevronRight } from 'lucide-react';
import { Member, ExtendedMedication } from '../../../types';
import { MEDICATION_ICONS } from '../../../constants';

interface TimelineTabProps {
  members: Member[];
  activeMemberId: string;
  setActiveMemberId: (id: string) => void;
  setIsAddMemberOpen: (isOpen: boolean) => void;
  selectedDate: Date;
  setSelectedDate: (date: Date) => void;
  medsByTime: { [key: string]: ExtendedMedication[] };
  sortedTimes: string[];
  activeMember: Member;
  setSelectedMedIndex: (index: number) => void;
}

export const TimelineTab: React.FC<TimelineTabProps> = ({
  members,
  activeMemberId,
  setActiveMemberId,
  setIsAddMemberOpen,
  selectedDate,
  setSelectedDate,
  medsByTime,
  sortedTimes,
  activeMember,
  setSelectedMedIndex
}) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  // Generate dynamic days (±15 days from today)
  const days = useMemo(() => {
    const d = [];
    const today = new Date();
    // Start 15 days ago
    const start = new Date(today);
    start.setDate(today.getDate() - 15);
    
    for (let i = 0; i < 30; i++) {
        const date = new Date(start);
        date.setDate(start.getDate() + i);
        d.push(date);
    }
    return d;
  }, []);

  const formatDayName = (date: Date) => {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[date.getDay()];
  };

  const isSameDay = (d1: Date, d2: Date) => {
    return d1.getDate() === d2.getDate() && 
           d1.getMonth() === d2.getMonth() && 
           d1.getFullYear() === d2.getFullYear();
  };
  
  // Auto-scroll to selected date on mount
  useEffect(() => {
    if (scrollRef.current) {
        const selectedBtn = scrollRef.current.querySelector('[data-selected="true"]');
        if (selectedBtn) {
            selectedBtn.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
        }
    }
  }, []); // Run once or when selectedDate drastically changes context if needed

  return (
    <>
      <div className="mb-8 pt-4 -mx-6 animate-in fade-in slide-in-from-top-4 duration-500">
        <h3 className="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-4 px-6 opacity-80">Gia đình</h3>
        <div className="flex items-center gap-5 overflow-x-auto no-scrollbar px-6 pb-2">
          {members.map((member) => (
            <button 
              key={member.id}
              onClick={() => setActiveMemberId(member.id)}
              className="flex flex-col items-center gap-3 group flex-shrink-0"
            >
              <div className={`relative w-[54px] h-[54px] rounded-full flex items-center justify-center transition-all duration-300 ${
                activeMemberId === member.id ? 'ring-2 ring-[#00c2ff] ring-offset-2 ring-offset-black scale-105' : 'opacity-40 grayscale'
              }`}>
                <div className="w-full h-full rounded-full overflow-hidden bg-zinc-800">
                  <img src={member.avatar} alt={member.name} className="w-full h-full object-cover" />
                </div>
              </div>
              <span className={`text-[10px] font-bold transition-colors ${activeMemberId === member.id ? 'text-[#00c2ff]' : 'text-slate-500'}`}>
                {member.name}
              </span>
            </button>
          ))}
          <button onClick={() => setIsAddMemberOpen(true)} className="flex flex-col items-center gap-3 flex-shrink-0">
             <div className="w-[54px] h-[54px] rounded-full bg-zinc-800/10 flex items-center justify-center border border-dashed border-zinc-700 hover:bg-zinc-800/30 transition-colors">
                <Plus className="text-slate-500 w-5 h-5" />
             </div>
             <span className="text-[10px] font-bold text-slate-500 uppercase tracking-tighter">Thêm</span>
          </button>
        </div>
      </div>

      <div 
        ref={scrollRef}
        className="flex items-center gap-6 overflow-x-auto no-scrollbar px-6 pb-4 -mx-6 mb-4 scroll-smooth"
      >
        {days.map((date, idx) => {
          const isSelected = isSameDay(date, selectedDate);
          return (
            <button 
                key={idx} 
                onClick={() => setSelectedDate(date)} 
                data-selected={isSelected}
                className="flex flex-col items-center gap-3 min-w-[32px] group"
            >
              <span className={`text-[9px] font-black uppercase tracking-widest transition-colors ${isSelected ? 'text-[#00c2ff]' : 'text-slate-500 group-hover:text-slate-300'}`}>
                {formatDayName(date)}
              </span>
              <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 ${
                  isSelected 
                    ? 'bg-[#00c2ff] text-white shadow-[0_0_15px_rgba(0,194,255,0.4)] scale-110' 
                    : 'text-zinc-400 bg-zinc-900 border border-white/5'
              }`}>
                {date.getDate()}
              </div>
            </button>
          );
        })}
      </div>

      {sortedTimes.length > 0 ? (
        sortedTimes.map((time) => {
            const takenCount = medsByTime[time].filter(m => m.taken).length;
            const totalCount = medsByTime[time].length;
            
            return (
              <div key={time} className="animate-in fade-in slide-in-from-bottom-2 duration-300">
                <div className="flex justify-between items-center mb-4 mt-2">
                  <h3 className="text-white text-[28px] font-black tracking-tighter leading-none">{time}</h3>
                  <div className="flex items-center gap-2">
                       <span className={`text-[10px] font-black uppercase tracking-widest px-3 py-1.5 rounded-lg border transition-colors ${
                           takenCount === totalCount 
                           ? 'border-[#00c2ff]/30 text-[#00c2ff] bg-[#00c2ff]/10' 
                           : 'border-zinc-700 text-zinc-500'
                       }`}>
                         {takenCount}/{totalCount} Đã dùng
                       </span>
                  </div>
                </div>
                <div className="space-y-3">
                  {medsByTime[time].map((med) => {
                    // Use findIndex with ID because 'med' here is a copy from useMemo, not the original reference
                    const originalIndex = activeMember.meds.findIndex(m => m.id === med.id);
                    
                    const MedIcon = MEDICATION_ICONS[med.icon || 'pill'] || Pill;
                    const medColor = med.color || '#00c2ff';

                    return (
                      <div key={med.id || originalIndex} onClick={() => setSelectedMedIndex(originalIndex)} className={`relative overflow-hidden p-0.5 rounded-[20px] transition-all duration-300 active:scale-[0.98] cursor-pointer group`}>
                         <div className={`absolute inset-0 transition-opacity duration-300 ${med.taken ? 'opacity-0' : 'opacity-100 bg-gradient-to-br from-white/10 to-transparent'}`}></div>
                         
                         <div className={`relative p-4 rounded-[19px] flex items-center gap-4 bg-[#111] border transition-colors ${
                             med.taken ? 'border-zinc-800' : med.skipped ? 'border-red-900/30' : 'border-white/10'
                         }`}>
                             
                            {/* Checkbox / Status Icon */}
                            <div 
                                className={`w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0 transition-all duration-500 shadow-lg ${med.taken ? 'scale-100' : 'scale-95'}`}
                                style={{ 
                                    backgroundColor: med.taken ? medColor : med.skipped ? '#ef4444' : '#1c1c1e',
                                    border: med.taken || med.skipped ? 'none' : `2px solid ${medColor}40`,
                                    boxShadow: med.taken ? `0 0 20px ${medColor}50` : 'none'
                                }}
                            >
                              {med.taken ? (
                                  <Check className="w-6 h-6 text-white" strokeWidth={3} /> 
                              ) : med.skipped ? (
                                  <X className="w-6 h-6 text-white" /> 
                              ) : (
                                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: medColor }}></div>
                              )}
                            </div>

                            <div className="flex-1 min-w-0">
                              <h4 className={`font-bold text-[17px] leading-snug truncate ${med.taken ? 'text-zinc-500 line-through decoration-2 decoration-zinc-700' : med.skipped ? 'text-red-400' : 'text-white'}`}>{med.name}</h4>
                              <p className="text-zinc-500 text-xs mt-1 font-bold tracking-tight truncate">
                                {med.dosage}, {med.frequency}
                              </p>
                              {med.takenAt && (
                                  <p className="text-[10px] font-bold mt-1.5 flex items-center gap-1" style={{ color: medColor }}>
                                      <Check className="w-3 h-3" /> Đã uống lúc {med.takenAt.split(',')[0]}
                                  </p>
                              )}
                            </div>
                            
                            <div className="w-8 h-8 rounded-full bg-zinc-900 flex items-center justify-center text-zinc-600 group-hover:bg-zinc-800 group-hover:text-white transition-colors">
                                <ChevronRight className="w-4 h-4" />
                            </div>
                         </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
        })
      ) : (
        <div className="text-center py-20 flex flex-col items-center gap-4 text-slate-600 animate-in fade-in duration-500">
          <div className="w-16 h-16 rounded-full bg-zinc-900/50 border border-zinc-800 flex items-center justify-center">
            <Pill className="w-6 h-6 opacity-20" />
          </div>
          <div>
              <p className="text-sm font-bold text-zinc-400">Không có lịch uống thuốc</p>
              <p className="text-xs mt-1 opacity-50 font-medium">Bạn có thể nghỉ ngơi!</p>
          </div>
        </div>
      )}
    </>
  );
};
