
import React from 'react';
import { AlertTriangle } from 'lucide-react';

interface DeleteConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title?: string;
  description?: string;
}

export const DeleteConfirmationModal: React.FC<DeleteConfirmationModalProps> = ({ 
  isOpen, 
  onClose, 
  onConfirm, 
  title = "Xóa hồ sơ?", 
  description = "Hành động này không thể hoàn tác." 
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[1100] flex items-center justify-center px-4">
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200" onClick={onClose}></div>
        <div className="relative w-full max-w-sm bg-[#1c1c1e] rounded-[2rem] p-6 shadow-2xl animate-in zoom-in-95 duration-200 border border-white/10 text-center">
            <div className="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto mb-4 border border-red-500/20">
                <AlertTriangle className="w-8 h-8 text-red-500" />
            </div>
            <h3 className="text-xl font-bold text-white mb-2">{title}</h3>
            <p className="text-zinc-400 text-sm mb-6 leading-relaxed">{description}</p>
            <div className="grid grid-cols-2 gap-3">
                <button onClick={onClose} className="py-3.5 rounded-2xl bg-zinc-800 text-white font-bold text-sm active:scale-95 transition-transform hover:bg-zinc-700">Hủy</button>
                <button onClick={onConfirm} className="py-3.5 rounded-2xl bg-red-500 text-white font-bold text-sm active:scale-95 transition-transform shadow-lg shadow-red-500/20 hover:bg-red-600">Xóa ngay</button>
            </div>
        </div>
    </div>
  );
};
