
import React, { useState, useEffect } from 'react';
import { X, Check, Clock, Trash2, Edit2, ChevronLeft, Pill, AlertTriangle, Calendar, Info, Bell } from 'lucide-react';
import { ExtendedMedication } from '../../../types';
import { MEDICATION_ICONS } from '../../../constants';

interface MedicationActionModalProps {
  medication: ExtendedMedication;
  onClose: () => void;
  onAction: (action: 'take' | 'skip' | 'untake') => void;
  onUpdate: (updatedMed: ExtendedMedication, scope: 'single' | 'all') => void;
  onDelete: () => void;
}

export const MedicationActionModal: React.FC<MedicationActionModalProps> = ({
  medication,
  onClose,
  onAction,
  onUpdate,
  onDelete
}) => {
  // Views: 'default' | 'reschedule' | 'quick-edit'
  const [currentView, setCurrentView] = useState<'default' | 'reschedule' | 'quick-edit'>('default');
  
  // Quick Edit State (Time & Dosage only for check-in adjustments)
  const [editForm, setEditForm] = useState<ExtendedMedication>(medication);

  // Reschedule State
  const [rescheduleTime, setRescheduleTime] = useState(medication.timeOfDay[0] || '08:00');

  useEffect(() => {
    setEditForm(medication);
    setRescheduleTime(medication.timeOfDay[0] || '08:00');
  }, [medication]);

  // --- HANDLERS ---

  const handleSaveQuickEdit = () => {
    // For check-in view, we usually just want to adjust THIS specific dose if it's incorrect
    onUpdate(editForm, 'single');
    setCurrentView('default');
  };

  const handleConfirmReschedule = () => {
    const updated = { ...medication, timeOfDay: [rescheduleTime] };
    onUpdate(updated, 'single');
    setCurrentView('default');
  };

  const addMinutes = (minutes: number) => {
    const [h, m] = rescheduleTime.split(':').map(Number);
    const date = new Date();
    date.setHours(h);
    date.setMinutes(m + minutes);
    const newTime = date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false });
    setRescheduleTime(newTime);
  };

  const getDosageNum = () => {
    const match = editForm.dosage.match(/^[\d.]+/);
    return match ? match[0] : '';
  };

  const getDosageUnit = () => {
    const num = getDosageNum();
    return editForm.dosage.replace(num, '').trim() || 'viên';
  };

  const handleDosageChange = (num: string, unit: string) => {
    setEditForm(prev => ({ ...prev, dosage: `${num} ${unit}`.trim() }));
  };

  // --- RENDER HELPERS ---
  const MedIcon = MEDICATION_ICONS[medication.icon || 'pill'] || Pill;
  const medColor = medication.color || '#00c2ff';

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm pointer-events-auto transition-opacity" onClick={onClose}></div>
      
      {/* CARD CONTAINER */}
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/5 shadow-2xl overflow-hidden h-auto min-h-[50vh]">
        
        {currentView === 'quick-edit' && (
            // --- QUICK EDIT VIEW (For Check-in Context) ---
            <div className="flex flex-col h-full">
                <div className="flex justify-between items-center p-6 border-b border-white/5">
                    <button onClick={() => setCurrentView('default')} className="text-zinc-400 flex items-center gap-1 font-medium text-sm hover:text-white transition-colors">
                        <ChevronLeft className="w-4 h-4" /> Hủy
                    </button>
                    <h3 className="text-lg font-bold text-white">Sửa nhanh liều này</h3>
                    <div className="w-8"></div>
                </div>
                
                <div className="p-6 space-y-6 flex-1">
                    <p className="text-zinc-500 text-sm text-center mb-4">Thay đổi này chỉ áp dụng cho lần uống hiện tại.</p>
                    
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Liều lượng</label>
                            <input type="number" value={getDosageNum()} onChange={(e) => handleDosageChange(e.target.value, getDosageUnit())} className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl p-4 text-white font-bold focus:outline-none focus:border-[#00c2ff]" />
                        </div>
                        <div>
                            <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Đơn vị</label>
                            <input type="text" value={getDosageUnit()} onChange={(e) => handleDosageChange(getDosageNum(), e.target.value)} className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl p-4 text-white font-bold focus:outline-none focus:border-[#00c2ff]" />
                        </div>
                    </div>
                    <div>
                        <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Giờ uống thực tế</label>
                        <input type="time" value={editForm.timeOfDay[0]} onChange={(e) => setEditForm({...editForm, timeOfDay: [e.target.value]})} className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl p-4 text-white font-bold focus:outline-none focus:border-[#00c2ff]" />
                    </div>
                    
                    <button onClick={handleSaveQuickEdit} className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20 mt-4">
                        Lưu thay đổi
                    </button>
                </div>
            </div>
        )}

        {currentView === 'reschedule' && (
            // --- RESCHEDULE VIEW ---
            <div className="flex flex-col h-full">
                <div className="flex justify-between items-center p-6 border-b border-white/5">
                    <button onClick={() => setCurrentView('default')} className="text-zinc-400 flex items-center gap-1 font-medium text-sm hover:text-white transition-colors">
                        <ChevronLeft className="w-4 h-4" /> Quay lại
                    </button>
                    <h3 className="text-lg font-bold text-white">Hẹn giờ uống lại</h3>
                    <div className="w-8"></div>
                </div>
                
                <div className="p-6 flex flex-col items-center justify-center flex-1 space-y-8">
                    <div className="text-center">
                        <div className="text-zinc-500 font-medium mb-4">Chọn thời gian mới cho liều này</div>
                        <div className="relative inline-block">
                             <input 
                                type="time" 
                                value={rescheduleTime}
                                onChange={(e) => setRescheduleTime(e.target.value)}
                                className="bg-[#1c1c1e] text-5xl font-black text-white focus:outline-none text-center w-48 p-2 rounded-2xl border border-zinc-800 focus:border-[#00c2ff] transition-colors"
                             />
                        </div>
                    </div>

                    <div className="grid grid-cols-3 gap-3 w-full">
                        <button onClick={() => addMinutes(15)} className="py-3 rounded-xl bg-zinc-800 text-zinc-300 font-bold text-sm hover:bg-zinc-700 transition-colors">+15 phút</button>
                        <button onClick={() => addMinutes(30)} className="py-3 rounded-xl bg-zinc-800 text-zinc-300 font-bold text-sm hover:bg-zinc-700 transition-colors">+30 phút</button>
                        <button onClick={() => addMinutes(60)} className="py-3 rounded-xl bg-zinc-800 text-zinc-300 font-bold text-sm hover:bg-zinc-700 transition-colors">+1 giờ</button>
                    </div>

                    <button onClick={handleConfirmReschedule} className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20">
                        Xác nhận thời gian
                    </button>
                </div>
            </div>
        )}

        {currentView === 'default' && (
            // --- CHECK-IN / ACTION VIEW ---
            <div className="flex flex-col h-full relative">
                
                {/* Header Icons */}
                <div className="flex justify-between items-center px-6 py-6 w-full z-10">
                    <div className="flex gap-2">
                        <span className="bg-zinc-800 text-zinc-400 px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider">
                           {medication.groupId ? 'Nhóm định kỳ' : 'Liều đơn'}
                        </span>
                    </div>
                    <div className="flex gap-4 text-zinc-500">
                         {/* Removed Delete for Timeline View to prevent accidental deletion of regimen */}
                        <button onClick={() => setCurrentView('quick-edit')} className="hover:text-white transition-colors flex items-center gap-1 text-xs font-bold bg-zinc-800 px-3 py-1.5 rounded-full">
                            <Edit2 className="w-3 h-3" /> Sửa nhanh
                        </button>
                    </div>
                </div>

                {/* Main Content */}
                <div className="flex-1 flex flex-col items-center justify-start pt-4 px-6">
                    {/* Pill Icon */}
                    <div className="relative mb-6">
                         <div 
                             className="w-20 h-10 rounded-full opacity-20 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 blur-xl"
                             style={{ backgroundColor: medColor, boxShadow: `0 0 30px ${medColor}` }}
                         ></div>
                         <MedIcon className="w-16 h-16" strokeWidth={1.5} style={{ color: medColor }} />
                    </div>

                    {/* Title */}
                    <h2 className="text-3xl font-medium text-white mb-2 text-center tracking-tight">{medication.name}</h2>
                    
                    {/* Status Text */}
                    <p className="font-medium text-sm mb-10 text-center" style={{ color: medColor }}>
                        {medication.taken 
                            ? `Đã uống lúc ${medication.takenAt?.split(',')[0]}` 
                            : `Lên lịch lúc ${medication.timeOfDay[0]}, hôm nay`}
                    </p>

                    {/* Info Rows */}
                    <div className="w-full space-y-5 px-4">
                        <div className="flex items-center gap-5">
                            <Calendar className="w-6 h-6 text-zinc-600" strokeWidth={1.5} />
                            <span className="text-zinc-400 text-sm font-medium">Lịch nhắc: {medication.timeOfDay[0]}</span>
                        </div>
                        <div className="flex items-center gap-5">
                            <Info className="w-6 h-6 text-zinc-600" strokeWidth={1.5} />
                            <span className="text-zinc-400 text-sm font-medium">{medication.dosage}</span>
                        </div>
                        {medication.notes && (
                            <div className="flex items-start gap-5">
                                <Info className="w-6 h-6 text-zinc-600 mt-0.5" strokeWidth={1.5} />
                                <span className="text-zinc-400 text-sm font-medium italic">"{medication.notes}"</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Footer Actions */}
                <div className="p-8 pb-12 flex justify-between items-end w-full">
                     {/* Skip Button */}
                     <div className="flex flex-col items-center gap-3 w-1/3">
                        <button 
                            onClick={() => onAction(medication.skipped ? 'untake' : 'skip')}
                            className={`w-14 h-14 rounded-full flex items-center justify-center transition-all active:scale-95 ${
                                medication.skipped ? 'bg-zinc-700 text-white' : 'bg-zinc-800'
                            }`}
                            style={{ color: medication.skipped ? 'white' : medColor }}
                        >
                           <X className="w-6 h-6" />
                        </button>
                        <span className="text-sm font-medium" style={{ color: medColor }}>{medication.skipped ? 'Bỏ qua' : 'Bỏ qua'}</span>
                     </div>

                     {/* Take Button (Center, Large) */}
                     <div className="flex flex-col items-center gap-3 w-1/3 -mt-4">
                        <button 
                            onClick={() => onAction(medication.taken ? 'untake' : 'take')}
                            className={`w-20 h-20 rounded-full flex items-center justify-center transition-all active:scale-95 shadow-lg`}
                            style={{ 
                                backgroundColor: medication.taken ? '#10b981' : medColor,
                                color: medication.taken ? 'white' : 'black',
                                boxShadow: medication.taken ? '0 0 20px rgba(16,185,129,0.3)' : `0 0 20px ${medColor}40`
                            }}
                        >
                           <Check className="w-8 h-8 stroke-[3]" />
                        </button>
                        <span className={`text-sm font-medium ${medication.taken ? 'text-emerald-500' : ''}`} style={{ color: !medication.taken ? medColor : undefined }}>
                            {medication.taken ? 'Đã uống' : 'Uống'}
                        </span>
                     </div>

                     {/* Reschedule Button */}
                     <div className="flex flex-col items-center gap-3 w-1/3">
                        <button onClick={() => setCurrentView('reschedule')} className="w-14 h-14 rounded-full bg-zinc-800 flex items-center justify-center active:scale-95 transition-all" style={{ color: medColor }}>
                           <Clock className="w-6 h-6" />
                        </button>
                        <span className="text-sm font-medium" style={{ color: medColor }}>Hẹn lại</span>
                     </div>
                </div>
            </div>
        )}
      </div>
    </div>
  );
};
