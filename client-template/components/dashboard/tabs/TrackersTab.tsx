
import React, { useState } from 'react';
import { Plus, Check, MoreHorizontal } from 'lucide-react';
import { HEALTH_METRICS_CONFIG, HABIT_CATEGORIES_CONFIG, HABIT_ICONS_MAP } from '../../../constants';
import { HealthLog, MetricType, HealthHabit, HabitLog } from '../../../types';

interface TrackersTabProps {
  healthLogs: HealthLog[];
  activeMemberId: string;
  setViewingMetric: (metric: MetricType | null) => void;
  openTrackerModal: (metric: MetricType) => void;
  getMetricStyle: (metric: MetricType) => any;
  getLatestLog: (metric: MetricType) => HealthLog | undefined;
  
  // New props for Habits
  habits: HealthHabit[];
  habitLogs: HabitLog[];
  onAddHabit: () => void;
  onLogHabit: (habitId: string, value: number) => void;
  onViewHabit: (habit: HealthHabit) => void; // NEW
  selectedDate: Date;
}

export const TrackersTab: React.FC<TrackersTabProps> = ({ 
  healthLogs, 
  activeMemberId, 
  setViewingMetric, 
  openTrackerModal, 
  getMetricStyle,
  getLatestLog,
  habits,
  habitLogs,
  onAddHabit,
  onLogHabit,
  onViewHabit,
  selectedDate
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'metrics' | 'habits'>('metrics');

  // --- METRICS LOGIC ---
  const memberLogs = healthLogs.filter(log => log.memberId === activeMemberId);
  const activeTypes = new Set(memberLogs.map(log => log.type));
  
  const activeMetrics = Object.values(HEALTH_METRICS_CONFIG).filter(m => activeTypes.has(m.id));
  const availableMetrics = Object.values(HEALTH_METRICS_CONFIG).filter(m => !activeTypes.has(m.id));

  // --- HABITS LOGIC ---
  const memberHabits = habits.filter(h => h.memberId === activeMemberId); // In real app, check ID
  const dateKey = selectedDate.toISOString().split('T')[0];

  const getHabitProgress = (habitId: string) => {
      const logs = habitLogs.filter(l => l.habitId === habitId && l.date === dateKey);
      const total = logs.reduce((sum, log) => sum + log.value, 0);
      return total;
  };

  const handleQuickAdd = (e: React.MouseEvent, habit: HealthHabit) => {
      e.stopPropagation(); // Prevent opening detail
      // Add 1 unit or a small increment
      const increment = habit.targetValue <= 10 ? 1 : Math.ceil(habit.targetValue / 4);
      onLogHabit(habit.id, increment);
  };

  return (
      <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 pb-20">
          <div className="flex items-center justify-between mb-6">
              <h3 className="text-2xl font-black text-white tracking-tight">Sức khỏe</h3>
              {/* Sub-tab Switcher */}
              <div className="flex bg-[#1c1c1e] p-1 rounded-xl border border-white/10">
                  <button 
                    onClick={() => setActiveSubTab('metrics')}
                    className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${activeSubTab === 'metrics' ? 'bg-[#00c2ff] text-white shadow-md' : 'text-zinc-500 hover:text-zinc-300'}`}
                  >
                      Chỉ số
                  </button>
                  <button 
                    onClick={() => setActiveSubTab('habits')}
                    className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${activeSubTab === 'habits' ? 'bg-[#00c2ff] text-white shadow-md' : 'text-zinc-500 hover:text-zinc-300'}`}
                  >
                      Thói quen
                  </button>
              </div>
          </div>
          
          {activeSubTab === 'metrics' ? (
              // --- METRICS VIEW ---
              <>
                {activeMetrics.length > 0 && (
                    <div className="grid grid-cols-2 gap-4 mb-8 animate-in slide-in-from-right duration-300">
                        {activeMetrics.map(metric => {
                            const latest = getLatestLog(metric.id);
                            if (!latest) return null;
                            
                            let displayValue = "";
                            if (metric.id === 'bp') {
                                displayValue = `${latest.values.systolic}/${latest.values.diastolic}`;
                            } else {
                                displayValue = latest.values.value || "--";
                            }
                            
                            const style = getMetricStyle(metric.id);
                            
                            const date = new Date(latest.timestamp);
                            const isToday = new Date().toDateString() === date.toDateString();
                            const timeStr = isToday ? date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : date.toLocaleDateString();

                            return (
                                <button 
                                    key={metric.id}
                                    onClick={() => setViewingMetric(metric.id)}
                                    className={`bg-[#1c1c1e] p-5 rounded-[1.5rem] border border-white/5 flex flex-col justify-between h-44 relative overflow-hidden group hover:border-white/10 transition-all ${metric.id === 'bp' ? 'col-span-2' : ''}`}
                                >
                                    <div className={`absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity`}>
                                        <metric.icon className={`w-24 h-24 ${style.class}`} />
                                    </div>
                                    <div className="flex justify-between items-start w-full relative z-10">
                                        <div className={`w-10 h-10 rounded-full ${style.bg} flex items-center justify-center`}>
                                            <metric.icon className={`w-5 h-5 ${style.class}`} />
                                        </div>
                                        <span className="text-[10px] font-bold text-zinc-500 bg-zinc-800/50 px-2 py-1 rounded-full">{timeStr}</span>
                                    </div>
                                    
                                    <div className="relative z-10 text-left w-full">
                                        <span className="text-zinc-500 text-xs font-bold uppercase tracking-wider block mb-1">{metric.label}</span>
                                        <div className="flex items-end gap-1.5">
                                            <span className={`font-black text-white tracking-tight ${metric.id === 'bp' ? 'text-4xl' : 'text-3xl'}`}>
                                                {displayValue}
                                            </span>
                                            <span className={`text-sm font-bold mb-1.5 ${style.class.replace('text-', 'text-opacity-60 text-')}`}>{metric.unit}</span>
                                        </div>
                                        {latest.tag && (
                                            <span className="text-[10px] font-bold text-zinc-600 mt-2 block bg-zinc-900/50 w-fit px-2 py-0.5 rounded border border-white/5">{latest.tag}</span>
                                        )}
                                    </div>
                                </button>
                            );
                        })}
                    </div>
                )}

                <h4 className="text-zinc-500 text-[10px] font-black uppercase tracking-widest mb-4">Có sẵn</h4>
                <div className="grid grid-cols-2 gap-3 animate-in slide-in-from-right duration-500">
                    {availableMetrics.map(metric => (
                        <button 
                            key={metric.id}
                            onClick={() => openTrackerModal(metric.id)}
                            className="bg-[#1c1c1e] p-4 rounded-2xl flex items-center gap-3 border border-white/5 hover:bg-zinc-800/50 transition-colors text-left"
                        >
                            <div className={`w-10 h-10 rounded-xl ${metric.bgColor} flex items-center justify-center flex-shrink-0`}>
                                <metric.icon className={`w-5 h-5 ${metric.color}`} />
                            </div>
                            <div>
                                <span className="text-zinc-200 font-bold text-sm block">{metric.label}</span>
                                <span className="text-zinc-600 text-[10px] font-bold uppercase">{metric.unit}</span>
                            </div>
                            <Plus className="w-4 h-4 text-zinc-600 ml-auto" />
                        </button>
                    ))}
                </div>
              </>
          ) : (
              // --- HABITS VIEW ---
              <div className="animate-in slide-in-from-right duration-300">
                  <div className="flex items-center justify-between mb-4 px-1">
                      <span className="text-zinc-500 text-xs font-bold uppercase">{selectedDate.toLocaleDateString('vi-VN', {weekday: 'long', day: '2-digit', month: '2-digit'})}</span>
                      <span className="text-zinc-600 text-[10px] font-bold">{memberHabits.length} Thói quen</span>
                  </div>

                  {memberHabits.length > 0 ? (
                      <div className="space-y-3">
                          {memberHabits.map(habit => {
                              const progress = getHabitProgress(habit.id);
                              const percent = Math.min((progress / habit.targetValue) * 100, 100);
                              
                              // Logic to determine icon: Custom > Config Default > Fallback
                              let HabitIcon = HABIT_CATEGORIES_CONFIG[habit.category]?.icon;
                              if (habit.icon && HABIT_ICONS_MAP[habit.icon]) {
                                  HabitIcon = HABIT_ICONS_MAP[habit.icon];
                              }
                              
                              const isComplete = percent >= 100;

                              return (
                                  <div 
                                    key={habit.id} 
                                    onClick={() => onViewHabit(habit)}
                                    className="bg-[#1c1c1e] rounded-2xl p-4 border border-white/5 relative overflow-hidden active:scale-[0.98] transition-all cursor-pointer"
                                  >
                                      {/* Progress Bar Background */}
                                      <div 
                                        className="absolute bottom-0 left-0 top-0 bg-white/5 transition-all duration-500"
                                        style={{ width: `${percent}%`, backgroundColor: `${habit.color || '#00c2ff'}10` }}
                                      ></div>

                                      <div className="flex items-center justify-between relative z-10">
                                          <div className="flex items-center gap-4">
                                              <div 
                                                className={`w-12 h-12 rounded-xl flex items-center justify-center transition-colors ${isComplete ? 'bg-emerald-500/20 text-emerald-500' : 'bg-zinc-800 text-zinc-400'}`}
                                                style={{ color: isComplete ? undefined : habit.color }}
                                              >
                                                  {isComplete ? <Check className="w-6 h-6" /> : <HabitIcon className="w-6 h-6" />}
                                              </div>
                                              <div>
                                                  <h4 className="font-bold text-white text-base">{habit.name}</h4>
                                                  <div className="flex items-center gap-2 mt-1">
                                                      <span className="text-xs font-bold text-zinc-500">{progress} / {habit.targetValue} {habit.unit}</span>
                                                      {habit.reminders.length > 0 && (
                                                          <span className="text-[10px] bg-zinc-800 text-zinc-500 px-1.5 rounded font-bold">{habit.reminders[0]}</span>
                                                      )}
                                                  </div>
                                              </div>
                                          </div>
                                          
                                          <button 
                                            onClick={(e) => handleQuickAdd(e, habit)}
                                            className="w-10 h-10 rounded-full bg-zinc-800 border border-white/5 flex items-center justify-center active:scale-95 transition-all hover:bg-zinc-700 hover:text-white text-zinc-400"
                                          >
                                              <Plus className="w-5 h-5" />
                                          </button>
                                      </div>
                                  </div>
                              );
                          })}
                      </div>
                  ) : (
                    <div className="text-center py-16 flex flex-col items-center gap-4 text-slate-600">
                        <div className="w-16 h-16 rounded-full bg-zinc-900/50 border border-zinc-800 flex items-center justify-center">
                            <Check className="w-6 h-6 opacity-20" />
                        </div>
                        <div>
                            <p className="text-sm font-bold text-zinc-400">Chưa có thói quen nào</p>
                            <p className="text-xs mt-1 opacity-50 font-medium">Bắt đầu xây dựng lối sống lành mạnh!</p>
                        </div>
                    </div>
                  )}

                  <button 
                    onClick={onAddHabit}
                    className="w-full py-4 mt-6 rounded-2xl border border-dashed border-zinc-700 text-zinc-500 font-bold hover:bg-zinc-800/50 transition-colors flex items-center justify-center gap-2"
                  >
                    <Plus className="w-5 h-5" /> Thêm thói quen mới
                  </button>
              </div>
          )}
      </div>
  );
};
