
import React, { useState, useEffect } from 'react';
import { X, ChevronLeft, ChevronRight, Check, Trash2, Edit2, Clock, Calendar, Bell, AlignLeft, Pill, Droplets, Syringe, Tablet, Plus, Minus, FolderPlus } from 'lucide-react';
import { ExtendedMedication } from '../../../types';
import { MEDICATION_ICONS, DOSAGE_UNITS } from '../../../constants';

interface MedicationDetailModalProps {
  medication: ExtendedMedication;
  onClose: () => void;
  onUpdate: (oldMed: ExtendedMedication, newMed: ExtendedMedication) => void;
  onDelete: (groupId: string) => void;
}

const COLORS = ['#00c2ff', '#f87171', '#fb923c', '#facc15', '#34d399', '#818cf8', '#c084fc', '#f472b6'];
const ICONS = [
  { id: 'pill', icon: Pill, label: 'Viên' },
  { id: 'tablet', icon: Tablet, label: 'Nén' },
  { id: 'syrup', icon: Droplets, label: 'Siro' },
  { id: 'injection', icon: Syringe, label: 'Tiêm' },
];

export const MedicationDetailModal: React.FC<MedicationDetailModalProps> = ({ 
  medication, 
  onClose, 
  onUpdate, 
  onDelete 
}) => {
  const [isEditing, setIsEditing] = useState(false);
  
  // --- FORM STATE (Derived from medication) ---
  const [name, setName] = useState(medication.name);
  const [prescriptionId, setPrescriptionId] = useState(medication.prescriptionId || '');
  const [selectedColor, setSelectedColor] = useState(medication.color || COLORS[0]);
  const [selectedIcon, setSelectedIcon] = useState(medication.icon || ICONS[0].id);
  
  // Parse Dosage
  const initialDosageNum = medication.dosage.match(/^[\d.]+/)?.[0] || '';
  const initialDosageUnit = medication.dosageUnit || medication.dosage.replace(initialDosageNum, '').trim() || 'viên';
  
  const [dosageNum, setDosageNum] = useState(initialDosageNum);
  const [dosageUnit, setDosageUnit] = useState(initialDosageUnit);
  const [direction, setDirection] = useState(medication.direction || 'Sau ăn');

  const [frequencyType, setFrequencyType] = useState(medication.frequencyType || 'daily');
  const [interval, setInterval] = useState(medication.interval || 1);
  
  // Times
  const [times, setTimes] = useState<string[]>(medication.timeOfDay || ['08:00']);
  
  const [duration, setDuration] = useState(medication.expectedDuration || '30 ngày');
  const [startDate, setStartDate] = useState(medication.startDate || new Date().toISOString().split('T')[0]);
  const [reminderEnabled, setReminderEnabled] = useState(medication.reminder ?? true);
  const [notes, setNotes] = useState(medication.notes || '');

  // Sub-modals for Edit Mode
  const [activeSubModal, setActiveSubModal] = useState<'none' | 'color' | 'unit'>('none');
  const [isDeleteConfirm, setIsDeleteConfirm] = useState(false);

  // --- HANDLERS ---
  const handleAddTime = () => setTimes([...times, '12:00']);
  const handleRemoveTime = (idx: number) => setTimes(times.filter((_, i) => i !== idx));
  const handleTimeChange = (idx: number, val: string) => {
    const newTimes = [...times];
    newTimes[idx] = val;
    setTimes(newTimes);
  };

  const handleSave = () => {
    const updatedMed: ExtendedMedication = {
      ...medication,
      name,
      prescriptionId: prescriptionId.trim(),
      dosage: `${dosageNum} ${dosageUnit}`.trim(),
      dosageUnit,
      frequency: frequencyType === 'daily' ? 'Mỗi ngày' : `Mỗi ${interval} ngày`,
      frequencyType,
      interval: frequencyType === 'interval' ? interval : undefined,
      timeOfDay: times.sort(),
      expectedDuration: duration,
      startDate,
      direction,
      color: selectedColor,
      icon: selectedIcon,
      reminder: reminderEnabled,
      notes,
    };
    onUpdate(medication, updatedMed);
    setIsEditing(false);
  };

  const handleDelete = () => {
      if (medication.groupId) {
          onDelete(medication.groupId);
      }
      onClose();
  };

  const MedIcon = MEDICATION_ICONS[selectedIcon] || Pill;

  // --- RENDER ---
  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={onClose}></div>
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
         
         {/* HEADER */}
         <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#1c1c1e] z-10 border-b border-white/5">
            {isEditing ? (
                <button onClick={() => setIsEditing(false)} className="text-zinc-400 flex items-center gap-1 font-medium text-sm hover:text-white transition-colors">
                    <ChevronLeft className="w-4 h-4" /> Hủy
                </button>
            ) : (
                <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                     <ChevronLeft className="w-5 h-5 text-zinc-400" />
                </button>
            )}
            
            <h3 className="text-lg font-bold text-white">
                {isEditing ? 'Sửa thuốc' : 'Chi tiết thuốc'}
            </h3>
            
            {isEditing ? (
                <div className="w-12"></div> // Spacer
            ) : (
                <button onClick={() => setIsEditing(true)} className="p-2 bg-[#00c2ff]/10 rounded-full text-[#00c2ff]">
                    <Edit2 className="w-5 h-5" />
                </button>
            )}
         </div>

         {/* CONTENT */}
         <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-24 space-y-6 pt-4">
             
             {!isEditing ? (
                 // --- VIEW MODE ---
                 <>
                    {/* Hero Info */}
                    <div className="flex flex-col items-center justify-center mb-6">
                         <div className="w-24 h-24 rounded-full flex items-center justify-center mb-4 relative" style={{ backgroundColor: `${selectedColor}20` }}>
                             <MedIcon className="w-12 h-12" style={{ color: selectedColor }} />
                             <div className="absolute inset-0 rounded-full blur-xl opacity-40" style={{ backgroundColor: selectedColor }}></div>
                         </div>
                         <h2 className="text-2xl font-bold text-white text-center mb-1">{name}</h2>
                         <p className="text-zinc-500 text-sm font-medium">{dosageNum} {dosageUnit} • {direction}</p>
                         {prescriptionId && (
                             <span className="mt-3 px-3 py-1 rounded-full bg-zinc-800 text-zinc-400 text-xs font-bold border border-white/5 flex items-center gap-1">
                                 <FolderPlus className="w-3 h-3" /> {prescriptionId}
                             </span>
                         )}
                    </div>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-2 gap-3">
                        <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5">
                             <div className="flex items-center gap-2 mb-2 text-zinc-400">
                                 <Clock className="w-4 h-4" />
                                 <span className="text-xs font-bold uppercase">Giờ uống</span>
                             </div>
                             <div className="flex flex-wrap gap-2">
                                 {times.map(t => (
                                     <span key={t} className="bg-black/30 px-2 py-1 rounded-md text-sm font-bold text-white">{t}</span>
                                 ))}
                             </div>
                        </div>
                        <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5">
                             <div className="flex items-center gap-2 mb-2 text-zinc-400">
                                 <Calendar className="w-4 h-4" />
                                 <span className="text-xs font-bold uppercase">Thời gian</span>
                             </div>
                             <span className="text-white font-bold text-sm block">{duration}</span>
                             <span className="text-zinc-500 text-xs">Từ {startDate}</span>
                        </div>
                        <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 col-span-2">
                             <div className="flex items-center gap-2 mb-2 text-zinc-400">
                                 <AlignLeft className="w-4 h-4" />
                                 <span className="text-xs font-bold uppercase">Ghi chú</span>
                             </div>
                             <p className="text-white text-sm leading-relaxed">
                                 {notes || "Không có ghi chú."}
                             </p>
                        </div>
                    </div>

                    {/* Delete Action */}
                    <div className="mt-8 pt-8 border-t border-white/5">
                        {!isDeleteConfirm ? (
                            <button 
                                onClick={() => setIsDeleteConfirm(true)}
                                className="w-full py-4 rounded-2xl border border-red-500/20 text-red-500 font-bold bg-red-500/5 hover:bg-red-500/10 transition-colors flex items-center justify-center gap-2"
                            >
                                <Trash2 className="w-5 h-5" /> Xóa thuốc này
                            </button>
                        ) : (
                            <div className="bg-red-500/10 rounded-2xl p-4 text-center border border-red-500/20">
                                <p className="text-red-400 font-bold mb-3 text-sm">Xóa toàn bộ lịch uống của thuốc này?</p>
                                <div className="flex gap-3">
                                    <button onClick={() => setIsDeleteConfirm(false)} className="flex-1 py-3 bg-zinc-800 rounded-xl text-white font-bold text-sm">Hủy</button>
                                    <button onClick={handleDelete} className="flex-1 py-3 bg-red-500 rounded-xl text-white font-bold text-sm shadow-lg shadow-red-500/20">Xóa ngay</button>
                                </div>
                            </div>
                        )}
                    </div>
                 </>
             ) : (
                 // --- EDIT MODE (Copied & Adapted from AddMedicationModal) ---
                 <div className="space-y-8 animate-in fade-in duration-300">
                     {/* 1. Basic Info */}
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Thông tin cơ bản</h4>
                        <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden">
                            <div className="p-4 border-b border-white/5 flex items-center gap-4">
                                <label className="w-24 font-medium text-zinc-300">Tên thuốc</label>
                                <input 
                                    type="text" 
                                    value={name} 
                                    onChange={e => setName(e.target.value)} 
                                    className="flex-1 bg-transparent text-right font-bold text-white placeholder:text-zinc-600 focus:outline-none"
                                />
                            </div>
                             {/* Prescription / Group Input */}
                            <div className="p-4 border-b border-white/5 flex items-center gap-4">
                                <div className="flex items-center gap-2 w-28">
                                    <FolderPlus className="w-4 h-4 text-[#00c2ff]" />
                                    <label className="font-medium text-zinc-300">Đơn thuốc</label>
                                </div>
                                <input 
                                    type="text" 
                                    value={prescriptionId} 
                                    onChange={e => setPrescriptionId(e.target.value)} 
                                    placeholder="Tên đơn thuốc" 
                                    className="flex-1 bg-transparent text-right font-bold text-white placeholder:text-zinc-600 focus:outline-none"
                                />
                            </div>
                            <div className="p-4 flex items-center justify-between" onClick={() => setActiveSubModal('color')}>
                                <label className="font-medium text-zinc-300">Giao diện</label>
                                <div className="flex items-center gap-2">
                                    <div className="w-6 h-6 rounded-full" style={{ backgroundColor: selectedColor }}></div>
                                    <ChevronRight className="w-5 h-5 text-zinc-600" />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* 2. Dosage Info */}
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Liều dùng</h4>
                        <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden">
                            <div className="p-4 border-b border-white/5 flex items-center justify-between">
                                <label className="font-medium text-zinc-300">Liều mỗi lần</label>
                                <input 
                                    type="number" 
                                    value={dosageNum} 
                                    onChange={e => setDosageNum(e.target.value)} 
                                    className="w-20 bg-transparent text-right font-bold text-white placeholder:text-zinc-600 focus:outline-none"
                                />
                            </div>
                            <div className="p-4 border-b border-white/5 flex items-center justify-between">
                                <label className="font-medium text-zinc-300">Đơn vị</label>
                                <button onClick={() => setActiveSubModal('unit')} className="flex items-center gap-1 text-[#00c2ff] font-bold">
                                    {dosageUnit} <ChevronRight className="w-4 h-4" />
                                </button>
                            </div>
                            <div className="p-4 flex items-center justify-between">
                                <label className="font-medium text-zinc-300">Cách dùng</label>
                                <div className="flex bg-black/30 rounded-lg p-1">
                                    {['Trước ăn', 'Sau ăn', 'Trong ăn'].map((opt) => (
                                    <button 
                                        key={opt}
                                        onClick={() => setDirection(opt)}
                                        className={`px-3 py-1.5 rounded-md text-xs font-bold transition-all ${direction === opt ? 'bg-[#00c2ff] text-white shadow-md' : 'text-zinc-500 hover:text-zinc-300'}`}
                                    >
                                        {opt}
                                    </button>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* 3. Schedule */}
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Lịch uống & Nhắc nhở</h4>
                        <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden space-y-[1px] bg-white/5">
                            <div className="bg-[#2c2c2e] p-4 flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <Clock className="w-5 h-5 text-orange-400" />
                                    <span className="font-medium text-zinc-300">Giờ uống</span>
                                </div>
                                <div className="flex flex-col items-end gap-2">
                                    {times.map((t, idx) => (
                                    <div key={idx} className="flex items-center gap-2">
                                        <input 
                                            type="time" 
                                            value={t} 
                                            onChange={(e) => handleTimeChange(idx, e.target.value)}
                                            className="bg-black/30 text-white font-bold rounded-lg px-2 py-1 text-sm focus:outline-none border border-transparent focus:border-[#00c2ff]"
                                        />
                                        <button onClick={() => handleRemoveTime(idx)} className="p-1 text-red-400"><Minus className="w-4 h-4" /></button>
                                    </div>
                                    ))}
                                    <button onClick={handleAddTime} className="text-xs font-bold text-[#00c2ff] flex items-center gap-1 mt-1">
                                    <Plus className="w-3 h-3" /> Thêm giờ
                                    </button>
                                </div>
                            </div>
                             {/* Start Date */}
                            <div className="bg-[#2c2c2e] p-4 flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <Calendar className="w-5 h-5 text-purple-400" />
                                    <span className="font-medium text-zinc-300">Ngày bắt đầu</span>
                                </div>
                                <input 
                                    type="date" 
                                    value={startDate}
                                    onChange={(e) => setStartDate(e.target.value)}
                                    className="bg-transparent text-white font-bold text-sm focus:outline-none text-right"
                                />
                            </div>
                            
                            {/* Duration */}
                            <div className="bg-[#2c2c2e] p-4 flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <Clock className="w-5 h-5 text-blue-400" />
                                    <span className="font-medium text-zinc-300">Thời gian</span>
                                </div>
                                <select 
                                    value={duration} 
                                    onChange={(e) => setDuration(e.target.value)}
                                    className="bg-transparent text-white font-bold text-sm focus:outline-none text-right appearance-none"
                                >
                                    <option value="7 ngày">7 ngày</option>
                                    <option value="14 ngày">14 ngày</option>
                                    <option value="30 ngày">30 ngày</option>
                                    <option value="90 ngày">90 ngày</option>
                                    <option value="Thường xuyên">Thường xuyên</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    {/* 4. Notes */}
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Ghi chú</h4>
                        <div className="bg-[#2c2c2e] rounded-2xl p-4 flex gap-3">
                            <AlignLeft className="w-5 h-5 text-zinc-500 mt-1" />
                            <textarea 
                                value={notes}
                                onChange={(e) => setNotes(e.target.value)}
                                rows={3}
                                className="w-full bg-transparent text-white text-sm font-medium placeholder:text-zinc-600 focus:outline-none resize-none"
                            />
                        </div>
                    </div>
                 </div>
             )}
         </div>

         {/* FOOTER (Only for Edit) */}
         {isEditing && (
            <div className="absolute bottom-0 left-0 right-0 p-6 bg-[#1c1c1e] border-t border-white/5 z-20">
                <button 
                onClick={handleSave}
                className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20"
                >
                Lưu thay đổi
                </button>
            </div>
         )}

         {/* SUB MODALS for Edit Mode */}
         {activeSubModal === 'color' && (
            <div className="absolute inset-0 z-[350] bg-[#1c1c1e] animate-in slide-in-from-right duration-300 flex flex-col">
                <div className="flex items-center gap-3 p-4 border-b border-white/5">
                    <button onClick={() => setActiveSubModal('none')}><ChevronLeft className="w-6 h-6 text-zinc-400" /></button>
                    <h3 className="font-bold text-white">Chọn màu sắc & Icon</h3>
                </div>
                <div className="p-6 space-y-8">
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-4">Hình dạng</h4>
                        <div className="flex gap-4">
                        {ICONS.map((item) => {
                            const Icon = item.icon;
                            return (
                            <button 
                                key={item.id} 
                                onClick={() => setSelectedIcon(item.id)}
                                className={`flex flex-col items-center gap-2 p-3 rounded-2xl border transition-all ${selectedIcon === item.id ? 'bg-[#00c2ff]/20 border-[#00c2ff]' : 'border-zinc-700 bg-zinc-800'}`}
                            >
                                <Icon className={`w-8 h-8 ${selectedIcon === item.id ? 'text-[#00c2ff]' : 'text-zinc-400'}`} />
                                <span className="text-xs font-medium text-zinc-400">{item.label}</span>
                            </button>
                            );
                        })}
                        </div>
                    </div>
                    <div>
                        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-4">Màu sắc</h4>
                        <div className="grid grid-cols-4 gap-4">
                            {COLORS.map(c => (
                            <button 
                                key={c}
                                onClick={() => setSelectedColor(c)}
                                className={`w-14 h-14 rounded-full flex items-center justify-center transition-transform active:scale-95 ${selectedColor === c ? 'ring-2 ring-white ring-offset-2 ring-offset-[#1c1c1e]' : ''}`}
                                style={{ backgroundColor: c }}
                            >
                                {selectedColor === c && <Check className="w-6 h-6 text-black/50" />}
                            </button>
                            ))}
                        </div>
                    </div>
                </div>
                <div className="mt-auto p-6">
                    <button onClick={() => setActiveSubModal('none')} className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold">Xong</button>
                </div>
            </div>
         )}
         
         {activeSubModal === 'unit' && (
            <div className="absolute inset-0 z-[350] bg-[#1c1c1e] animate-in slide-in-from-right duration-300 flex flex-col">
               <div className="flex items-center gap-3 p-4 border-b border-white/5">
                  <button onClick={() => setActiveSubModal('none')}><ChevronLeft className="w-6 h-6 text-zinc-400" /></button>
                  <h3 className="font-bold text-white">Chọn đơn vị</h3>
               </div>
               <div className="p-4 overflow-y-auto flex-1">
                   {Object.entries(DOSAGE_UNITS).map(([cat, units]) => (
                       <div key={cat} className="mb-6">
                           <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">{cat}</h4>
                           <div className="space-y-1">
                               {units.map(u => (
                                   <button 
                                     key={u} 
                                     onClick={() => { setDosageUnit(u); setActiveSubModal('none'); }}
                                     className="w-full flex items-center justify-between p-4 bg-[#2c2c2e] rounded-xl hover:bg-zinc-700 transition-colors"
                                   >
                                       <span className="text-white font-bold">{u}</span>
                                       {dosageUnit === u && <Check className="w-5 h-5 text-[#00c2ff]" />}
                                   </button>
                               ))}
                           </div>
                       </div>
                   ))}
               </div>
            </div>
         )}

      </div>
    </div>
  );
};
