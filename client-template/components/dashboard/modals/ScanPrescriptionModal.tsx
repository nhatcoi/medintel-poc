
import React, { useState, useRef } from 'react';
import { X, Camera, Image as ImageIcon, Loader2, Check, Sparkles, ChevronRight, Pill, Calendar, Clock, ArrowRight, FolderPlus, Edit2, AlertCircle } from 'lucide-react';
import { ExtendedMedication } from '../../../types';
import { MEDICATION_ICONS } from '../../../constants';
import { parseMedicationFromImage } from '../../../services/gemini';

interface ScanPrescriptionModalProps {
  onClose: () => void;
  onSave: (meds: ExtendedMedication[]) => void;
}

export const ScanPrescriptionModal: React.FC<ScanPrescriptionModalProps> = ({ onClose, onSave }) => {
  const [step, setStep] = useState<'upload' | 'scanning' | 'review'>('upload');
  const [scannedImage, setScannedImage] = useState<string | null>(null);
  const [extractedMeds, setExtractedMeds] = useState<ExtendedMedication[]>([]);
  const [prescriptionName, setPrescriptionName] = useState('');
  const [error, setError] = useState<string | null>(null);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setScannedImage(result);
        startScanning(result);
      };
      reader.readAsDataURL(file);
    }
  };

  const startScanning = async (imageData: string) => {
    setStep('scanning');
    setError(null);
    
    try {
        const results = await parseMedicationFromImage(imageData);
        
        if (results && results.length > 0) {
            setExtractedMeds(results);
            // Set default prescription name with today's date
            const today = new Date();
            setPrescriptionName(`Đơn ${today.getDate()}/${today.getMonth() + 1}`);
            setStep('review');
        } else {
            setError("AI không tìm thấy thông tin thuốc nào trong ảnh. Vui lòng thử lại với ảnh rõ nét hơn.");
            setStep('upload');
        }
    } catch (err) {
        console.error("AI Scan Error:", err);
        setError("Có lỗi xảy ra khi phân tích ảnh. Vui lòng kiểm tra kết nối mạng.");
        setStep('upload');
    }
  };

  const handleRemoveMed = (index: number) => {
    setExtractedMeds(prev => prev.filter((_, i) => i !== index));
    if (extractedMeds.length <= 1) {
        // If they delete all items, maybe go back or just stay empty? 
        // Staying empty but review step allows adding manually or re-scanning?
        // For now, let's keep review step even if empty
    }
  };

  const handleConfirm = () => {
    // Add prescription ID to all meds
    const finalMeds = extractedMeds.map(med => ({
        ...med,
        prescriptionId: prescriptionName.trim() || undefined
    }));
    onSave(finalMeds);
  };

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto transition-opacity" onClick={onClose}></div>
      
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl h-[90vh] overflow-hidden">
        
        {/* Header */}
        <div className="flex justify-between items-center px-6 pt-6 pb-4 border-b border-white/5 bg-[#1c1c1e] z-10">
            <h3 className="text-lg font-bold text-white">Quét đơn thuốc</h3>
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                <X className="w-5 h-5 text-zinc-400" />
            </button>
        </div>

        <div className="flex-1 overflow-y-auto no-scrollbar p-6">
            
            {step === 'upload' && (
                <div className="flex flex-col items-center justify-center h-full space-y-8 pb-20">
                    <div className="w-20 h-20 rounded-full bg-purple-500/10 flex items-center justify-center relative">
                        <Sparkles className="w-10 h-10 text-purple-400 animate-pulse" />
                        <div className="absolute inset-0 rounded-full border border-purple-500/30 animate-ping"></div>
                    </div>
                    <div className="text-center space-y-2">
                        <h2 className="text-2xl font-bold text-white">AI Phân tích đơn thuốc</h2>
                        <p className="text-zinc-500 text-sm max-w-[260px] mx-auto">Chụp ảnh đơn thuốc hoặc vỏ thuốc, AI sẽ tự động trích xuất thông tin và lịch uống.</p>
                    </div>

                    {error && (
                        <div className="w-full bg-red-500/10 border border-red-500/20 rounded-xl p-3 flex items-start gap-3">
                            <AlertCircle className="w-5 h-5 text-red-400 shrink-0" />
                            <p className="text-xs text-red-300 font-medium mt-0.5">{error}</p>
                        </div>
                    )}

                    <div className="w-full space-y-3">
                        <button onClick={() => fileInputRef.current?.click()} className="w-full py-4 rounded-2xl bg-zinc-800 border border-white/5 flex items-center justify-center gap-3 active:scale-95 transition-transform hover:bg-zinc-700">
                             <Camera className="w-5 h-5 text-white" />
                             <span className="font-bold text-white">Chụp ảnh mới</span>
                        </button>
                        <button onClick={() => fileInputRef.current?.click()} className="w-full py-4 rounded-2xl bg-zinc-800 border border-white/5 flex items-center justify-center gap-3 active:scale-95 transition-transform hover:bg-zinc-700">
                             <ImageIcon className="w-5 h-5 text-white" />
                             <span className="font-bold text-white">Chọn từ thư viện</span>
                        </button>
                        <input type="file" ref={fileInputRef} className="hidden" accept="image/*" onChange={handleFileUpload} />
                    </div>
                </div>
            )}

            {step === 'scanning' && (
                <div className="flex flex-col items-center justify-center h-full pb-20">
                     <div className="relative w-64 h-80 rounded-2xl overflow-hidden border-2 border-purple-500/30 mb-8 shadow-2xl shadow-purple-900/20">
                         {scannedImage && <img src={scannedImage} className="w-full h-full object-cover opacity-50" />}
                         
                         {/* Scanning Line Animation */}
                         <div className="absolute top-0 left-0 right-0 h-1 bg-purple-500 shadow-[0_0_20px_#a855f7] animate-[scan_2s_ease-in-out_infinite]"></div>
                         
                         <div className="absolute inset-0 flex items-center justify-center">
                              <Loader2 className="w-12 h-12 text-purple-400 animate-spin" />
                         </div>
                     </div>
                     <h3 className="text-xl font-bold text-white animate-pulse">Đang xử lý hình ảnh...</h3>
                     <p className="text-zinc-500 text-sm mt-2">Đang nhận diện tên thuốc và liều lượng</p>
                </div>
            )}

            {step === 'review' && (
                <div className="animate-in slide-in-from-bottom duration-500">
                    <div className="flex items-center gap-3 mb-6 bg-purple-500/10 p-4 rounded-2xl border border-purple-500/20">
                        <div className="w-10 h-10 rounded-full bg-purple-500 flex items-center justify-center shrink-0">
                            <Sparkles className="w-5 h-5 text-white" />
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm">Đã tìm thấy {extractedMeds.length} thuốc</h4>
                            <p className="text-xs text-zinc-400">Kiểm tra lại thông tin trước khi thêm</p>
                        </div>
                    </div>

                    {/* Prescription Name Input */}
                    <div className="mb-6">
                        <label className="text-zinc-500 text-xs font-bold uppercase mb-2 block ml-1">Tên đơn thuốc</label>
                        <div className="bg-[#2c2c2e] p-2 rounded-2xl border border-white/5 flex items-center gap-3">
                             <div className="w-10 h-10 rounded-xl bg-zinc-800 flex items-center justify-center flex-shrink-0">
                                 <FolderPlus className="w-5 h-5 text-[#00c2ff]" />
                             </div>
                             <input 
                                type="text" 
                                value={prescriptionName} 
                                onChange={(e) => setPrescriptionName(e.target.value)} 
                                className="flex-1 bg-transparent text-white font-bold text-sm focus:outline-none placeholder:text-zinc-600"
                                placeholder="Ví dụ: Đơn thuốc A"
                             />
                             <div className="pr-2">
                                 <Edit2 className="w-4 h-4 text-zinc-500" />
                             </div>
                        </div>
                    </div>

                    <div className="space-y-4">
                        {extractedMeds.map((med, idx) => {
                             const Icon = MEDICATION_ICONS[med.icon || 'pill'];
                             return (
                                 <div key={idx} className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 relative group">
                                     <button 
                                        onClick={() => handleRemoveMed(idx)}
                                        className="absolute top-2 right-2 p-2 text-zinc-500 hover:text-red-400 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
                                     >
                                         <X className="w-4 h-4" />
                                     </button>

                                     <div className="flex items-start gap-4">
                                         <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: `${med.color}20` }}>
                                             <Icon className="w-6 h-6" style={{ color: med.color }} />
                                         </div>
                                         <div className="flex-1 min-w-0">
                                             <h4 className="font-bold text-white text-base truncate pr-6">{med.name}</h4>
                                             <p className="text-xs text-zinc-400 font-medium mt-1">{med.dosage} • {med.direction}</p>
                                             
                                             <div className="flex flex-wrap gap-2 mt-3">
                                                 {med.timeOfDay.length > 0 ? med.timeOfDay.map(t => (
                                                     <span key={t} className="bg-black/30 px-2 py-1 rounded text-[10px] font-bold text-zinc-300 flex items-center gap-1">
                                                         <Clock className="w-3 h-3" /> {t}
                                                     </span>
                                                 )) : (
                                                     <span className="bg-black/30 px-2 py-1 rounded text-[10px] font-bold text-zinc-300">Khi cần</span>
                                                 )}
                                                 {med.expectedDuration && (
                                                     <span className="bg-black/30 px-2 py-1 rounded text-[10px] font-bold text-zinc-300 flex items-center gap-1">
                                                          <Calendar className="w-3 h-3" /> {med.expectedDuration}
                                                     </span>
                                                 )}
                                             </div>
                                         </div>
                                     </div>
                                 </div>
                             );
                        })}
                    </div>
                </div>
            )}
        </div>

        {/* Footer */}
        {step === 'review' && (
            <div className="p-6 bg-[#1c1c1e] border-t border-white/5 w-full flex gap-3">
                <button 
                    onClick={() => { setStep('upload'); setExtractedMeds([]); }}
                    className="flex-1 py-4 bg-zinc-800 text-white rounded-2xl font-bold text-sm active:scale-[0.98] transition-all"
                >
                    Hủy bỏ
                </button>
                <button 
                    onClick={handleConfirm}
                    disabled={extractedMeds.length === 0}
                    className="flex-[2] py-4 bg-purple-600 hover:bg-purple-500 text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-all shadow-lg shadow-purple-600/20 flex items-center justify-center gap-2 disabled:opacity-50 disabled:grayscale"
                >
                    Thêm vào tủ thuốc <ArrowRight className="w-5 h-5" />
                </button>
            </div>
        )}
      </div>
      
      <style>{`
        @keyframes scan {
          0% { top: 0%; opacity: 0; }
          10% { opacity: 1; }
          90% { opacity: 1; }
          100% { top: 100%; opacity: 0; }
        }
      `}</style>
    </div>
  );
};
