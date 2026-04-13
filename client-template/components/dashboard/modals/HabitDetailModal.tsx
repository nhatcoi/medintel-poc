
import React from 'react';
import { X, ChevronLeft, Edit2, Calendar, Clock, Trash2, CheckCircle2, Trophy } from 'lucide-react';
import { HealthHabit, HabitLog } from '../../../types';
import { HABIT_CATEGORIES_CONFIG, HABIT_ICONS_MAP } from '../../../constants';

interface HabitDetailModalProps {
  habit: HealthHabit;
  logs: HabitLog[]; // Logs for current date or all history filtered outside
  onClose: () => void;
  onEdit: () => void;
  onDeleteLog: (logId: string) => void;
}

export const HabitDetailModal: React.FC<HabitDetailModalProps> = ({ 
  habit, 
  logs, 
  onClose, 
  onEdit, 
  onDeleteLog 
}) => {
  // Determine icon: Custom > Config Default
  let CategoryIcon = HABIT_CATEGORIES_CONFIG[habit.category]?.icon;
  if (habit.icon && HABIT_ICONS_MAP[habit.icon]) {
      CategoryIcon = HABIT_ICONS_MAP[habit.icon];
  }

  const currentTotal = logs.reduce((sum, log) => sum + log.value, 0);
  const percent = Math.min((currentTotal / habit.targetValue) * 100, 100);
  const isComplete = currentTotal >= habit.targetValue;

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto" onClick={onClose}></div>
        
        <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
             
             {/* Header */}
             <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#1c1c1e] z-10 border-b border-white/5">
                <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                     <ChevronLeft className="w-5 h-5 text-zinc-400" />
                </button>
                <h3 className="text-lg font-bold text-white">Chi tiết thói quen</h3>
                <button onClick={onEdit} className="p-2 bg-[#00c2ff]/10 rounded-full text-[#00c2ff]">
                    <Edit2 className="w-5 h-5" />
                </button>
             </div>

             <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-12 pt-6">
                 
                 {/* Hero Section */}
                 <div className="flex flex-col items-center mb-8">
                     <div className="relative w-32 h-32 flex items-center justify-center mb-4">
                         {/* Progress Ring Background */}
                         <svg className="absolute inset-0 w-full h-full -rotate-90">
                             <circle cx="64" cy="64" r="58" stroke="#333" strokeWidth="8" fill="transparent" />
                             <circle 
                                cx="64" cy="64" r="58" 
                                stroke={habit.color || '#00c2ff'} 
                                strokeWidth="8" 
                                fill="transparent"
                                strokeDasharray={364}
                                strokeDashoffset={364 - (364 * percent) / 100}
                                strokeLinecap="round"
                                className="transition-all duration-1000"
                             />
                         </svg>
                         <div className="w-24 h-24 rounded-full bg-zinc-800 flex items-center justify-center shadow-inner relative z-10">
                             {isComplete ? (
                                 <Trophy className="w-10 h-10 text-yellow-400 animate-bounce" />
                             ) : (
                                 <CategoryIcon className="w-10 h-10" style={{ color: habit.color }} />
                             )}
                         </div>
                     </div>
                     
                     <h2 className="text-2xl font-bold text-white text-center">{habit.name}</h2>
                     <div className="flex items-end gap-1.5 mt-1">
                         <span className="text-3xl font-black text-white">{currentTotal}</span>
                         <span className="text-sm font-bold text-zinc-500 mb-1.5">/ {habit.targetValue} {habit.unit}</span>
                     </div>
                 </div>

                 {/* Stats Row */}
                 <div className="grid grid-cols-2 gap-3 mb-8">
                     <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 flex flex-col items-center text-center">
                         <span className="text-xs font-bold text-zinc-500 uppercase mb-1">Mục tiêu ngày</span>
                         <span className="text-white font-bold">{habit.targetValue} {habit.unit}</span>
                     </div>
                     <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 flex flex-col items-center text-center">
                         <span className="text-xs font-bold text-zinc-500 uppercase mb-1">Số lần thực hiện</span>
                         <span className="text-white font-bold">{logs.length} lần</span>
                     </div>
                 </div>

                 {/* History / Logs */}
                 <h4 className="text-zinc-500 text-xs font-bold uppercase mb-4 pl-1">Lịch sử hôm nay</h4>
                 {logs.length > 0 ? (
                     <div className="space-y-3">
                         {logs.slice().reverse().map((log) => (
                             <div key={log.id} className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 flex items-center justify-between group">
                                 <div className="flex items-center gap-4">
                                     <div className="w-10 h-10 rounded-xl bg-zinc-800 flex items-center justify-center text-zinc-400">
                                         <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                                     </div>
                                     <div>
                                         <span className="text-white font-bold block">+{log.value} {habit.unit}</span>
                                         <div className="flex items-center gap-1 text-[10px] text-zinc-500 font-medium">
                                             <Clock className="w-3 h-3" />
                                             {log.timestamp ? new Date(log.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : 'check-in'}
                                         </div>
                                     </div>
                                 </div>
                                 <button 
                                    onClick={() => onDeleteLog(log.id)}
                                    className="p-2 rounded-full bg-red-500/10 text-red-500 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-all hover:bg-red-500/20"
                                 >
                                     <Trash2 className="w-4 h-4" />
                                 </button>
                             </div>
                         ))}
                     </div>
                 ) : (
                     <div className="text-center py-8 bg-[#2c2c2e]/50 rounded-2xl border border-dashed border-zinc-700">
                         <p className="text-zinc-500 text-sm font-medium">Chưa có hoạt động nào hôm nay</p>
                     </div>
                 )}

             </div>
        </div>
    </div>
  );
};
