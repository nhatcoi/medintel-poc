
import React, { useState, useEffect } from 'react';
import { X, Check, Clock, Minus, Plus, Trash2, ChevronRight } from 'lucide-react';
import { HealthHabit, HabitCategory } from '../../../types';
import { HABIT_CATEGORIES_CONFIG, COLOR_PALETTE, HABIT_ICONS_MAP } from '../../../constants';

interface AddHabitModalProps {
  onClose: () => void;
  onSave: (habit: HealthHabit) => void;
  initialData?: HealthHabit | null;
  onDelete?: (id: string) => void;
}

export const AddHabitModal: React.FC<AddHabitModalProps> = ({ onClose, onSave, initialData, onDelete }) => {
  // State
  const [name, setName] = useState('');
  const [category, setCategory] = useState<HabitCategory>('nutrition');
  const [targetValue, setTargetValue] = useState<string>('');
  const [unit, setUnit] = useState('');
  const [times, setTimes] = useState<string[]>([]);
  const [selectedColor, setSelectedColor] = useState(COLOR_PALETTE[4].hex); 
  const [selectedIconKey, setSelectedIconKey] = useState<string>('apple');
  
  // UI State
  const [isDeleteConfirm, setIsDeleteConfirm] = useState(false);
  const [isIconPickerOpen, setIsIconPickerOpen] = useState(false);

  // Initialize
  useEffect(() => {
    if (initialData) {
        setName(initialData.name);
        setCategory(initialData.category);
        setTargetValue(initialData.targetValue.toString());
        setUnit(initialData.unit);
        setTimes(initialData.reminders || []);
        setSelectedColor(initialData.color || COLOR_PALETTE[4].hex);
        setSelectedIconKey(initialData.icon || HABIT_CATEGORIES_CONFIG[initialData.category].defaultIconKey);
    }
  }, [initialData]);

  // Handlers
  const handleCategoryChange = (cat: HabitCategory) => {
    setCategory(cat);
    const config = HABIT_CATEGORIES_CONFIG[cat];
    setSelectedIconKey(config.defaultIconKey);
    
    // Find color object that matches the tailwind class in config to get Hex, or default to teal
    const colorObj = COLOR_PALETTE.find(c => config.color.includes(c.class.replace('text-', '').split('-')[0]));
    setSelectedColor(colorObj ? colorObj.hex : '#22d3ee');

    if (!initialData) {
        // Presets
        switch (cat) {
            case 'nutrition': setName('Uống nước'); setTargetValue('2000'); setUnit('ml'); break;
            case 'movement': setName('Đi bộ'); setTargetValue('5000'); setUnit('bước'); break;
            case 'sleep': setName('Ngủ đủ giấc'); setTargetValue('8'); setUnit('giờ'); break;
            case 'mind': setName('Thiền'); setTargetValue('15'); setUnit('phút'); break;
            case 'hygiene': setName('Đánh răng'); setTargetValue('2'); setUnit('lần'); break;
            case 'learning': setName('Đọc sách'); setTargetValue('30'); setUnit('phút'); break;
            case 'custom': setName(''); setTargetValue(''); setUnit(''); break;
            default: break;
        }
    }
  };

  const handleSave = () => {
    if (!name.trim() || !targetValue) return;

    const newHabit: HealthHabit = {
        id: initialData ? initialData.id : Date.now().toString(),
        memberId: initialData ? initialData.memberId : 'me', 
        name,
        category,
        targetValue: parseFloat(targetValue),
        unit,
        frequency: 'daily',
        reminders: times.sort(),
        color: selectedColor,
        icon: selectedIconKey
    };
    onSave(newHabit);
  };

  // Render Helpers
  const renderCategorySelection = () => (
    <div>
        <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Danh mục</h4>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {(Object.keys(HABIT_CATEGORIES_CONFIG) as HabitCategory[])
                .filter(c => c !== 'medication')
                .map(cat => {
                    const config = HABIT_CATEGORIES_CONFIG[cat];
                    const Icon = config.icon;
                    const isSelected = category === cat;
                    return (
                        <button 
                            key={cat}
                            onClick={() => handleCategoryChange(cat)}
                            className={`flex flex-col items-center justify-center p-3 rounded-2xl border transition-all h-24 ${isSelected ? 'bg-white/10 border-white/20' : 'bg-zinc-800/50 border-zinc-700 hover:bg-zinc-800'}`}
                        >
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center mb-2 ${isSelected ? config.bg : 'bg-zinc-700'}`}>
                                <Icon className={`w-4 h-4 ${isSelected ? config.color : 'text-zinc-400'}`} />
                            </div>
                            <span className={`text-xs font-bold ${isSelected ? 'text-white' : 'text-zinc-400'}`}>{config.label}</span>
                        </button>
                    );
            })}
        </div>
    </div>
  );

  const renderBasicInfo = () => {
      const SelectedIcon = HABIT_ICONS_MAP[selectedIconKey] || HABIT_ICONS_MAP['sparkles'];
      return (
        <div>
            <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Chi tiết</h4>
            <div className="bg-[#2c2c2e] rounded-2xl overflow-hidden">
                <div className="p-4 border-b border-white/5 flex items-center gap-4">
                    <button 
                        onClick={() => setIsIconPickerOpen(true)}
                        className="w-10 h-10 rounded-xl bg-zinc-800 flex items-center justify-center flex-shrink-0 hover:bg-zinc-700 transition-colors"
                        style={{ backgroundColor: `${selectedColor}20` }}
                    >
                        <SelectedIcon className="w-5 h-5" style={{ color: selectedColor }} />
                    </button>
                    <div className="flex-1">
                        <label className="text-[10px] font-bold text-zinc-500 uppercase">Tên thói quen</label>
                        <input 
                            type="text" 
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            placeholder="Ví dụ: Tập Yoga"
                            className="w-full bg-transparent font-bold text-white placeholder:text-zinc-600 focus:outline-none text-base"
                        />
                    </div>
                </div>
                <div className="p-4 flex items-center gap-4">
                    <div className="flex-1">
                        <label className="text-[10px] font-bold text-zinc-500 uppercase">Mục tiêu hàng ngày</label>
                        <div className="flex items-baseline gap-2">
                             <input 
                                 type="number" 
                                 value={targetValue}
                                 onChange={(e) => setTargetValue(e.target.value)}
                                 placeholder="0"
                                 className="w-20 bg-transparent font-black text-2xl text-white placeholder:text-zinc-700 focus:outline-none"
                             />
                             <input 
                                 type="text" 
                                 value={unit}
                                 onChange={(e) => setUnit(e.target.value)}
                                 placeholder="đơn vị"
                                 className="flex-1 bg-transparent font-bold text-zinc-400 placeholder:text-zinc-700 focus:outline-none"
                             />
                        </div>
                    </div>
                </div>
            </div>
        </div>
      );
  };

  const renderIconPicker = () => (
      <div className="absolute inset-0 z-[350] bg-[#1c1c1e] animate-in slide-in-from-right duration-300 flex flex-col">
          <div className="flex items-center gap-3 p-4 border-b border-white/5">
               <button onClick={() => setIsIconPickerOpen(false)} className="p-2 -ml-2"><ChevronRight className="w-6 h-6 text-zinc-400 rotate-180" /></button>
               <h3 className="font-bold text-white">Chọn biểu tượng</h3>
          </div>
          <div className="p-4 overflow-y-auto flex-1">
               <div className="grid grid-cols-5 gap-4">
                   {Object.entries(HABIT_ICONS_MAP).map(([key, Icon]) => (
                       <button
                           key={key}
                           onClick={() => { setSelectedIconKey(key); setIsIconPickerOpen(false); }}
                           className={`aspect-square rounded-2xl flex items-center justify-center border transition-all ${selectedIconKey === key ? 'bg-white/10 border-white text-white' : 'bg-zinc-800 border-transparent text-zinc-500'}`}
                       >
                           <Icon className="w-6 h-6" />
                       </button>
                   ))}
               </div>
          </div>
      </div>
  );

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
        <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={onClose}></div>
        <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
            
            {/* Header */}
            <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#1c1c1e] z-10">
                <h3 className="text-lg font-bold text-white mx-auto">{initialData ? 'Sửa thói quen' : 'Thêm thói quen'}</h3>
                <button onClick={onClose} className="absolute right-6 w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                    <X className="w-5 h-5 text-zinc-400" />
                </button>
            </div>

            <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-24 space-y-8 relative">
                {renderCategorySelection()}
                {renderBasicInfo()}

                {/* Reminders */}
                <div>
                   <div className="flex items-center justify-between mb-3">
                       <h4 className="text-zinc-500 text-xs font-bold uppercase">Nhắc nhở</h4>
                       <button onClick={() => setTimes([...times, '08:00'])} className="text-xs font-bold text-[#00c2ff] flex items-center gap-1">
                           <Plus className="w-3 h-3" /> Thêm giờ
                       </button>
                   </div>
                   {times.length > 0 ? (
                       <div className="bg-[#2c2c2e] rounded-2xl p-2 space-y-1">
                           {times.map((t, idx) => (
                               <div key={idx} className="flex items-center justify-between p-3 bg-zinc-800/50 rounded-xl">
                                   <div className="flex items-center gap-3">
                                       <Clock className="w-4 h-4 text-zinc-400" />
                                       <input 
                                            type="time" 
                                            value={t}
                                            onChange={(e) => {
                                                const newTimes = [...times];
                                                newTimes[idx] = e.target.value;
                                                setTimes(newTimes);
                                            }}
                                            className="bg-transparent text-white font-bold focus:outline-none"
                                       />
                                   </div>
                                   <button onClick={() => setTimes(times.filter((_, i) => i !== idx))} className="p-1 text-zinc-500 hover:text-red-400">
                                       <Minus className="w-4 h-4" />
                                   </button>
                               </div>
                           ))}
                       </div>
                   ) : (
                       <div className="bg-[#2c2c2e] rounded-2xl p-4 text-center text-zinc-500 text-sm font-medium border border-white/5">
                           Không có nhắc nhở
                       </div>
                   )}
                </div>

                {/* Color */}
                <div>
                     <h4 className="text-zinc-500 text-xs font-bold uppercase mb-3">Màu sắc</h4>
                     <div className="grid grid-cols-6 gap-3">
                        {COLOR_PALETTE.map(c => (
                        <button 
                            key={c.name}
                            onClick={() => setSelectedColor(c.hex)}
                            className={`w-10 h-10 rounded-full flex items-center justify-center transition-transform active:scale-95 ${selectedColor === c.hex ? 'ring-2 ring-white ring-offset-2 ring-offset-[#1c1c1e]' : ''}`}
                            style={{ backgroundColor: c.hex }}
                        >
                            {selectedColor === c.hex && <Check className="w-4 h-4 text-black/50" />}
                        </button>
                        ))}
                    </div>
                </div>

                {/* Delete Section */}
                {initialData && onDelete && (
                    <div className="pt-4 border-t border-white/5">
                         {!isDeleteConfirm ? (
                            <button onClick={() => setIsDeleteConfirm(true)} className="w-full py-4 rounded-2xl bg-red-500/10 text-red-500 font-bold text-sm flex items-center justify-center gap-2">
                                <Trash2 className="w-5 h-5" /> Xóa thói quen này
                            </button>
                         ) : (
                             <div className="flex gap-3">
                                <button onClick={() => setIsDeleteConfirm(false)} className="flex-1 py-4 rounded-2xl bg-zinc-800 text-white font-bold">Hủy</button>
                                <button onClick={() => { onDelete(initialData.id); onClose(); }} className="flex-1 py-4 rounded-2xl bg-red-500 text-white font-bold shadow-lg shadow-red-500/20">Xác nhận xóa</button>
                             </div>
                         )}
                    </div>
                )}
            </div>

            <div className="absolute bottom-0 left-0 right-0 p-6 bg-[#1c1c1e] border-t border-white/5 z-20">
                <button 
                    onClick={handleSave}
                    className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20"
                >
                    {initialData ? 'Lưu thay đổi' : 'Tạo thói quen'}
                </button>
            </div>

            {/* Sub Modals */}
            {isIconPickerOpen && renderIconPicker()}
        </div>
    </div>
  );
};
