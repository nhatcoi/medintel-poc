
import React from 'react';
import { ScrollText, FileText, ChevronRight, Plus, Image as ImageIcon } from 'lucide-react';
import { DOSSIER_TYPES } from '../../../constants';
import { Dossier } from '../../../types';

interface DossiersTabProps {
  dossiers: Dossier[];
  setViewingDossier: (dossier: Dossier) => void;
  setIsEditingDossier: (isEditing: boolean) => void;
  setIsAddDossierOpen: (isOpen: boolean) => void;
  resetDossierForm: () => void;
}

export const DossiersTab: React.FC<DossiersTabProps> = ({ 
  dossiers, 
  setViewingDossier, 
  setIsEditingDossier,
  setIsAddDossierOpen,
  resetDossierForm
}) => {
  return (
    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 pb-20">
      <h3 className="text-2xl font-black text-white tracking-tight mb-6">Hồ sơ & Diễn biến</h3>
      <div className="space-y-4">
        {dossiers.length === 0 ? (
           <div className="flex flex-col items-center justify-center py-12 text-zinc-600">
              <ScrollText className="w-16 h-16 mb-4 opacity-20" />
              <p className="text-sm font-bold">Chưa có hồ sơ nào</p>
              <p className="text-xs mt-1 opacity-50">Nhấn "Thêm mới" để tạo hồ sơ bệnh án</p>
           </div>
        ) : (
             dossiers.map((file, idx) => (
                <button 
                    key={idx} 
                    onClick={() => { setViewingDossier(file); setIsEditingDossier(false); }}
                    className="w-full bg-[#1c1c1e] p-4 rounded-2xl flex items-center gap-4 border border-white/5 hover:bg-zinc-800/50 transition-colors cursor-pointer text-left"
                >
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-black ${DOSSIER_TYPES[file.type as keyof typeof DOSSIER_TYPES]?.bg || 'bg-zinc-800'}`}>
                        {(() => {
                            const Icon = DOSSIER_TYPES[file.type as keyof typeof DOSSIER_TYPES]?.icon || FileText;
                            return <Icon className={`w-5 h-5 ${DOSSIER_TYPES[file.type as keyof typeof DOSSIER_TYPES]?.color || 'text-zinc-500'}`} />;
                        })()}
                    </div>
                    <div className="flex-1">
                        <h4 className="font-bold text-white text-sm">{file.title}</h4>
                        <p className="text-xs text-zinc-500 mt-1">{file.date} • {file.type === 'Progression' ? 'Diễn biến' : file.type === 'Rx' ? 'Đơn thuốc' : 'Hồ sơ'}</p>
                    </div>
                    {file.images && file.images.length > 0 && (
                        <div className="flex -space-x-2">
                             <div className="w-8 h-8 rounded-full bg-zinc-800 border-2 border-[#1c1c1e] flex items-center justify-center">
                                 <ImageIcon className="w-4 h-4 text-zinc-500" />
                             </div>
                        </div>
                    )}
                    <ChevronRight className="w-4 h-4 text-zinc-600" />
                </button>
            ))
        )}
        
        <button 
          onClick={() => { resetDossierForm(); setIsAddDossierOpen(true); }}
          className="w-full py-4 rounded-2xl border border-dashed border-zinc-700 text-zinc-500 font-bold hover:bg-zinc-800/50 transition-colors flex items-center justify-center gap-2"
        >
          <Plus className="w-5 h-5" /> Thêm mới
        </button>
      </div>
    </div>
  );
};
