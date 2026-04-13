
import React, { useState } from 'react';
import { X, Sparkles, ArrowRight, Loader2, Quote, Clock, Calendar, Check, AlertCircle } from 'lucide-react';
import { ExtendedMedication } from '../../../types';
import { parseMedicationFromText } from '../../../services/gemini';
import { MEDICATION_ICONS } from '../../../constants';

interface SmartInputModalProps {
  onClose: () => void;
  onSave: (meds: ExtendedMedication[]) => void;
}

export const SmartInputModal: React.FC<SmartInputModalProps> = ({ onClose, onSave }) => {
  const [inputText, setInputText] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [parsedMeds, setParsedMeds] = useState<ExtendedMedication[]>([]);
  const [step, setStep] = useState<'input' | 'review'>('input');
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async () => {
    if (!inputText.trim()) return;
    setIsAnalyzing(true);
    setError(null);
    
    try {
      const results = await parseMedicationFromText(inputText);
      if (results && results.length > 0) {
        setParsedMeds(results);
        setStep('review');
      } else {
        setError("AI không tìm thấy thông tin thuốc hợp lệ. Vui lòng thử lại chi tiết hơn.");
      }
    } catch (err) {
      setError("Có lỗi xảy ra khi phân tích. Vui lòng thử lại.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleRemoveMed = (index: number) => {
    setParsedMeds(prev => prev.filter((_, i) => i !== index));
    if (parsedMeds.length <= 1) {
        setStep('input');
    }
  };

  const handleConfirm = () => {
    onSave(parsedMeds);
  };

  const suggestedTexts = [
    "Bị sốt, uống Paracetamol 500mg, mỗi lần 1 viên, ngày 2–3 lần sau ăn.",
    "Kháng sinh Augmentin 1g sáng 1 viên, chiều 1 viên uống trong 7 ngày.",
    "Vitamin C uống mỗi buổi sáng 1 viên."
  ];

  return (
    <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto" onClick={onClose}></div>
      
      <div className="relative w-full max-w-md bg-[#1c1c1e] rounded-t-[2.5rem] h-[92vh] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl overflow-hidden">
        
        {/* Header */}
        <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#1c1c1e] z-10">
            <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-indigo-400" />
                Nhập thông minh
            </h3>
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700">
                <X className="w-5 h-5 text-zinc-400" />
            </button>
        </div>

        <div className="flex-1 overflow-y-auto no-scrollbar px-6 pb-24 relative">
            
            {step === 'input' && (
                <div className="animate-in fade-in duration-300 h-full flex flex-col">
                    <p className="text-zinc-400 text-sm mb-4">
                        Nhập hoặc dán lời dặn của bác sĩ, AI sẽ tự động tạo lịch uống thuốc cho bạn.
                    </p>

                    <div className="relative flex-1 min-h-[200px] mb-4">
                        <textarea
                            value={inputText}
                            onChange={(e) => setInputText(e.target.value)}
                            placeholder="Ví dụ: Bị sốt, uống Paracetamol 500mg, mỗi lần 1 viên, ngày 2–3 lần, uống sau ăn..."
                            className="w-full h-full bg-[#2c2c2e] rounded-2xl p-5 text-white font-medium text-base leading-relaxed focus:outline-none focus:ring-2 focus:ring-indigo-500/50 border border-white/5 resize-none placeholder:text-zinc-600"
                        />
                        {isAnalyzing && (
                            <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px] rounded-2xl flex flex-col items-center justify-center z-10">
                                <Loader2 className="w-10 h-10 text-indigo-400 animate-spin mb-3" />
                                <span className="text-white font-bold text-sm animate-pulse">AI đang phân tích...</span>
                            </div>
                        )}
                    </div>
                    
                    {error && (
                        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-3 flex items-start gap-3 mb-4">
                            <AlertCircle className="w-5 h-5 text-red-400 shrink-0" />
                            <p className="text-xs text-red-300 font-medium mt-0.5">{error}</p>
                        </div>
                    )}

                    <div className="mb-6">
                        <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-wider mb-3 block">Gợi ý mẫu</span>
                        <div className="space-y-2">
                            {suggestedTexts.map((text, idx) => (
                                <button 
                                    key={idx}
                                    onClick={() => setInputText(text)}
                                    className="w-full text-left p-3 rounded-xl bg-zinc-800/50 hover:bg-zinc-800 border border-white/5 text-xs text-zinc-400 flex gap-3 transition-colors group"
                                >
                                    <Quote className="w-4 h-4 text-zinc-600 shrink-0 group-hover:text-indigo-400" />
                                    {text}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>
            )}

            {step === 'review' && (
                <div className="animate-in slide-in-from-right duration-300">
                    <div className="flex items-center gap-3 mb-6 bg-indigo-500/10 p-4 rounded-2xl border border-indigo-500/20">
                        <div className="w-10 h-10 rounded-full bg-indigo-500 flex items-center justify-center shrink-0 shadow-lg shadow-indigo-500/30">
                            <Check className="w-5 h-5 text-white stroke-[3]" />
                        </div>
                        <div>
                            <h4 className="font-bold text-white text-sm">Đã tìm thấy {parsedMeds.length} thuốc</h4>
                            <p className="text-xs text-zinc-400">Vui lòng kiểm tra lại thông tin</p>
                        </div>
                    </div>

                    <div className="space-y-4">
                        {parsedMeds.map((med, idx) => {
                             const Icon = MEDICATION_ICONS[med.icon || 'pill'];
                             return (
                                 <div key={idx} className="bg-[#2c2c2e] p-4 rounded-2xl border border-white/5 relative group animate-in slide-in-from-bottom duration-500" style={{ animationDelay: `${idx * 100}ms` }}>
                                     <button 
                                        onClick={() => handleRemoveMed(idx)}
                                        className="absolute top-2 right-2 p-2 text-zinc-500 hover:text-red-400"
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
                                                         <Clock className="w-3 h-3 text-indigo-400" /> {t}
                                                     </span>
                                                 )) : (
                                                     <span className="bg-black/30 px-2 py-1 rounded text-[10px] font-bold text-zinc-300">Khi cần</span>
                                                 )}
                                                 {med.expectedDuration && (
                                                     <span className="bg-black/30 px-2 py-1 rounded text-[10px] font-bold text-zinc-300 flex items-center gap-1">
                                                          <Calendar className="w-3 h-3 text-emerald-400" /> {med.expectedDuration}
                                                     </span>
                                                 )}
                                             </div>
                                             {med.notes && (
                                                <div className="mt-2 text-xs text-zinc-500 italic border-l-2 border-zinc-700 pl-2">
                                                    "{med.notes}"
                                                </div>
                                             )}
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
        <div className="absolute bottom-0 left-0 right-0 p-6 bg-[#1c1c1e] border-t border-white/5 z-20">
            {step === 'input' ? (
                <button 
                    onClick={handleAnalyze}
                    disabled={!inputText.trim() || isAnalyzing}
                    className="w-full py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-all shadow-lg shadow-indigo-600/20 flex items-center justify-center gap-2 disabled:opacity-50 disabled:grayscale"
                >
                    {isAnalyzing ? (
                        <>Đang phân tích...</>
                    ) : (
                        <>Phân tích <Sparkles className="w-5 h-5" /></>
                    )}
                </button>
            ) : (
                <div className="flex gap-3">
                    <button 
                        onClick={() => setStep('input')}
                        className="flex-1 py-4 bg-zinc-800 text-white rounded-2xl font-bold text-sm active:scale-[0.98] transition-all"
                    >
                        Quay lại
                    </button>
                    <button 
                        onClick={handleConfirm}
                        className="flex-[2] py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-2xl font-bold text-base active:scale-[0.98] transition-all shadow-lg shadow-indigo-600/20 flex items-center justify-center gap-2"
                    >
                        Lưu vào tủ thuốc <ArrowRight className="w-5 h-5" />
                    </button>
                </div>
            )}
        </div>
      </div>
    </div>
  );
};
