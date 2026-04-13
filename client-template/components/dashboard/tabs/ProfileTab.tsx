
import React, { useMemo } from 'react';
import { UserCircle, ShieldCheck, Settings, HelpCircle, LogOut, Plus, ChevronRight, TrendingUp, AlertCircle, Award } from 'lucide-react';
import { Member, ExtendedMedication } from '../../../types';

interface ProfileTabProps {
  activeMember: Member;
  members: Member[];
  activeMemberId: string;
  setActiveMemberId: (id: string) => void;
  setIsAddMemberOpen: (isOpen: boolean) => void;
  handleLogout: () => void;
}

export const ProfileTab: React.FC<ProfileTabProps> = ({ 
  activeMember, 
  members, 
  activeMemberId, 
  setActiveMemberId, 
  setIsAddMemberOpen, 
  handleLogout 
}) => {
  
  // Calculate Adherence Stats
  const adherenceStats = useMemo(() => {
    const today = new Date();
    const stats = [];
    let totalTaken = 0;
    let totalScheduled = 0;

    // Helper to check if med is scheduled for a specific date
    const checkIsScheduled = (med: ExtendedMedication, date: Date) => {
        const dateKey = date.toISOString().split('T')[0];
        // If no time defined, it's not a scheduled med (e.g. PRN)
        if (!med.timeOfDay || med.timeOfDay.length === 0) return false;

        if (med.startDate) {
            const start = new Date(med.startDate);
            const current = new Date(dateKey);
            start.setHours(0,0,0,0);
            current.setHours(0,0,0,0);
            
            if (current < start) return false;
            
            if (med.frequencyType === 'interval' && med.interval) {
                 const diffTime = Math.abs(current.getTime() - start.getTime());
                 const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
                 if (diffDays % med.interval !== 0) return false;
            } else if (med.frequencyType === 'specific_days' && med.specificDays) {
                 if (!med.specificDays.includes(current.getDay())) return false;
            }
        }
        return true;
    };

    // Last 7 days including today
    for (let i = 6; i >= 0; i--) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        const dateKey = d.toISOString().split('T')[0];
        
        // Label: T2, T3... or Date
        const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        const label = i === 0 ? 'Hôm nay' : days[d.getDay()];

        let dayScheduledCount = 0;
        let dayTakenCount = 0;

        activeMember.meds.forEach(med => {
            if (checkIsScheduled(med, d)) {
                dayScheduledCount++;
                if (med.history?.[dateKey]?.taken) {
                    dayTakenCount++;
                }
            }
        });

        const percent = dayScheduledCount > 0 ? Math.round((dayTakenCount / dayScheduledCount) * 100) : 0;
        
        stats.push({
            label,
            percent,
            isToday: i === 0
        });

        totalScheduled += dayScheduledCount;
        totalTaken += dayTakenCount;
    }

    const overall = totalScheduled > 0 ? Math.round((totalTaken / totalScheduled) * 100) : 0;
    
    return { daily: stats, overall };
  }, [activeMember]);

  const getAdherenceColor = (percent: number) => {
      if (percent >= 80) return '#34d399'; // Emerald
      if (percent >= 50) return '#fb923c'; // Orange
      return '#f87171'; // Red
  };

  const adherenceColor = getAdherenceColor(adherenceStats.overall);

  return (
    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 pb-20">
      <div className="flex flex-col items-center py-8 relative overflow-hidden">
        {/* Decorative Background Elements */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120%] h-[300px] bg-gradient-to-b from-[#00c2ff]/10 to-transparent rounded-full blur-3xl -z-10"></div>

        <div className="w-24 h-24 rounded-full border-2 border-[#00c2ff] p-1 mb-4 shadow-[0_0_20px_rgba(0,194,255,0.2)] relative group">
          <div className="w-full h-full rounded-full overflow-hidden bg-zinc-800">
            <img src={activeMember.avatar} alt="me" className="w-full h-full object-cover" />
          </div>
          <div className="absolute -bottom-1 -right-1 bg-[#1c1c1e] rounded-full p-1.5 border border-white/10">
              <div className="w-4 h-4 rounded-full bg-emerald-500 border-2 border-[#1c1c1e]"></div>
          </div>
        </div>
        <h3 className="text-2xl font-bold text-white tracking-tight">{activeMember.name}</h3>
        <p className="text-zinc-500 text-sm font-medium uppercase tracking-widest mt-1">Gói Premium</p>
      </div>

      {/* Adherence Report Card */}
      <div className="px-4 mb-8">
          <div className="bg-[#1c1c1e] rounded-[2rem] p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 right-0 p-8 opacity-5 pointer-events-none">
                  <TrendingUp className="w-32 h-32 text-white" />
              </div>

              <div className="flex items-center justify-between mb-6 relative z-10">
                  <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#00c2ff]/10 flex items-center justify-center">
                          <Award className="w-5 h-5 text-[#00c2ff]" />
                      </div>
                      <div>
                          <h4 className="font-bold text-white text-sm">Báo cáo tuân thủ</h4>
                          <p className="text-xs text-zinc-500 font-medium">7 ngày qua</p>
                      </div>
                  </div>
                  <div className="text-right">
                      <span className="text-3xl font-black tracking-tighter" style={{ color: adherenceColor }}>{adherenceStats.overall}%</span>
                  </div>
              </div>

              {/* Chart */}
              <div className="flex items-end justify-between h-32 gap-2 relative z-10">
                  {adherenceStats.daily.map((day, idx) => (
                      <div key={idx} className="flex-1 flex flex-col items-center gap-2 group">
                          <div className="w-full relative flex-1 flex items-end">
                              <div className="w-full bg-zinc-800/50 rounded-t-lg absolute inset-0"></div>
                              <div 
                                className="w-full rounded-t-lg transition-all duration-500 relative group-hover:opacity-80"
                                style={{ 
                                    height: `${day.percent}%`, 
                                    backgroundColor: getAdherenceColor(day.percent),
                                    boxShadow: day.isToday ? `0 0 15px ${getAdherenceColor(day.percent)}40` : 'none'
                                }}
                              >
                                {day.percent > 0 && (
                                    <div className="absolute -top-6 left-1/2 -translate-x-1/2 text-[10px] font-bold text-white opacity-0 group-hover:opacity-100 transition-opacity bg-black/80 px-1.5 py-0.5 rounded">
                                        {day.percent}%
                                    </div>
                                )}
                              </div>
                          </div>
                          <span className={`text-[10px] font-bold ${day.isToday ? 'text-white' : 'text-zinc-600'}`}>
                              {day.label}
                          </span>
                      </div>
                  ))}
              </div>

              <div className="mt-6 pt-4 border-t border-white/5 flex items-start gap-3">
                  <AlertCircle className="w-4 h-4 text-zinc-500 mt-0.5" />
                  <p className="text-xs text-zinc-400 leading-relaxed">
                      {adherenceStats.overall >= 80 
                        ? "Tuyệt vời! Bạn đang duy trì lịch uống thuốc rất đều đặn. Hãy tiếp tục phát huy!"
                        : adherenceStats.overall >= 50
                        ? "Khá tốt. Cố gắng không bỏ lỡ các liều thuốc vào buổi tối để đạt hiệu quả tốt nhất."
                        : "Cần chú ý hơn. Hãy bật thông báo hoặc nhờ người thân nhắc nhở để cải thiện."
                      }
                  </p>
              </div>
          </div>
      </div>

      <div className="mb-8">
         <div className="px-6 pb-3 text-[11px] font-black text-zinc-600 uppercase tracking-widest">Gia đình</div>
         <div className="flex items-center gap-4 overflow-x-auto no-scrollbar py-2 px-6">
           {members.map((member) => (
             <button 
               key={member.id}
               onClick={() => setActiveMemberId(member.id)}
               className="flex flex-col items-center gap-2 group flex-shrink-0"
             >
               <div className={`relative w-[60px] h-[60px] rounded-full flex items-center justify-center transition-all duration-300 ${
                 activeMemberId === member.id ? 'ring-2 ring-[#00c2ff] ring-offset-2 ring-offset-black scale-105' : 'opacity-60 grayscale'
               }`}>
                 <div className="w-full h-full rounded-full overflow-hidden bg-zinc-800">
                   <img src={member.avatar} alt={member.name} className="w-full h-full object-cover" />
                 </div>
               </div>
               <span className={`text-[10px] font-bold transition-colors mt-0.5 ${activeMemberId === member.id ? 'text-[#00c2ff]' : 'text-slate-500'}`}>
                 {member.name}
               </span>
             </button>
           ))}
           <button onClick={() => setIsAddMemberOpen(true)} className="flex flex-col items-center gap-2 flex-shrink-0">
              <div className="w-[60px] h-[60px] rounded-full bg-zinc-800/10 flex items-center justify-center border border-dashed border-zinc-700 hover:bg-zinc-800/30 transition-colors">
                 <Plus className="text-slate-500 w-5 h-5" />
              </div>
              <span className="text-[10px] font-bold text-slate-500 mt-0.5 uppercase tracking-tighter">Thêm</span>
           </button>
         </div>
      </div>

      <div className="space-y-2 px-4">
        <div className="px-2 pb-2 text-[11px] font-black text-zinc-600 uppercase tracking-widest">Cài đặt</div>
        <button className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#1c1c1e] hover:bg-zinc-800 transition-colors border border-white/5">
          <UserCircle className="w-5 h-5 text-[#00c2ff]" />
          <span className="font-bold text-sm text-zinc-200">Thông tin cá nhân</span>
          <ChevronRight className="w-4 h-4 text-zinc-600 ml-auto" />
        </button>
        <button className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#1c1c1e] hover:bg-zinc-800 transition-colors border border-white/5">
          <ShieldCheck className="w-5 h-5 text-[#00d892]" />
          <span className="font-bold text-sm text-zinc-200">Bảo mật & Quyền riêng tư</span>
          <ChevronRight className="w-4 h-4 text-zinc-600 ml-auto" />
        </button>
        <button className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#1c1c1e] hover:bg-zinc-800 transition-colors border border-white/5">
          <Settings className="w-5 h-5 text-zinc-400" />
          <span className="font-bold text-sm text-zinc-200">Cài đặt ứng dụng</span>
          <ChevronRight className="w-4 h-4 text-zinc-600 ml-auto" />
        </button>
        <button className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#1c1c1e] hover:bg-zinc-800 transition-colors border border-white/5">
          <HelpCircle className="w-5 h-5 text-zinc-400" />
          <span className="font-bold text-sm text-zinc-200">Hỗ trợ & FAQ</span>
          <ChevronRight className="w-4 h-4 text-zinc-600 ml-auto" />
        </button>
      </div>

      <div className="px-4">
        <button 
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 p-4 rounded-2xl bg-red-500/10 text-red-500 mt-8 font-bold active:scale-95 transition-all"
        >
            <LogOut className="w-5 h-5" /> Đăng xuất
        </button>
      </div>
      <p className="text-[10px] text-zinc-700 font-bold uppercase tracking-[0.2em] text-center mt-8 opacity-50">MedIntel v1.0.4</p>
    </div>
  );
};
