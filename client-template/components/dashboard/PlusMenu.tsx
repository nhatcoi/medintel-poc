
import React from 'react';
import { Pill, Activity, Camera, ChevronRight, AlarmClock, Search } from 'lucide-react';

interface PlusMenuProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenAddMed: () => void;
  onOpenTrackers: () => void;
  onOpenDrugLookup: () => void; // New Prop
}

export const PlusMenu: React.FC<PlusMenuProps> = ({ isOpen, onClose, onOpenAddMed, onOpenTrackers, onOpenDrugLookup }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[150] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/40 pointer-events-auto" onClick={onClose}></div>
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] p-8 pb-12 animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-[0_-20px_40px_rgba(0,0,0,0.5)]">
        <div className="w-12 h-1.5 bg-zinc-700 rounded-full mx-auto mb-8"></div>
        <h3 className="text-xl font-bold text-white mb-6 px-2">Thêm mới & Tra cứu</h3>
        <div className="grid grid-cols-1 gap-4">
          <button onClick={() => { onOpenAddMed(); onClose(); }} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-[#00c2ff]/10 active:border-[#00c2ff]/30 transition-all text-left">
            <div className="w-12 h-12 rounded-xl bg-[#00c2ff]/20 flex items-center justify-center"><Pill className="w-6 h-6 text-[#00c2ff]" /></div>
            <div><h4 className="font-bold text-white">Thêm thuốc</h4><p className="text-xs text-zinc-500">Thêm thuốc mới vào tủ</p></div>
            <ChevronRight className="ml-auto w-5 h-5 text-zinc-600" />
          </button>
          
          <button onClick={() => { onOpenDrugLookup(); onClose(); }} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-[#00c2ff]/10 active:border-[#00c2ff]/30 transition-all text-left">
            <div className="w-12 h-12 rounded-xl bg-purple-500/20 flex items-center justify-center"><Search className="w-6 h-6 text-purple-400" /></div>
            <div><h4 className="font-bold text-white">Tra cứu thuốc</h4><p className="text-xs text-zinc-500">Thông tin, liều dùng, tác dụng phụ</p></div>
            <ChevronRight className="ml-auto w-5 h-5 text-zinc-600" />
          </button>

          <button onClick={() => { onOpenTrackers(); onClose(); }} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-[#00c2ff]/10 active:border-[#00c2ff]/30 transition-all text-left">
            <div className="w-12 h-12 rounded-xl bg-orange-500/20 flex items-center justify-center"><Activity className="w-6 h-6 text-orange-400" /></div>
            <div><h4 className="font-bold text-white">Chỉ số sức khỏe</h4><p className="text-xs text-zinc-500">Cân nặng, Huyết áp...</p></div>
            <ChevronRight className="ml-auto w-5 h-5 text-zinc-600" />
          </button>
          
          <button className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-[#00c2ff]/10 active:border-[#00c2ff]/30 transition-all text-left opacity-70">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/20 flex items-center justify-center"><Camera className="w-6 h-6 text-emerald-400" /></div>
            <div><h4 className="font-bold text-white">Trích xuất từ hóa đơn</h4><p className="text-xs text-zinc-500">Quét bằng AI (Camera)</p></div>
            <ChevronRight className="ml-auto w-5 h-5 text-zinc-600" />
          </button>
        </div>
        <button onClick={onClose} className="mt-8 w-full py-4 rounded-2xl bg-zinc-800 text-white font-bold active:scale-95 transition-all">Hủy bỏ</button>
      </div>
    </div>
  );
};
