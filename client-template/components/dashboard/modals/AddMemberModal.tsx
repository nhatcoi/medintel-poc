
import React, { useState } from 'react';
import { X, User, Check } from 'lucide-react';

interface AddMemberModalProps {
  onClose: () => void;
  onSave: (name: string, avatar: string) => void;
}

const AVATARS = [
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Jack',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Precious',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Sasha',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=Midnight'
];

export const AddMemberModal: React.FC<AddMemberModalProps> = ({ onClose, onSave }) => {
  const [name, setName] = useState('');
  const [selectedAvatar, setSelectedAvatar] = useState(AVATARS[0]);

  const handleSave = () => {
    if (name.trim()) {
      onSave(name, selectedAvatar);
    }
  };

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
        <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={onClose}></div>
        <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] p-8 pb-12 animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl">
            <div className="flex justify-between items-center mb-8">
                <h3 className="text-xl font-bold text-white">Thêm thành viên</h3>
                <button onClick={onClose} className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center">
                    <X className="w-5 h-5 text-zinc-400" />
                </button>
            </div>

            <div className="space-y-6">
                <div>
                    <label className="block text-zinc-500 font-bold text-xs uppercase mb-3">Tên thành viên</label>
                    <div className="bg-[#2c2c2e] rounded-2xl p-4 flex items-center gap-4 border border-white/5">
                        <User className="w-5 h-5 text-zinc-500" />
                        <input 
                            type="text" 
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            placeholder="Nhập tên..." 
                            className="bg-transparent text-white font-bold w-full focus:outline-none placeholder:text-zinc-600"
                            autoFocus
                        />
                    </div>
                </div>

                <div>
                    <label className="block text-zinc-500 font-bold text-xs uppercase mb-3">Chọn Avatar</label>
                    <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2">
                        {AVATARS.map((avatar, idx) => (
                            <button 
                                key={idx}
                                onClick={() => setSelectedAvatar(avatar)}
                                className={`relative w-16 h-16 rounded-full flex-shrink-0 overflow-hidden transition-all ${selectedAvatar === avatar ? 'ring-4 ring-[#00c2ff] scale-105' : 'opacity-50 hover:opacity-100'}`}
                            >
                                <img src={avatar} alt={`avatar-${idx}`} className="w-full h-full object-cover bg-zinc-800" />
                                {selectedAvatar === avatar && (
                                    <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                                        <Check className="w-6 h-6 text-white font-bold" />
                                    </div>
                                )}
                            </button>
                        ))}
                    </div>
                </div>

                <button 
                    onClick={handleSave}
                    disabled={!name.trim()}
                    className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20 mt-4 disabled:opacity-50 disabled:grayscale"
                >
                    Thêm thành viên
                </button>
            </div>
        </div>
    </div>
  );
};
