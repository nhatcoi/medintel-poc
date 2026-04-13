
import React, { useState, useRef } from 'react';
import { X, Loader2, Sparkles, ChevronRight, Upload, Zap, Camera, ImageIcon as PictureIcon } from 'lucide-react';
import { Dossier } from '../../../types';
import { DOSSIER_TYPES } from '../../../constants';
import { parseDossierFromImage } from '../../../services/gemini';

interface AddDossierModalProps {
  onClose: () => void;
  onSave: (dossier: Dossier) => void;
}

export const AddDossierModal: React.FC<AddDossierModalProps> = ({ onClose, onSave }) => {
  const [dossierForm, setDossierForm] = useState<{
    title: string;
    hospital: string;
    department: string;
    doctor: string;
    details: string;
    type: string;
    images: string[];
  }>({
      title: '',
      hospital: '',
      department: '',
      doctor: '',
      details: '',
      type: 'Exam',
      images: []
  });
  const [dossierScanning, setDossierScanning] = useState(false);
  const [isAiSourceMenuOpen, setIsAiSourceMenuOpen] = useState(false);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const libraryInputRef = useRef<HTMLInputElement>(null);

  const handleAiInputFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setIsAiSourceMenuOpen(false); // Close menu immediately
      setDossierScanning(true);
      
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64String = reader.result as string;
        
        // Add image immediately to preview
        setDossierForm(prev => ({
          ...prev,
          images: [...prev.images, base64String]
        }));

        try {
            // Call Gemini AI
            const result = await parseDossierFromImage(base64String);
            
            if (result) {
                setDossierForm(prev => ({
                    ...prev,
                    title: result.title || prev.title,
                    hospital: result.hospital || prev.hospital,
                    doctor: result.doctor || prev.doctor,
                    type: result.type || prev.type,
                    details: result.details || prev.details,
                    // Note: We don't overwrite date here as it's not in local state, 
                    // but usually you might want to save the date too. 
                    // For now, Dossier type saves date on save, or we could add date to local state.
                    // The current form structure relies on Date.now() on save, but let's stick to UI fields.
                }));
            }
        } catch (err) {
            console.error("Error analyzing dossier:", err);
            // Optionally set an error state here
        } finally {
            setDossierScanning(false);
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const handleAiSourceSelect = (source: 'camera' | 'library') => {
    if (source === 'camera') {
        cameraInputRef.current?.click();
    } else {
        libraryInputRef.current?.click();
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result;
        if (typeof result === 'string') {
          setDossierForm(prev => ({
            ...prev,
            images: [...prev.images, result]
          }));
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = (index: number) => {
    setDossierForm(prev => ({
      ...prev,
      images: prev.images.filter((_, i) => i !== index)
    }));
  };

  const handleSaveInternal = () => {
      if (!dossierForm.title) return;
      const newDossier: Dossier = {
          id: Date.now().toString(),
          title: dossierForm.title,
          date: new Date().toLocaleDateString('vi-VN', {day: '2-digit', month: 'short', year: 'numeric'}),
          type: dossierForm.type,
          hospital: dossierForm.hospital,
          doctor: dossierForm.doctor,
          details: dossierForm.details,
          images: dossierForm.images
      };
      onSave(newDossier);
  };

  return (
    <>
      {/* Hidden Inputs */}
      <input type="file" accept="image/*" capture="environment" className="hidden" ref={cameraInputRef} onChange={handleAiInputFile} />
      <input type="file" accept="image/*" className="hidden" ref={libraryInputRef} onChange={handleAiInputFile} />

      <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
          <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={onClose}></div>
          <div className="relative w-full max-w-md h-[95vh] bg-white rounded-t-[2.5rem] flex flex-col animate-in slide-in-from-bottom duration-400 pointer-events-auto overflow-hidden">
             
             <header className="flex justify-between items-center px-6 pt-6 pb-4 relative">
                <div className="w-8"></div> 
                <h2 className="text-lg font-bold text-black">Thêm hồ sơ</h2>
                <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-gray-100 rounded-full text-gray-500 hover:bg-gray-200">
                    <X className="w-5 h-5" />
                </button>
             </header>

             <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-24">
                {/* AI Button */}
                <button 
                    onClick={() => setIsAiSourceMenuOpen(true)}
                    disabled={dossierScanning}
                    className="w-full mb-8 bg-gradient-to-r from-purple-50 to-pink-50 border border-purple-100 rounded-2xl p-4 shadow-[0_4px_20px_rgba(168,85,247,0.1)] flex items-center justify-between active:scale-[0.98] transition-all relative overflow-hidden"
                >
                    {dossierScanning && (
                        <div className="absolute inset-0 bg-white/40 backdrop-blur-sm flex items-center justify-center z-10">
                            <div className="flex items-center gap-3">
                                <Loader2 className="w-5 h-5 text-purple-600 animate-spin" />
                                <span className="text-purple-600 font-bold text-sm">Đang trích xuất dữ liệu...</span>
                            </div>
                        </div>
                    )}
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-purple-500 flex items-center justify-center shadow-lg shadow-purple-200">
                            <Sparkles className="w-5 h-5 text-white fill-white/20" />
                        </div>
                        <div className="text-left">
                            <span className="block font-bold text-purple-900 leading-tight">AI Trích xuất hồ sơ</span>
                            <span className="text-[10px] text-purple-600 font-medium uppercase tracking-wider">Tự động điền thông tin</span>
                        </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-purple-300" />
                </button>

                {/* Form Fields */}
                <div className="mb-8">
                    <span className="text-gray-900 font-bold text-sm block mb-3">Loại hồ sơ</span>
                    <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
                        {Object.entries(DOSSIER_TYPES).map(([key, config]) => (
                            <button
                                key={key}
                                onClick={() => setDossierForm(prev => ({ ...prev, type: key }))}
                                className={`px-4 py-2 rounded-xl text-xs font-bold whitespace-nowrap border transition-all ${
                                    dossierForm.type === key
                                        ? 'bg-black text-white border-black'
                                        : 'bg-gray-50 text-gray-500 border-gray-100 hover:bg-gray-100'
                                }`}
                            >
                                {config.label}
                            </button>
                        ))}
                    </div>
                </div>

                <div className="space-y-6 mb-8">
                    <div className="flex items-center justify-between py-2 border-b border-gray-50">
                        <span className="text-gray-600 font-medium text-sm">Bệnh viện / Nơi khám</span>
                        <div className="flex items-center gap-2 text-gray-400 text-sm">
                            <input 
                                className="text-right bg-transparent focus:outline-none text-black font-medium placeholder:text-gray-400 w-48 truncate"
                                placeholder="Chọn"
                                value={dossierForm.hospital}
                                onChange={(e) => setDossierForm({...dossierForm, hospital: e.target.value})}
                            />
                            <ChevronRight className="w-4 h-4" />
                        </div>
                    </div>
                    
                     <div className="flex items-center justify-between py-2 border-b border-gray-50">
                        <span className="text-gray-600 font-medium text-sm">Bác sĩ</span>
                        <div className="flex items-center gap-2 text-gray-400 text-sm">
                            <input 
                                className="text-right bg-transparent focus:outline-none text-black font-medium placeholder:text-gray-400 w-48 truncate"
                                placeholder="Chọn"
                                value={dossierForm.doctor}
                                onChange={(e) => setDossierForm({...dossierForm, doctor: e.target.value})}
                            />
                            <ChevronRight className="w-4 h-4" />
                        </div>
                    </div>
                </div>

                <div className="space-y-6">
                    <div>
                        <label className="block text-gray-800 font-bold text-sm mb-3">Tiêu đề hồ sơ</label>
                        <input 
                            type="text" 
                            placeholder="Nhập tiêu đề"
                            value={dossierForm.title}
                            onChange={(e) => setDossierForm({...dossierForm, title: e.target.value})}
                            className="w-full bg-gray-50 rounded-2xl p-4 text-sm font-medium text-black focus:outline-none focus:ring-2 focus:ring-purple-100 placeholder:text-gray-300"
                        />
                    </div>
                    <div>
                        <label className="block text-gray-800 font-bold text-sm mb-3">Chi tiết / Ghi chú</label>
                        <textarea 
                            placeholder="Nhập chi tiết"
                            rows={4}
                            value={dossierForm.details}
                            onChange={(e) => setDossierForm({...dossierForm, details: e.target.value})}
                            className="w-full bg-gray-50 rounded-2xl p-4 text-sm font-medium text-black focus:outline-none focus:ring-2 focus:ring-purple-100 placeholder:text-gray-300 resize-none"
                        />
                    </div>

                     <div>
                        <label className="block text-gray-800 font-bold text-sm mb-3">Hình ảnh</label>
                        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2">
                            {dossierForm.images.map((img, idx) => (
                                <div key={idx} className="relative w-20 h-20 flex-shrink-0 rounded-xl overflow-hidden group">
                                    <img src={img} alt="scan" className="w-full h-full object-cover" />
                                    <button 
                                        onClick={() => removeImage(idx)}
                                        className="absolute top-1 right-1 bg-black/50 text-white rounded-full p-0.5 opacity-100"
                                    >
                                        <X className="w-3 h-3" />
                                    </button>
                                    {dossierScanning && idx === dossierForm.images.length - 1 && (
                                        <div className="absolute inset-0 bg-purple-500/40 flex items-center justify-center">
                                            <Zap className="w-6 h-6 text-white animate-pulse" />
                                        </div>
                                    )}
                                </div>
                            ))}
                            <label className="w-20 h-20 flex-shrink-0 rounded-xl bg-gray-50 border border-dashed border-gray-300 flex flex-col items-center justify-center cursor-pointer hover:bg-gray-100 transition-colors">
                                <Upload className="w-5 h-5 text-gray-400 mb-1" />
                                <span className="text-[10px] font-bold text-gray-500">Thêm</span>
                                <input type="file" accept="image/*" className="hidden" onChange={handleImageUpload} />
                            </label>
                        </div>
                    </div>
                </div>
             </div>

             <div className="absolute bottom-0 left-0 right-0 p-6 bg-white border-t border-gray-50">
                 <button onClick={handleSaveInternal} className="w-full py-4 bg-black text-white rounded-2xl font-bold text-sm active:scale-[0.98] transition-transform">
                     Lưu hồ sơ
                 </button>
             </div>
          </div>
      </div>

      {/* AI Source Menu (Sub-modal) */}
      {isAiSourceMenuOpen && (
          <div className="fixed inset-0 z-[1001] flex flex-col justify-end">
              <div className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300" onClick={() => setIsAiSourceMenuOpen(false)}></div>
              <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2rem] p-6 pb-12 animate-in slide-in-from-bottom duration-300 border-t border-white/10 shadow-2xl">
                  <div className="w-12 h-1.5 bg-zinc-700 rounded-full mx-auto mb-6"></div>
                  <h3 className="text-lg font-bold text-white mb-6 px-2">Chọn nguồn hình ảnh</h3>
                  <div className="space-y-3">
                      <button onClick={() => handleAiSourceSelect('camera')} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800 hover:bg-zinc-700 transition-colors text-left group">
                          <div className="w-12 h-12 rounded-xl bg-blue-500/20 flex items-center justify-center group-active:scale-95 transition-transform">
                              <Camera className="w-6 h-6 text-blue-400" />
                          </div>
                          <div>
                              <h4 className="font-bold text-white">Chụp ảnh</h4>
                              <p className="text-xs text-zinc-500">Dùng camera chụp trực tiếp hồ sơ</p>
                          </div>
                      </button>
                      <button onClick={() => handleAiSourceSelect('library')} className="w-full flex items-center gap-4 p-4 rounded-2xl bg-zinc-800 hover:bg-zinc-700 transition-colors text-left group">
                          <div className="w-12 h-12 rounded-xl bg-purple-500/20 flex items-center justify-center group-active:scale-95 transition-transform">
                              <PictureIcon className="w-6 h-6 text-purple-400" />
                          </div>
                          <div>
                              <h4 className="font-bold text-white">Thư viện ảnh</h4>
                              <p className="text-xs text-zinc-500">Chọn ảnh hồ sơ có sẵn trong máy</p>
                          </div>
                      </button>
                  </div>
                  <button onClick={() => setIsAiSourceMenuOpen(false)} className="w-full py-4 mt-6 rounded-2xl bg-zinc-900 text-zinc-400 font-bold active:bg-zinc-800 transition-all">Hủy bỏ</button>
              </div>
          </div>
      )}
    </>
  );
};
