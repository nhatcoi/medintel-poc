
import React, { useState, useMemo } from 'react';
import { ChevronLeft, Plus, ChevronRight } from 'lucide-react';
import { MetricType, HealthLog } from '../../types';
import { HEALTH_METRICS_CONFIG } from '../../constants';

interface HealthChartDetailProps {
  metricType: MetricType;
  onClose: () => void;
  healthLogs: HealthLog[];
  onAddRecord: () => void;
}

type TimeRange = 'new' | '7d' | '14d' | '30d' | '90d' | '1y';

export const HealthChartDetail: React.FC<HealthChartDetailProps> = ({ 
  metricType, 
  onClose, 
  healthLogs,
  onAddRecord
}) => {
  const [range, setRange] = useState<TimeRange>('new');
  const config = HEALTH_METRICS_CONFIG[metricType];

  // 1. Filter Logs by Metric Type
  const logs = useMemo(() => {
    return healthLogs
        .filter(l => l.type === metricType)
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  }, [healthLogs, metricType]);

  // 2. Filter Logs by Time Range for Chart
  const chartData = useMemo(() => {
    if (range === 'new') return logs.slice(0, 5).reverse(); // Just show last 5 for "New"

    const now = new Date();
    const cutoff = new Date();
    if (range === '7d') cutoff.setDate(now.getDate() - 7);
    if (range === '14d') cutoff.setDate(now.getDate() - 14);
    if (range === '30d') cutoff.setDate(now.getDate() - 30);
    if (range === '90d') cutoff.setDate(now.getDate() - 90);
    if (range === '1y') cutoff.setFullYear(now.getFullYear() - 1);

    return logs.filter(l => new Date(l.timestamp) >= cutoff).reverse(); // Reverse to have oldest first for chart
  }, [logs, range]);

  const latestLog = logs[0];

  // 3. Chart Scaling Logic
  const getChartPoints = () => {
    if (chartData.length === 0) return [];
    
    // Determine Max/Min for Y Axis
    let maxVal = 0;
    let minVal = 1000;

    chartData.forEach(d => {
        if (metricType === 'bp') {
            const sys = parseInt(d.values.systolic || '0');
            const dia = parseInt(d.values.diastolic || '0');
            if (sys > maxVal) maxVal = sys;
            if (sys < minVal) minVal = sys;
            if (dia > maxVal) maxVal = dia;
            if (dia < minVal) minVal = dia;
        } else {
            const val = parseFloat(d.values.value || '0');
            if (val > maxVal) maxVal = val;
            if (val < minVal) minVal = val;
        }
    });

    // Padding
    maxVal = Math.ceil(maxVal * 1.1);
    minVal = Math.floor(minVal * 0.9);
    const rangeY = maxVal - minVal || 10;

    // SVG Dimensions
    const width = 320;
    const height = 160;
    const paddingX = 20;
    const paddingY = 20;

    return chartData.map((d, i) => {
        const x = paddingX + (i / (Math.max(chartData.length - 1, 1))) * (width - 2 * paddingX);
        
        if (metricType === 'bp') {
            const sys = parseInt(d.values.systolic || '0');
            const dia = parseInt(d.values.diastolic || '0');
            const ySys = height - paddingY - ((sys - minVal) / rangeY) * (height - 2 * paddingY);
            const yDia = height - paddingY - ((dia - minVal) / rangeY) * (height - 2 * paddingY);
            return { x, ySys, yDia, sys, dia, date: d.timestamp };
        } else {
             const val = parseFloat(d.values.value || '0');
             const y = height - paddingY - ((val - minVal) / rangeY) * (height - 2 * paddingY);
             return { x, y, val, date: d.timestamp };
        }
    });
  };

  const points = getChartPoints();

  return (
    <div className="absolute inset-0 z-[200] flex flex-col bg-black animate-in slide-in-from-right duration-300">
        
        {/* Header */}
        <div className="px-6 pt-12 pb-4 bg-black flex items-center justify-between">
            <h2 className="text-3xl font-bold text-white tracking-tight">{config.label}</h2>
             <button onClick={onClose} className="p-2 -mr-2 text-zinc-400 active:text-white bg-zinc-900/50 rounded-full">
                  <ChevronLeft className="w-6 h-6" />
              </button>
        </div>

        {/* Range Selector */}
        <div className="px-6 mb-8">
            <div className="flex bg-[#1c1c1e] rounded-xl p-1 overflow-x-auto no-scrollbar">
                {(['new', '7d', '14d', '30d', '90d', '1y'] as TimeRange[]).map((r) => (
                    <button
                        key={r}
                        onClick={() => setRange(r)}
                        className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-bold uppercase transition-all whitespace-nowrap ${
                            range === r 
                            ? 'bg-[#6366f1] text-white shadow-md' 
                            : 'text-zinc-500 hover:text-zinc-300'
                        }`}
                    >
                        {r === 'new' ? 'Mới' : r}
                    </button>
                ))}
            </div>
        </div>

        {/* Chart Area */}
        <div className="flex-1 px-6 relative">
            <div className="h-[220px] w-full relative mb-8">
                 {/* Background Grid Lines (Static) */}
                 <div className="absolute inset-0 flex flex-col justify-between text-[10px] text-zinc-600 font-medium">
                     <div className="border-b border-zinc-800 w-full h-0"></div>
                     <div className="border-b border-zinc-800 w-full h-0"></div>
                     <div className="border-b border-zinc-800 w-full h-0"></div>
                     <div className="border-b border-zinc-800 w-full h-0"></div>
                     <div className="border-b border-zinc-800 w-full h-0"></div>
                 </div>

                 {/* SVG Chart */}
                 <svg className="absolute inset-0 w-full h-full overflow-visible" preserveAspectRatio="none" viewBox="0 0 320 160">
                     {points.length > 0 && (
                         <>
                            {metricType === 'bp' ? (
                                <>
                                    {/* Systolic Line (Red) */}
                                    <path 
                                        d={`M ${points.map(p => `${p.x},${p.ySys}`).join(' L ')}`} 
                                        fill="none" 
                                        stroke="#f87171" 
                                        strokeWidth="2" 
                                        opacity="0.5"
                                    />
                                    {/* Diastolic Line (Blue) */}
                                    <path 
                                        d={`M ${points.map(p => `${p.x},${p.yDia}`).join(' L ')}`} 
                                        fill="none" 
                                        stroke="#3b82f6" 
                                        strokeWidth="2" 
                                        opacity="0.5"
                                    />
                                    {/* Points */}
                                    {points.map((p, i) => (
                                        <g key={i}>
                                            <circle cx={p.x} cy={p.ySys} r="4" fill="#111" stroke="#f87171" strokeWidth="2" />
                                            <circle cx={p.x} cy={p.yDia} r="4" fill="#111" stroke="#3b82f6" strokeWidth="2" />
                                        </g>
                                    ))}
                                </>
                            ) : (
                                <>
                                    <path 
                                        d={`M ${points.map(p => `${p.x},${p.y}`).join(' L ')}`} 
                                        fill="none" 
                                        stroke="#00c2ff" 
                                        strokeWidth="2"
                                        opacity="0.8" 
                                    />
                                    <path 
                                        d={`M ${points.map(p => `${p.x},${p.y}`).join(' L ')} L ${points[points.length-1].x},160 L ${points[0].x},160 Z`} 
                                        fill="url(#gradientArea)" 
                                        opacity="0.2"
                                    />
                                    <defs>
                                        <linearGradient id="gradientArea" x1="0" x2="0" y1="0" y2="1">
                                            <stop offset="0%" stopColor="#00c2ff" />
                                            <stop offset="100%" stopColor="#00c2ff" stopOpacity="0" />
                                        </linearGradient>
                                    </defs>
                                    {points.map((p, i) => (
                                        <circle key={i} cx={p.x} cy={p.y} r="4" fill="#111" stroke="#00c2ff" strokeWidth="2" />
                                    ))}
                                </>
                            )}
                         </>
                     )}
                 </svg>
            </div>

            {/* Legend */}
            {metricType === 'bp' ? (
                <div className="flex items-center gap-6 mb-8">
                     <div className="flex items-center gap-2">
                         <div className="w-2.5 h-2.5 rounded-full bg-red-400"></div>
                         <span className="text-zinc-400 text-xs font-bold">Tâm thu (Systolic)</span>
                     </div>
                     <div className="flex items-center gap-2">
                         <div className="w-2.5 h-2.5 rounded-full bg-blue-500"></div>
                         <span className="text-zinc-400 text-xs font-bold">Tâm trương (Diastolic)</span>
                     </div>
                </div>
            ) : (
                 <div className="flex items-center gap-2 mb-8">
                     <div className="w-2.5 h-2.5 rounded-full bg-[#00c2ff] shadow-[0_0_10px_#00c2ff]"></div>
                     <span className="text-zinc-400 text-xs font-bold">Chỉ số đo lường</span>
                 </div>
            )}

            {/* Latest Record Card */}
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-white font-bold text-sm">Bản ghi mới nhất</h3>
                <button className="text-zinc-500 text-xs font-bold flex items-center gap-1">Tất cả <ChevronRight className="w-3 h-3" /></button>
            </div>
            
            {latestLog ? (
                 <div className="bg-[#1c1c1e] rounded-[1.5rem] p-5 border border-white/5 flex items-center justify-between mb-24">
                     <div>
                         <span className="text-3xl font-black text-white tracking-tighter">
                            {metricType === 'bp' 
                                ? `${latestLog.values.systolic}/${latestLog.values.diastolic}` 
                                : latestLog.values.value}
                         </span>
                         <span className="text-sm font-bold text-zinc-500 ml-1">{config.unit}</span>
                     </div>
                     <div className="text-right">
                         <div className="text-zinc-400 text-sm font-bold">
                             {new Date(latestLog.timestamp).toLocaleDateString('vi-VN', { month: '2-digit', day: '2-digit' })}
                         </div>
                         <div className="text-zinc-600 text-xs font-bold mt-0.5">
                             {new Date(latestLog.timestamp).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                         </div>
                     </div>
                     <ChevronRight className="w-5 h-5 text-zinc-600" />
                 </div>
            ) : (
                <div className="text-center py-8 text-zinc-500 text-sm font-medium">Chưa có dữ liệu</div>
            )}
            
        </div>

        {/* Footer Button */}
        <div className="absolute bottom-0 left-0 right-0 p-6 bg-black z-10 border-t border-white/5">
            <button 
                onClick={onAddRecord}
                className="w-full py-4 bg-[#6366f1] text-white rounded-2xl font-bold text-base flex items-center justify-center gap-2 shadow-lg shadow-[#6366f1]/20 active:scale-95 transition-all"
            >
                <Plus className="w-5 h-5" /> Thêm bản ghi mới
            </button>
        </div>
    </div>
  );
};
