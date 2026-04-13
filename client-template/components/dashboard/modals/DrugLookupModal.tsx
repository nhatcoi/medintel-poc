
import React, { useState, useMemo } from 'react';
import { Search, X, ChevronRight, Pill, Tablet, Droplets, Syringe, AlertTriangle, CheckCircle2, FileText, Info, Plus } from 'lucide-react';
import { DRUG_DATABASE } from '../../../data/mockDrugs';
import { DrugReference, ExtendedMedication } from '../../../types';

interface DrugLookupModalProps {
  onClose: () => void;
  onAddToCabinet: (drug: DrugReference) => void;
}

export const DrugLookupModal: React.FC<DrugLookupModalProps> = ({ onClose, onAddToCabinet }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDrug, setSelectedDrug] = useState<DrugReference | null>(null);

  // Filter logic
  const filteredDrugs = useMemo(() => {
    if (!searchQuery.trim()) return DRUG_DATABASE;
    const lowerQuery = searchQuery.toLowerCase();
    return DRUG_DATABASE.filter(drug => 
      drug.name.toLowerCase().includes(lowerQuery) || 
      drug.ingredient.toLowerCase().includes(lowerQuery) ||
      drug.group.toLowerCase().includes(lowerQuery)
    );
  }, [searchQuery]);

  // Icon mapping helper
  const getDrugIcon = (type: string) => {
    switch (type) {
      case 'pill': return Pill;
      case 'syrup': return Droplets;
      case 'injection': return Syringe;
      default: return Tablet;
    }
  };

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto" onClick={onClose}></div>
      
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
        
        {/* Header with Search */}
        <div className="flex flex-col bg-[#1c1c1e] z-10 border-b border-white/5 pt-6 px-6 pb-4">
            <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-bold text-white">Tra cứu thuốc</h3>
                <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                    <X className="w-5 h-5 text-zinc-400" />
                </button>
            </div>
            
            <div className="relative">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500" />
                <input 
                    type="text" 
                    placeholder="Tìm tên thuốc, hoạt chất..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl py-3.5 pl-12 pr-4 text-white font-medium focus:outline-none focus:border-[#00c2ff] focus:ring-1 focus:ring-[#00c2ff] transition-all placeholder:text-zinc-600"
                    autoFocus
                />
            </div>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto no-scrollbar relative">
            {selectedDrug ? (
                // --- DETAIL VIEW ---
                <div className="p-6 space-y-6 animate-in slide-in-from-right duration-300">
                    <button onClick={() => setSelectedDrug(null)} className="text-zinc-500 text-xs font-bold flex items-center gap-1 hover:text-white mb-2">
                        <ChevronRight className="w-4 h-4 rotate-180" /> Quay lại danh sách
                    </button>

                    {/* Hero Header */}
                    <div className="flex items-start gap-5">
                         <div className="w-16 h-16 rounded-2xl bg-[#00c2ff]/10 flex items-center justify-center border border-[#00c2ff]/20 shrink-0">
                             {React.createElement(getDrugIcon(selectedDrug.iconType), { className: "w-8 h-8 text-[#00c2ff]" })}
                         </div>
                         <div>
                             <h2 className="text-2xl font-bold text-white leading-tight">{selectedDrug.name}</h2>
                             <span className="text-[#00c2ff] text-xs font-bold bg-[#00c2ff]/10 px-2 py-0.5 rounded-md mt-2 inline-block">
                                 {selectedDrug.group}
                             </span>
                         </div>
                    </div>

                    <div className="space-y-4">
                        {/* Ingredient */}
                        <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5">
                            <h4 className="text-zinc-500 text-xs font-bold uppercase mb-2 flex items-center gap-2">
                                <FileText className="w-4 h-4" /> Thành phần
                            </h4>
                            <p className="text-white font-medium text-sm leading-relaxed">{selectedDrug.ingredient}</p>
                        </div>

                        {/* Usage & Dosage */}
                        <div className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 space-y-4">
                            <div>
                                <h4 className="text-zinc-500 text-xs font-bold uppercase mb-2 flex items-center gap-2">
                                    <CheckCircle2 className="w-4 h-4 text-emerald-500" /> Chỉ định
                                </h4>
                                <p className="text-white font-medium text-sm leading-relaxed">{selectedDrug.usage}</p>
                            </div>
                            <div className="h-[1px] bg-white/5 w-full"></div>
                            <div>
                                <h4 className="text-zinc-500 text-xs font-bold uppercase mb-2 flex items-center gap-2">
                                    <Info className="w-4 h-4 text-blue-500" /> Liều dùng tham khảo
                                </h4>
                                <p className="text-white font-medium text-sm leading-relaxed">{selectedDrug.dosage}</p>
                            </div>
                        </div>

                        {/* Warnings */}
                        <div className="bg-red-500/5 p-4 rounded-2xl border border-red-500/10 space-y-4">
                            <div>
                                <h4 className="text-red-400 text-xs font-bold uppercase mb-2 flex items-center gap-2">
                                    <AlertTriangle className="w-4 h-4" /> Chống chỉ định
                                </h4>
                                <p className="text-zinc-300 font-medium text-sm leading-relaxed">{selectedDrug.contraindication}</p>
                            </div>
                            {selectedDrug.sideEffect && (
                                <div className="mt-3 pt-3 border-t border-red-500/10">
                                    <h4 className="text-red-400 text-xs font-bold uppercase mb-2">Tác dụng phụ</h4>
                                    <p className="text-zinc-300 font-medium text-sm leading-relaxed">{selectedDrug.sideEffect}</p>
                                </div>
                            )}
                        </div>
                         
                        {selectedDrug.warning && (
                            <div className="bg-orange-500/5 p-4 rounded-2xl border border-orange-500/10">
                                <h4 className="text-orange-400 text-xs font-bold uppercase mb-2">Lưu ý & Thận trọng</h4>
                                <p className="text-zinc-300 font-medium text-sm leading-relaxed">{selectedDrug.warning}</p>
                            </div>
                        )}
                    </div>

                    <div className="h-20"></div> {/* Spacer */}
                </div>
            ) : (
                // --- LIST VIEW ---
                <div className="p-4 space-y-2">
                    {filteredDrugs.length > 0 ? (
                        filteredDrugs.map(drug => (
                            <button 
                                key={drug.id}
                                onClick={() => setSelectedDrug(drug)}
                                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#2c2c2e] hover:bg-zinc-800 border border-white/5 transition-all text-left group"
                            >
                                <div className="w-12 h-12 rounded-xl bg-zinc-900 flex items-center justify-center shrink-0 group-hover:bg-[#00c2ff]/20 transition-colors">
                                    {React.createElement(getDrugIcon(drug.iconType), { className: "w-6 h-6 text-zinc-500 group-hover:text-[#00c2ff]" })}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <h4 className="text-white font-bold text-base truncate">{drug.name}</h4>
                                    <p className="text-zinc-500 text-xs font-medium truncate mt-0.5">{drug.ingredient}</p>
                                    <div className="flex gap-2 mt-2">
                                        <span className="text-[10px] bg-zinc-800 text-zinc-400 px-2 py-0.5 rounded font-bold border border-white/5 truncate max-w-[150px]">
                                            {drug.group}
                                        </span>
                                    </div>
                                </div>
                                <ChevronRight className="w-5 h-5 text-zinc-600 group-hover:text-zinc-400" />
                            </button>
                        ))
                    ) : (
                        <div className="text-center py-20">
                            <div className="w-16 h-16 bg-zinc-900 rounded-full flex items-center justify-center mx-auto mb-4">
                                <Search className="w-6 h-6 text-zinc-600" />
                            </div>
                            <p className="text-zinc-500 font-bold">Không tìm thấy thuốc</p>
                            <p className="text-zinc-600 text-sm mt-1">Thử tìm bằng tên hoạt chất</p>
                        </div>
                    )}
                </div>
            )}
        </div>

        {/* Footer Action (Only in Detail View) */}
        {selectedDrug && (
            <div className="absolute bottom-0 left-0 right-0 p-6 bg-[#1c1c1e] border-t border-white/5 z-20">
                <button 
                    onClick={() => onAddToCabinet(selectedDrug)}
                    className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-transform shadow-lg shadow-[#00c2ff]/20 flex items-center justify-center gap-2"
                >
                    <Plus className="w-5 h-5" /> Thêm vào tủ thuốc
                </button>
            </div>
        )}

      </div>
    </div>
  );
};
