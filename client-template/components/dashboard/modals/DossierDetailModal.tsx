
import React, { useState, useEffect } from 'react';
import { ChevronLeft, X, Edit2, Trash2, Upload, Image as ImageIcon, FileText } from 'lucide-react';
import { Dossier } from '../../../types';
import { DOSSIER_TYPES } from '../../../constants';

interface DossierDetailModalProps {
  dossier: Dossier;
  onClose: () => void;
  onUpdate: (updatedDossier: Dossier) => void;
  onDeleteRequest: () => void;
}

export const DossierDetailModal: React.FC<DossierDetailModalProps> = ({ 
  dossier, 
  onClose, 
  onUpdate, 
  onDeleteRequest 
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [form, setForm] = useState<Dossier>(dossier);

  // Sync form if dossier prop changes externally
  useEffect(() => {
    setForm(dossier);
  }, [dossier]);

  const handleSave = () => {
    onUpdate(form);
    setIsEditing(false);
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setForm(prev => ({
          ...prev,
          images: [...(prev.images || []), result]
        }));
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = (index: number) => {
    setForm(prev => ({
      ...prev,
      images: (prev.images || []).filter((_, i) => i !== index)
    }));
  };

  const DossierIcon = DOSSIER_TYPES[form.type]?.icon || FileText;

  return (
    <div className="absolute inset-0 z-[200] flex flex-col bg-black animate-in slide-in-from-right duration-300">
         {/* Header */}
         <div className="flex items-center justify-between px-6 pt-12 pb-6 bg-[#0f1d2a] border-b border-white/5">
              <button onClick={onClose} className="p-2 -ml-2 text-zinc-400 active:text-white">
                  <ChevronLeft className="w-6 h-6" />
              </button>
              <h2 className="text-lg font-bold text-white">
                  {isEditing ? 'Cập nhật hồ sơ' : 'Chi tiết hồ sơ'}
              </h2>
              <button 
                onClick={() => isEditing ? setIsEditing(false) : setIsEditing(true)} 
                className={`p-2 -mr-2 transition-colors ${isEditing ? 'text-zinc-400' : 'text-[#00c2ff]'}`}
              >
                  {isEditing ? <X className="w-6 h-6" /> : <Edit2 className="w-5 h-5" />}
              </button>
         </div>
         
         <div className="flex-1 overflow-y-auto no-scrollbar p-6">
             {isEditing ? (
                 // EDIT MODE
                 <div className="space-y-6">
                    {/* Type Selector */}
                    <div className="mb-4">
                        <span className="text-zinc-500 font-bold text-xs block mb-3 uppercase tracking-wider">Loại hồ sơ</span>
                        <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
                            {Object.entries(DOSSIER_TYPES).map(([key, config]) => (
                                <button
                                    key={key}
                                    onClick={() => setForm(prev => ({ ...prev, type: key }))}
                                    className={`px-4 py-2 rounded-xl text-xs font-bold whitespace-nowrap border transition-all ${
                                        form.type === key
                                            ? 'bg-[#00c2ff] text-white border-[#00c2ff]'
                                            : 'bg-[#1c1c1e] text-zinc-400 border-white/5 hover:bg-zinc-800'
                                    }`}
                                >
                                    {config.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div>
                        <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Tiêu đề</label>
                        <input 
                            type="text" 
                            value={form.title}
                            onChange={(e) => setForm({...form, title: e.target.value})}
                            className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5"
                        />
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4">
                         <div>
                            <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Bác sĩ</label>
                            <input 
                                type="text" 
                                value={form.doctor}
                                onChange={(e) => setForm({...form, doctor: e.target.value})}
                                className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5"
                            />
                         </div>
                         <div>
                            <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Cơ sở y tế</label>
                            <input 
                                type="text" 
                                value={form.hospital}
                                onChange={(e) => setForm({...form, hospital: e.target.value})}
                                className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5"
                            />
                         </div>
                    </div>

                    <div>
                        <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Chi tiết / Ghi chú</label>
                        <textarea 
                            rows={6}
                            value={form.details}
                            onChange={(e) => setForm({...form, details: e.target.value})}
                            className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5 resize-none"
                        />
                    </div>

                    {/* Image Upload in Edit Mode */}
                     <div>
                        <label className="block text-zinc-500 font-bold text-xs mb-3 uppercase tracking-wider">Hình ảnh</label>
                        <div className="grid grid-cols-3 gap-3">
                            {(form.images || []).map((img, idx) => (
                                <div key={idx} className="relative aspect-square rounded-xl overflow-hidden group">
                                    <img src={img} alt="scan" className="w-full h-full object-cover" />
                                    <button 
                                        onClick={() => removeImage(idx)}
                                        className="absolute top-1 right-1 bg-black/50 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                                    >
                                        <X className="w-3 h-3" />
                                    </button>
                                </div>
                            ))}
                            <label className="aspect-square rounded-xl bg-[#1c1c1e] border border-dashed border-zinc-700 flex flex-col items-center justify-center cursor-pointer hover:bg-zinc-800 transition-colors">
                                <Upload className="w-6 h-6 text-zinc-500 mb-2" />
                                <span className="text-[10px] font-bold text-zinc-600">Thêm ảnh</span>
                                <input type="file" accept="image/*" className="hidden" onChange={handleImageUpload} />
                            </label>
                        </div>
                    </div>

                    <button 
                        onClick={handleSave}
                        className="w-full py-4 bg-[#00c2ff] text-white rounded-2xl font-bold text-sm active:scale-[0.98] transition-transform mt-8"
                    >
                         Lưu thay đổi
                    </button>
                 </div>
             ) : (
                 // VIEW MODE
                 <>
                    <div className="mb-8">
                        <div className={`w-16 h-16 rounded-2xl flex items-center justify-center mb-4 ${DOSSIER_TYPES[form.type]?.bg || 'bg-zinc-800'}`}>
                            <DossierIcon className={`w-8 h-8 ${DOSSIER_TYPES[form.type]?.color || 'text-zinc-400'}`} />
                        </div>
                        <h1 className="text-2xl font-bold text-white mb-2">{form.title}</h1>
                        <span className="text-[#00c2ff] font-bold text-sm bg-[#00c2ff]/10 px-3 py-1 rounded-full">
                            {DOSSIER_TYPES[form.type]?.label || form.type}
                        </span>
                    </div>

                    {/* Info Grid */}
                    <div className="grid grid-cols-2 gap-4 mb-8">
                        <div className="bg-[#1c1c1e] p-4 rounded-2xl border border-white/5">
                            <span className="text-zinc-500 text-xs font-bold uppercase block mb-1">Ngày khám</span>
                            <span className="text-white font-bold">{form.date}</span>
                        </div>
                        <div className="bg-[#1c1c1e] p-4 rounded-2xl border border-white/5">
                            <span className="text-zinc-500 text-xs font-bold uppercase block mb-1">Bác sĩ</span>
                            <span className="text-white font-bold truncate">{form.doctor || '--'}</span>
                        </div>
                        <div className="col-span-2 bg-[#1c1c1e] p-4 rounded-2xl border border-white/5">
                            <span className="text-zinc-500 text-xs font-bold uppercase block mb-1">Cơ sở y tế</span>
                            <span className="text-white font-bold">{form.hospital || '--'}</span>
                        </div>
                    </div>

                    {/* Images Gallery */}
                    {form.images && form.images.length > 0 && (
                        <div className="mb-8">
                            <h3 className="text-white font-bold text-lg mb-4 flex items-center gap-2">
                                <ImageIcon className="w-5 h-5 text-zinc-400" /> Hình ảnh
                            </h3>
                            <div className="grid grid-cols-2 gap-3">
                                {form.images.map((img, idx) => (
                                    <div key={idx} className="rounded-xl overflow-hidden aspect-[4/3] bg-zinc-800">
                                        <img src={img} alt="Medical record" className="w-full h-full object-cover" />
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Details */}
                    <div className="mb-8">
                        <h3 className="text-white font-bold text-lg mb-4">Chi tiết / Chẩn đoán</h3>
                        <div className="bg-[#1c1c1e] p-6 rounded-2xl border border-white/5 text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap">
                            {form.details || "Không có ghi chú chi tiết."}
                        </div>
                    </div>
                    
                    {/* Delete Button */}
                    <button 
                        onClick={onDeleteRequest}
                        className="w-full py-4 rounded-2xl border border-red-500/20 text-red-500 font-bold bg-red-500/5 hover:bg-red-500/10 transition-colors flex items-center justify-center gap-2"
                    >
                        <Trash2 className="w-5 h-5" /> Xóa hồ sơ
                    </button>
                 </>
             )}
         </div>
    </div>
  );
};
