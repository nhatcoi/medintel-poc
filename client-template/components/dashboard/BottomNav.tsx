
import React from 'react';
import { Clock, Pill, LayoutGrid, ClipboardList, User } from 'lucide-react';

interface BottomNavProps {
  activeTab: string;
  setActiveTab: (tab: any) => void;
  isBlurred: boolean;
}

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, setActiveTab, isBlurred }) => {
  const items = [
    { id: 'timeline', icon: Clock },
    { id: 'meds', icon: Pill },
    { id: 'trackers', icon: LayoutGrid },
    { id: 'files', icon: ClipboardList },
    { id: 'profile', icon: User }
  ];

  return (
    <nav className={`absolute bottom-0 left-0 right-0 bg-black/90 backdrop-blur-xl border-t border-white/[0.05] px-6 py-4 flex justify-between items-center z-20 pb-6 transition-all duration-300 ${isBlurred ? 'blur-sm opacity-50 pointer-events-none' : ''}`}>
      {items.map((item) => (
        <button key={item.id} onClick={() => setActiveTab(item.id)} className={`p-2 rounded-xl transition-all duration-300 ${activeTab === item.id ? 'bg-[#00c2ff]/10 text-[#00c2ff] scale-110' : 'text-slate-600 hover:text-slate-400'}`}>
          <item.icon className="w-6 h-6" strokeWidth={activeTab === item.id ? 2.5 : 2} />
        </button>
      ))}
    </nav>
  );
};
