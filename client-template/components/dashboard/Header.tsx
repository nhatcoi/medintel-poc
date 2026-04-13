
import React from 'react';
import { Plus } from 'lucide-react';
import { Member } from '../../types';

interface HeaderProps {
  activeMember: Member;
  setActiveTab: (tab: any) => void;
  setIsPlusMenuOpen: (isOpen: boolean) => void;
  isBlurred: boolean;
}

export const Header: React.FC<HeaderProps> = ({ activeMember, setActiveTab, setIsPlusMenuOpen, isBlurred }) => {
  return (
    <header className={`bg-[#142d3e] pt-16 pb-5 relative z-10 flex-none px-6 flex justify-between items-center shadow-lg shadow-black/20 transition-all duration-300 ${isBlurred ? 'blur-sm opacity-50' : ''}`}>
        <button onClick={() => setActiveTab('profile')} className="flex items-center gap-3 active:opacity-60 transition-all hover:translate-x-1">
          <div className="w-10 h-10 bg-[#34495e] rounded-full flex items-center justify-center overflow-hidden border-2 border-[#455a64] shadow-md">
            <img src={activeMember.avatar} alt="active profile" className="w-full h-full object-cover" />
          </div>
          <div className="text-left">
            <p className="text-slate-400 text-[9px] font-black uppercase tracking-widest leading-none mb-1">Xin chào</p>
            <p className="text-white font-bold text-sm tracking-tight leading-none">{activeMember.name}</p>
          </div>
        </button>
        <button onClick={() => setIsPlusMenuOpen(true)} className="text-[#00c2ff] active:opacity-50 transition-opacity hover:scale-110 p-1">
          <Plus className="w-7 h-7" strokeWidth={3} />
        </button>
    </header>
  );
};
