
import React, { useMemo } from 'react';
import { Pill, Activity, Plus, FolderOpen, ChevronRight } from 'lucide-react';
import { Member, ExtendedMedication } from '../../../types';
import { MEDICATION_ICONS } from '../../../constants';

interface MedicationsTabProps {
  activeMember: Member;
  onAddMedication: () => void;
  onSelectMedication: (med: ExtendedMedication) => void;
}

export const MedicationsTab: React.FC<MedicationsTabProps> = ({ activeMember, onAddMedication, onSelectMedication }) => {
  
  // 1. Group by Medication Definition (groupId) first to get unique meds
  const uniqueMeds = useMemo(() => {
    const definitions: Record<string, { med: ExtendedMedication, times: string[] }> = {};
    
    activeMember.meds.forEach(med => {
        const key = med.groupId || med.name; 
        if (!definitions[key]) {
            definitions[key] = { med: med, times: [] };
        }
        // Collect times for this definition
        if (med.timeOfDay && med.timeOfDay[0]) {
             definitions[key].times.push(med.timeOfDay[0]);
        }
    });

    return Object.values(definitions).map(def => ({
        ...def.med,
        timeOfDay: Array.from(new Set(def.times)).sort() // Aggregated unique times
    }));
  }, [activeMember.meds]);

  // 2. Group these unique meds by Prescription (prescriptionId)
  const { prescriptions, singles } = useMemo(() => {
      const groups: Record<string, ExtendedMedication[]> = {};
      const singleList: ExtendedMedication[] = [];

      uniqueMeds.forEach(med => {
          if (med.prescriptionId && med.prescriptionId.trim() !== '') {
              if (!groups[med.prescriptionId]) {
                  groups[med.prescriptionId] = [];
              }
              groups[med.prescriptionId].push(med);
          } else {
              singleList.push(med);
          }
      });

      return { prescriptions: groups, singles: singleList };
  }, [uniqueMeds]);

  const renderMedRow = (med: ExtendedMedication, isCompact = false) => {
      const MedIcon = MEDICATION_ICONS[med.icon || 'pill'] || Pill;
      
      return (
        <button 
            key={med.groupId || med.id}
            onClick={() => onSelectMedication(med)}
            className={`w-full flex items-center justify-between transition-colors text-left group ${isCompact ? 'py-3 border-b border-white/5 last:border-0 hover:bg-white/5 px-2 rounded-lg' : 'bg-[#1c1c1e] p-4 rounded-2xl border border-white/5 active:bg-zinc-800 mb-3'}`}
        >
          <div className="flex items-center gap-4">
            <div 
                className={`${isCompact ? 'w-10 h-10 rounded-xl' : 'w-12 h-12 rounded-2xl'} flex items-center justify-center shadow-lg transition-transform group-active:scale-95`}
                style={{ backgroundColor: `${med.color || '#00c2ff'}20` }} 
            >
              <MedIcon className={`${isCompact ? 'w-5 h-5' : 'w-6 h-6'}`} style={{ color: med.color || '#00c2ff' }} />
            </div>
            <div>
              <h5 className={`font-bold text-white ${isCompact ? 'text-sm' : 'text-base'}`}>{med.name}</h5>
              <p className="text-xs text-zinc-500 mt-0.5 font-medium">
                  {med.dosage} • {med.timeOfDay.length > 0 ? med.timeOfDay.join(', ') : 'Khi cần'}
              </p>
            </div>
          </div>
          {isCompact && <ChevronRight className="w-4 h-4 text-zinc-700 group-hover:text-zinc-500" />}
        </button>
      );
  };

  return (
    <div className="animate-in fade-in slide-in-from-bottom-2 duration-300 pb-20">
      <h3 className="text-2xl font-black text-white tracking-tight mb-6">Tủ thuốc của {activeMember.name}</h3>
      
      {/* 1. PRESCRIPTION GROUPS */}
      {Object.entries(prescriptions).map(([groupName, meds]) => {
          const medList = meds as ExtendedMedication[];
          return (
          <div key={groupName} className="mb-6 animate-in slide-in-from-bottom-4 duration-500">
              <div className="flex items-center gap-2 mb-3">
                  <FolderOpen className="w-4 h-4 text-[#00c2ff]" />
                  <h4 className="text-zinc-400 text-xs font-bold uppercase tracking-widest">Đơn: {groupName}</h4>
                  <span className="bg-zinc-800 text-zinc-500 text-[10px] font-bold px-2 py-0.5 rounded-full ml-auto">{medList.length} thuốc</span>
              </div>
              <div className="bg-[#141416] border border-white/5 rounded-3xl p-2 overflow-hidden">
                  {medList.map(med => renderMedRow(med, true))}
              </div>
          </div>
      )})}

      {/* 2. SINGLE MEDICATIONS */}
      {singles.length > 0 && (
        <div className="mb-8">
           {Object.keys(prescriptions).length > 0 && (
               <h4 className="text-zinc-500 text-[10px] font-bold uppercase tracking-widest mb-4 mt-8 px-1">Thuốc lẻ</h4>
           )}
           <div className="grid grid-cols-1">
             {singles.map(med => renderMedRow(med))}
           </div>
        </div>
      )}

      {/* EMPTY STATE */}
      {singles.length === 0 && Object.keys(prescriptions).length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 opacity-50">
              <Pill className="w-12 h-12 text-zinc-600 mb-4" />
              <p className="text-zinc-500 font-bold">Chưa có thuốc nào</p>
          </div>
      )}

      <button onClick={onAddMedication} className="w-full py-4 rounded-2xl border border-dashed border-zinc-700 text-zinc-500 font-bold hover:bg-zinc-800/50 transition-colors flex items-center justify-center gap-2 mt-4">
        <Plus className="w-5 h-5" /> Thêm thuốc mới
      </button>
    </div>
  );
};
