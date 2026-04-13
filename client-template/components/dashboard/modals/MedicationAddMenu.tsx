
import React from 'react';
import { Pill, Camera, X, Sparkles } from 'lucide-react';

interface MedicationAddMenuProps {
  isOpen: boolean;
  onClose: () => void;
  onAddManually: () => void;
  onScan: () => void;
  onSmartInput: () => void; // New Prop
}

export const MedicationAddMenu: React.FC<MedicationAddMenuProps> = ({ 
  isOpen, 
  onClose, 
  onAddManually, 
  onScan,
  onSmartInput
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center px-4">
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200" onClick={onClose}></div>
        <div className="relative w-full max-w-xs bg-[#1c1c1e] rounded-[2rem] p-6 shadow-2xl animate-in zoom-in-95 duration-200 border border-white/10">
            <div className="flex justify-between items-center mb-6 px-2">
                 <h3 className="text-lg font-bold text-white">Thêm thuốc mới</h3>
                 <button onClick={onClose} className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center hover:bg-zinc-700 transition-colors">
                     <X className="w-5 h-5 text-zinc-400" />
                 </button>
            </div>
            
            <div className="space-y-3">
                 <button onClick={onSmartInput} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-gradient-to-r from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 active:scale-95 transition-all text-left group hover:bg-zinc-800">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center group-active:scale-95 transition-transform shadow-lg shadow-purple-500/20">
                        <Sparkles className="w-6 h-6 text-white" />
                    </div>
                    <div>
                        <h4 className="font-bold text-white text-sm">Nhập thông minh AI</h4>
                        <p className="text-[10px] text-zinc-400 font-medium">Nhập hoặc dán lời dặn bác sĩ</p>
                    </div>
                 </button>

                 <button onClick={onAddManually} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-[#00c2ff]/10 active:border-[#00c2ff]/30 transition-all text-left group hover:bg-zinc-800">
                    <div className="w-12 h-12 rounded-xl bg-[#00c2ff]/20 flex items-center justify-center group-active:scale-95 transition-transform">
                        <Pill className="w-6 h-6 text-[#00c2ff]" />
                    </div>
                    <div>
                        <h4 className="font-bold text-white text-sm">Thêm thủ công</h4>
                        <p className="text-[10px] text-zinc-500 font-medium">Nhập tên và liều lượng</p>
                    </div>
                 </button>

                 <button onClick={onScan} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800/50 border border-white/5 active:bg-purple-500/10 active:border-purple-500/30 transition-all text-left group hover:bg-zinc-800">
                    <div className="w-12 h-12 rounded-xl bg-purple-500/20 flex items-center justify-center group-active:scale-95 transition-transform">
                        <Camera className="w-6 h-6 text-purple-400" />
                    </div>
                    <div>
                        <h4 className="font-bold text-white text-sm">Trích xuất từ hóa đơn</h4>
                        <p className="text-[10px] text-zinc-500 font-medium">Quét bằng AI Camera</p>
                    </div>
                 </button>
            </div>
        </div>
    </div>
  );
};
