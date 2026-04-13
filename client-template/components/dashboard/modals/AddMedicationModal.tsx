
import React, { useState, useEffect } from 'react';
import { X, ChevronRight, Plus, Minus, Pill, Droplets, Syringe, Tablet, Clock, Calendar, Bell, AlignLeft, Check, ChevronLeft, FolderPlus, Search } from 'lucide-react';
import { ExtendedMedication } from '../../../types';
import { DOSAGE_UNITS } from '../../../constants';

interface AddMedicationModalProps {
  onClose: () => void;
  onAdd: (med: ExtendedMedication) => void;
  existingPrescriptions?: string[];
  cabinetMedications?: ExtendedMedication[]; // List of existing meds for auto-complete
}

const COLORS = ['#00c2ff', '#f87171', '#fb923c', '#facc15', '#34d399', '#818cf8', '#c084fc', '#f472b6'];
const ICONS = [
  { id: 'pill', icon: Pill, label: 'Viên' },
  { id: 'tablet', icon: Tablet, label: 'Nén' },
  { id: 'syrup', icon: Droplets, label: 'Siro' },
  { id: 'injection', icon: Syringe, label: 'Tiêm' },
];

export const AddMedicationModal: React.FC<AddMedicationModalProps> = ({ onClose, onAdd, existingPrescriptions = [], cabinetMedications = [] }) => {
  // --- FORM STATE ---
  const [name, setName] = useState('');
  const [prescriptionId, setPrescriptionId] = useState('');
  
  // Appearance
  const [selectedColor, setSelectedColor] = useState(COLORS[0]);
  const [selectedIcon, setSelectedIcon] = useState(ICONS[0].id);

  // Dosage
  const [dosageNum, setDosageNum] = useState('');
  const [dosageUnit, setDosageUnit] = useState('viên');
  const [direction, setDirection] = useState('Sau ăn'); // Before, After, With meal

  // Schedule
  const [enableSchedule, setEnableSchedule] = useState(true); // NEW: Toggle for schedule
  const [frequencyType, setFrequencyType] = useState<'daily' | 'interval'>('daily');
  const [interval, setInterval] = useState(1); // Every X days
  const [times, setTimes] = useState<string[]>(['08:00']);
  const [duration, setDuration] = useState('30 ngày');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  
  // Advanced
  const [reminderEnabled, setReminderEnabled] = useState(true);
  const [notes, setNotes] = useState('');

  // --- SUB-MODAL STATES ---
  const [activeSubModal, setActiveSubModal] = useState<'none' | 'color' | 'unit' | 'schedule'>('none');
  const [showSuggestions, setShowSuggestions] = useState(false);

  // Filter unique existing medications for suggestions
  const uniqueCabinetMeds = React.useMemo(() => {
      const map = new Map();
      cabinetMedications.forEach(m => {
          if (!map.has(m.name)) map.set(m.name, m);
      });
      return Array.from(map.values());
  }, [cabinetMedications]);

  const filteredSuggestions = uniqueCabinetMeds.filter(m => 
     m.name.toLowerCase().includes(name.toLowerCase()) && name.trim() !== ''
  );

  // --- HANDLERS ---
  const handleSelectExisting = (med: ExtendedMedication) => {
      setName(med.name);
      setPrescriptionId(med.prescriptionId || '');
      setSelectedColor(med.color || COLORS[0]);
      setSelectedIcon(med.icon || ICONS[0].id);
      
      // Parse Dosage
      const match = med.dosage.match(/^[\d.]+/);
      const num = match ? match[0] : '';
      const unit = med.dosageUnit || med.dosage.replace(num, '').trim();
      
      setDosageNum(num);
      setDosageUnit(unit || 'viên');
      setDirection(med.direction || 'Sau ăn');
      
      setShowSuggestions(false);
  };

  const handleAddTime = () => setTimes([...times, '12:00']);
  const handleRemoveTime = (idx: number) => setTimes(times.filter((_, i) => i !== idx));
  const handleTimeChange = (idx: number, val: string) => {
    const newTimes = [...times];
    newTimes[idx] = val;
    setTimes(newTimes);
  };

  const handleSave = () => {
    if (!name.trim()) return;

    const finalMed: ExtendedMedication = {
      name,
      prescriptionId: prescriptionId.trim(),
      dosage: `${dosageNum} ${dosageUnit}`.trim(),
      dosageUnit,
      // If schedule is disabled, clear schedule related fields
      frequency: enableSchedule ? (frequencyType === 'daily' ? 'Mỗi ngày' : `Mỗi ${interval} ngày`) : 'Khi cần',
      frequencyType: enableSchedule ? frequencyType : undefined,
      interval: enableSchedule && frequencyType === 'interval' ? interval : undefined,
      timeOfDay: enableSchedule ? times.sort() : [],
      expectedDuration: enableSchedule ? duration : '',
      startDate: enableSchedule ? startDate : undefined,
      direction,
      color: selectedColor,
      icon: selectedIcon,
      reminder: enableSchedule ? reminderEnabled : false,
      notes,
      taken: false
    };

    onAdd(finalMed);
  };

  // --- SUB-COMPONENTS (Simplified for inline) ---
  
  const renderColorPicker = () => (
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
  );

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={onClose}></div>
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
         
         {/* HEADER */}
         <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#1c1c1e] z-10">
            <h3 className="text-lg font-bold text-white mx-auto">Thêm thuốc</h3>
            <button onClick={onClose} className="absolute right-6 w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
              <X className="w-5 h-5 text-zinc-400" />
            </button>
         </div>
         
         {/* SCROLLABLE CONTENT */}
         <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-24 space-y-8">
            
            {/* 1. Basic Info */}
            <div>
               <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Thông tin cơ bản</h4>
               <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden relative">
                  <div className="p-4 border-b border-white/5 flex items-center gap-4 relative">
                     <label className="w-24 font-medium text-zinc-300">Tên thuốc</label>
                     <div className="flex-1 relative">
                        <input 
                            type="text" 
                            value={name} 
                            onChange={e => { setName(e.target.value); setShowSuggestions(true); }}
                            onFocus={() => setShowSuggestions(true)}
                            onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
                            placeholder="Ví dụ: Panadol" 
                            className="w-full bg-transparent text-right font-bold text-white placeholder:text-zinc-600 focus:outline-none"
                        />
                        {/* Auto-complete Suggestions */}
                        {showSuggestions && uniqueCabinetMeds.length > 0 && (
                            <div className="absolute top-full right-0 mt-2 w-[120%] bg-[#1c1c1e] border border-white/10 rounded-xl shadow-2xl z-50 overflow-hidden max-h-48 overflow-y-auto">
                                <div className="px-3 py-2 text-[10px] text-zinc-500 font-bold uppercase bg-zinc-800/50">Gợi ý từ tủ thuốc</div>
                                {filteredSuggestions.length > 0 ? (
                                    filteredSuggestions.map((med, i) => (
                                        <button 
                                            key={i} 
                                            onMouseDown={() => handleSelectExisting(med)}
                                            className="w-full flex items-center gap-3 p-3 hover:bg-zinc-800 transition-colors border-b border-white/5 last:border-0"
                                        >
                                            <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${med.color}20` }}>
                                                {React.createElement(ICONS.find(ic => ic.id === med.icon)?.icon || Pill, { className: "w-4 h-4", style: { color: med.color } })}
                                            </div>
                                            <div className="text-left">
                                                <div className="text-sm font-bold text-white">{med.name}</div>
                                                <div className="text-xs text-zinc-500">{med.dosage}</div>
                                            </div>
                                        </button>
                                    ))
                                ) : (
                                    uniqueCabinetMeds.map((med, i) => (
                                        <button 
                                            key={i} 
                                            onMouseDown={() => handleSelectExisting(med)}
                                            className="w-full flex items-center gap-3 p-3 hover:bg-zinc-800 transition-colors border-b border-white/5 last:border-0"
                                        >
                                            <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${med.color}20` }}>
                                                {React.createElement(ICONS.find(ic => ic.id === med.icon)?.icon || Pill, { className: "w-4 h-4", style: { color: med.color } })}
                                            </div>
                                            <div className="text-left">
                                                <div className="text-sm font-bold text-white">{med.name}</div>
                                                <div className="text-xs text-zinc-500">{med.dosage}</div>
                                            </div>
                                        </button>
                                    ))
                                )}
                            </div>
                        )}
                     </div>
                  </div>
                   {/* Prescription / Group Input */}
                   <div className="p-4 border-b border-white/5 flex flex-col gap-2">
                     <div className="flex items-center gap-4">
                         <div className="flex items-center gap-2 w-28">
                             <FolderPlus className="w-4 h-4 text-[#00c2ff]" />
                             <label className="font-medium text-zinc-300">Đơn thuốc</label>
                         </div>
                         <input 
                            type="text" 
                            value={prescriptionId} 
                            onChange={e => setPrescriptionId(e.target.value)} 
                            placeholder="Nhập tên đơn (Tùy chọn)" 
                            className="flex-1 bg-transparent text-right font-bold text-white placeholder:text-zinc-600 focus:outline-none"
                         />
                     </div>
                     
                     {/* Suggestion Chips */}
                     {existingPrescriptions.length > 0 && (
                        <div className="flex gap-2 overflow-x-auto no-scrollbar mt-2 px-1 pb-1">
                          {existingPrescriptions.map(p => (
                            <button 
                              key={p} 
                              onClick={() => setPrescriptionId(p)}
                              className={`px-3 py-1.5 rounded-lg text-[10px] font-bold border whitespace-nowrap transition-colors flex-shrink-0 ${prescriptionId === p ? 'bg-[#00c2ff]/20 text-[#00c2ff] border-[#00c2ff]' : 'bg-zinc-800 text-zinc-400 border-zinc-700 hover:bg-zinc-700'}`}
                            >
                              {p}
                            </button>
                          ))}
                        </div>
                     )}
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
                        placeholder="0" 
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

            {/* 3. Schedule & Reminders */}
            <div>
               <div className="flex items-center justify-between mb-3">
                   <h4 className="text-zinc-500 text-xs font-bold uppercase">Lịch uống & Nhắc nhở</h4>
                   {/* MASTER TOGGLE */}
                   <button 
                        onClick={() => setEnableSchedule(!enableSchedule)}
                        className={`w-10 h-6 rounded-full p-1 transition-colors duration-300 ${enableSchedule ? 'bg-[#00c2ff]' : 'bg-zinc-700'}`}
                   >
                        <div className={`w-4 h-4 bg-white rounded-full shadow-md transform transition-transform duration-300 ${enableSchedule ? 'translate-x-4' : 'translate-x-0'}`} />
                   </button>
               </div>
               
               {enableSchedule ? (
                   <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden space-y-[1px] bg-white/5 animate-in fade-in slide-in-from-top-2 duration-300">
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
                                  {times.length > 1 && (
                                    <button onClick={() => handleRemoveTime(idx)} className="p-1 text-red-400"><Minus className="w-4 h-4" /></button>
                                  )}
                               </div>
                            ))}
                            <button onClick={handleAddTime} className="text-xs font-bold text-[#00c2ff] flex items-center gap-1 mt-1">
                               <Plus className="w-3 h-3" /> Thêm giờ
                            </button>
                         </div>
                      </div>

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

                      <div className="bg-[#2c2c2e] p-4 flex items-center justify-between">
                         <div className="flex items-center gap-3">
                            <Clock className="w-5 h-5 text-blue-400" />
                            <span className="font-medium text-zinc-300">Thời gian điều trị</span>
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

                      <div className="bg-[#2c2c2e] p-4 flex items-center justify-between">
                         <div className="flex items-center gap-3">
                            <Bell className="w-5 h-5 text-emerald-400" />
                            <span className="font-medium text-zinc-300">Nhắc nhở</span>
                         </div>
                         <button 
                            onClick={() => setReminderEnabled(!reminderEnabled)}
                            className={`w-12 h-7 rounded-full p-1 transition-colors duration-300 ${reminderEnabled ? 'bg-[#00c2ff]' : 'bg-zinc-600'}`}
                         >
                            <div className={`w-5 h-5 bg-white rounded-full shadow-md transform transition-transform duration-300 ${reminderEnabled ? 'translate-x-5' : 'translate-x-0'}`} />
                         </button>
                      </div>
                   </div>
               ) : (
                   <div className="bg-[#2c2c2e] rounded-2xl p-4 text-center border border-white/5">
                       <p className="text-zinc-500 text-sm font-medium">Đã tắt lịch uống & nhắc nhở</p>
                       <p className="text-[10px] text-zinc-600 mt-1">Thuốc này sẽ chỉ hiển thị trong tủ thuốc (Khi cần)</p>
                   </div>
               )}
            </div>

            {/* 4. Notes */}
            <div>
               <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Ghi chú</h4>
               <div className="bg-[#2c2c2e] rounded-2xl p-4 flex gap-3">
                  <AlignLeft className="w-5 h-5 text-zinc-500 mt-1" />
                  <textarea 
                     value={notes}
                     onChange={(e) => setNotes(e.target.value)}
                     placeholder="Ví dụ: Nên uống nhiều nước..."
                     rows={3}
                     className="w-full bg-transparent text-white text-sm font-medium placeholder:text-zinc-600 focus:outline-none resize-none"
                  />
               </div>
            </div>

         </div>

         {/* FOOTER */}
         <div className="absolute bottom-0 left-0 right-0 p-6 bg-[#1c1c1e] border-t border-white/5 z-20">
            <button 
               onClick={handleSave}
               className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20"
            >
               Lưu thuốc
            </button>
         </div>

         {/* --- SUB MODALS OVERLAYS --- */}
         
         {activeSubModal === 'color' && renderColorPicker()}
         
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
