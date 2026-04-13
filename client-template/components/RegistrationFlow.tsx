
import React, { useState, useEffect } from 'react';
import { 
  ChevronRight, 
  ChevronLeft, 
  User, 
  HeartHandshake, 
  Users, 
  Activity, 
  CheckCircle2, 
  Sparkles,
  ShieldCheck,
  BrainCircuit,
  AlertCircle
} from 'lucide-react';
import { FormData, INITIAL_FORM_DATA, UserRole, TreatmentStage } from '../types';
import { StepContainer } from './StepContainer';
import { analyzePatientProfile } from '../services/gemini';

interface RegistrationFlowProps {
  onComplete: (data: FormData) => void;
}

export const RegistrationFlow: React.FC<RegistrationFlowProps> = ({ onComplete }) => {
  const [step, setStep] = useState(1);
  const [data, setData] = useState<FormData>(INITIAL_FORM_DATA);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [aiAnalysis, setAiAnalysis] = useState<string | null>(null);

  const nextStep = () => setStep(s => s + 1);
  const prevStep = () => setStep(s => s - 1);

  const updateData = (updates: Partial<FormData>) => {
    setData(prev => ({ ...prev, ...updates }));
  };

  const handleAiAnalysis = async () => {
    setIsAnalyzing(true);
    const result = await analyzePatientProfile(data);
    setAiAnalysis(result);
    setIsAnalyzing(false);
    nextStep();
  };

  // Step 1: Identity & Role
  const renderStep1 = () => (
    <StepContainer 
      title="Chào mừng bạn đến với MedIntel" 
      description="Bắt đầu hành trình chăm sóc sức khỏe cá nhân hóa của bạn."
    >
      <div className="space-y-6">
        <div>
          <label className="block text-slate-700 font-bold text-sm mb-2">Số điện thoại hoặc Email</label>
          <input 
            type="text"
            className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-slate-900 font-medium focus:ring-2 focus:ring-medblue focus:outline-none transition-all"
            placeholder="Nhập thông tin của bạn"
            value={data.emailOrPhone}
            onChange={e => updateData({ emailOrPhone: e.target.value })}
          />
        </div>

        <div className="grid grid-cols-1 gap-3">
          <p className="text-slate-700 font-bold text-sm mb-1">Bạn đăng ký cho ai?</p>
          {[
            { id: UserRole.PATIENT, label: 'Cho chính tôi', icon: User, desc: 'Tôi là bệnh nhân' },
            { id: UserRole.CAREGIVER, label: 'Cho người thân', icon: HeartHandshake, desc: 'Tôi là người chăm sóc' },
            { id: UserRole.BOTH, label: 'Cả hai', icon: Users, desc: 'Tôi chăm sóc cho cả gia đình' },
          ].map((role) => (
            <button
              key={role.id}
              onClick={() => updateData({ userRole: role.id })}
              className={`flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left ${
                data.userRole === role.id 
                  ? 'border-medblue bg-medblue/5 shadow-lg shadow-medblue/10' 
                  : 'border-slate-100 hover:border-slate-200 bg-white'
              }`}
            >
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${data.userRole === role.id ? 'bg-medblue text-white' : 'bg-slate-100 text-slate-400'}`}>
                <role.icon className="w-6 h-6" />
              </div>
              <div>
                <p className={`font-bold ${data.userRole === role.id ? 'text-medblue' : 'text-slate-900'}`}>{role.label}</p>
                <p className="text-xs text-slate-500 font-medium">{role.desc}</p>
              </div>
            </button>
          ))}
        </div>

        <button 
          disabled={!data.emailOrPhone || !data.userRole}
          onClick={nextStep}
          className="w-full py-4 bg-medblue text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-medblue/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:grayscale"
        >
          Tiếp tục <ChevronRight className="w-5 h-5" />
        </button>
      </div>
    </StepContainer>
  );

  // Step 2: User Personal Info
  const renderStep2 = () => (
    <StepContainer 
      title="Thông tin cơ bản" 
      description="Giúp chúng tôi biết cách xưng hô với bạn."
    >
      <div className="space-y-6">
        <div>
          <label className="block text-slate-700 font-bold text-sm mb-2">Họ và tên</label>
          <input 
            type="text"
            className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-slate-900 font-medium focus:ring-2 focus:ring-medblue focus:outline-none"
            placeholder="Ví dụ: Nguyễn Văn A"
            value={data.userName}
            onChange={e => updateData({ userName: e.target.value })}
          />
        </div>
        
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-slate-700 font-bold text-sm mb-2">Ngày sinh</label>
            <input 
              type="date"
              className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-slate-900 font-medium focus:ring-2 focus:ring-medblue focus:outline-none"
              value={data.userDob}
              onChange={e => updateData({ userDob: e.target.value })}
            />
          </div>
          <div>
            <label className="block text-slate-700 font-bold text-sm mb-2">Giới tính</label>
            <select 
              className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-slate-900 font-medium focus:ring-2 focus:ring-medblue focus:outline-none appearance-none"
              value={data.userGender}
              onChange={e => updateData({ userGender: e.target.value })}
            >
              <option value="">Chọn</option>
              <option value="Nam">Nam</option>
              <option value="Nữ">Nữ</option>
              <option value="Khác">Khác</option>
            </select>
          </div>
        </div>

        <div className="flex gap-3 pt-4">
          <button onClick={prevStep} className="flex-1 py-4 border-2 border-slate-100 text-slate-400 font-bold rounded-2xl">Quay lại</button>
          <button 
            disabled={!data.userName || !data.userDob || !data.userGender}
            onClick={nextStep}
            className="flex-[2] py-4 bg-medblue text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-medblue/20 active:scale-[0.98] transition-all disabled:opacity-50"
          >
            Tiếp tục <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </StepContainer>
  );

  // Step 3: Clinical Background
  const renderStep3 = () => (
    <StepContainer 
      title="Hồ sơ bệnh lý" 
      description="Thông tin này giúp AI phân tích nguy cơ tuân thủ điều trị."
    >
      <div className="space-y-6">
        <div>
          <label className="block text-slate-700 font-bold text-sm mb-2">Bệnh lý chính</label>
          <input 
            type="text"
            className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-slate-900 font-medium focus:ring-2 focus:ring-medblue focus:outline-none"
            placeholder="Ví dụ: Tăng huyết áp, Tiểu đường..."
            value={data.mainDisease}
            onChange={e => updateData({ mainDisease: e.target.value })}
          />
        </div>

        <div>
          <label className="block text-slate-700 font-bold text-sm mb-2">Giai đoạn điều trị</label>
          <div className="grid grid-cols-1 gap-2">
            {[
              { id: TreatmentStage.NEW, label: 'Mới chẩn đoán', desc: 'Dưới 3 tháng' },
              { id: TreatmentStage.MAINTENANCE, label: 'Đang duy trì', desc: 'Đã ổn định' },
              { id: TreatmentStage.LONG_TERM, label: 'Điều trị dài hạn', desc: 'Trên 1 năm' },
            ].map((stage) => (
              <button
                key={stage.id}
                onClick={() => updateData({ treatmentStage: stage.id })}
                className={`p-4 rounded-2xl border-2 text-left transition-all ${
                  data.treatmentStage === stage.id ? 'border-medblue bg-medblue/5' : 'border-slate-100'
                }`}
              >
                <p className={`font-bold text-sm ${data.treatmentStage === stage.id ? 'text-medblue' : 'text-slate-900'}`}>{stage.label}</p>
                <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">{stage.desc}</p>
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="block text-slate-700 font-bold text-sm mb-2">Bạn có thường quên uống thuốc không?</label>
          <div className="flex flex-wrap gap-2">
            {['Hiếm khi', 'Thỉnh thoảng', 'Thường xuyên', 'Rất hay quên'].map(freq => (
              <button
                key={freq}
                onClick={() => updateData({ forgotFrequency: freq })}
                className={`px-4 py-2 rounded-full text-xs font-bold border-2 transition-all ${
                  data.forgotFrequency === freq ? 'border-medorange bg-medorange/5 text-medorange' : 'border-slate-100 text-slate-500'
                }`}
              >
                {freq}
              </button>
            ))}
          </div>
        </div>

        <div className="flex gap-3 pt-4">
          <button onClick={prevStep} className="flex-1 py-4 border-2 border-slate-100 text-slate-400 font-bold rounded-2xl">Quay lại</button>
          <button 
            disabled={!data.mainDisease || !data.treatmentStage || !data.forgotFrequency}
            onClick={handleAiAnalysis}
            className="flex-[2] py-4 bg-medblue text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-medblue/20 active:scale-[0.98] transition-all disabled:opacity-50"
          >
            Phân tích bằng AI <Sparkles className="w-5 h-5 fill-white/20" />
          </button>
        </div>
      </div>
    </StepContainer>
  );

  // Step 4: AI Loading & Summary
  const renderStep4 = () => (
    <div className="w-full max-w-xl mx-auto">
      {isAnalyzing ? (
        <div className="bg-white rounded-[2.5rem] p-12 text-center space-y-8 shadow-2xl shadow-sky-100/40 border border-slate-100">
          <div className="relative w-24 h-24 mx-auto">
             <div className="absolute inset-0 bg-medblue/20 rounded-full animate-ping"></div>
             <div className="relative w-full h-full bg-medblue rounded-full flex items-center justify-center shadow-lg shadow-medblue/30">
                <BrainCircuit className="w-10 h-10 text-white animate-pulse" />
             </div>
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 mb-2">Đang phân tích dữ liệu...</h2>
            <p className="text-slate-500 font-medium">AI đang xây dựng chiến lược tuân thủ cá nhân hóa cho bạn.</p>
          </div>
          <div className="space-y-3 px-8">
             {[1, 2, 3].map(i => (
               <div key={i} className="h-2 bg-slate-100 rounded-full overflow-hidden">
                  <div className={`h-full bg-medblue/40 rounded-full animate-pulse`} style={{ width: `${30 * i}%`, animationDelay: `${i * 200}ms` }}></div>
               </div>
             ))}
          </div>
        </div>
      ) : (
        <div className="bg-white rounded-[2.5rem] p-8 md:p-12 shadow-2xl shadow-sky-100/40 border border-slate-100 animate-in fade-in zoom-in-95 duration-500 overflow-hidden relative">
          <div className="absolute top-0 right-0 p-8 opacity-5">
            <Sparkles className="w-32 h-32 text-medblue" />
          </div>

          <div className="flex items-center gap-3 mb-8">
            <div className="w-10 h-10 bg-medorange/10 rounded-xl flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-medorange" />
            </div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">Chiến lược từ MedIntel AI</h2>
          </div>

          <div className="bg-slate-50 rounded-3xl p-6 border border-slate-100 mb-8 max-h-[400px] overflow-y-auto no-scrollbar prose prose-slate">
            <div className="whitespace-pre-wrap text-slate-600 font-medium leading-relaxed text-sm">
              {aiAnalysis || "Hệ thống đang gặp sự cố nhỏ khi phân tích. Bạn vẫn có thể bắt đầu sử dụng ứng dụng ngay."}
            </div>
          </div>

          <div className="space-y-4">
             <div className="flex items-start gap-3 p-4 bg-emerald-50 rounded-2xl border border-emerald-100">
                <ShieldCheck className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" />
                <p className="text-xs text-emerald-700 font-bold leading-tight">Mọi dữ liệu của bạn được mã hóa và bảo mật tuyệt đối theo tiêu chuẩn y tế.</p>
             </div>
             
             <button 
                onClick={() => onComplete(data)}
                className="w-full py-5 bg-slate-900 text-white rounded-2xl font-black text-lg flex items-center justify-center gap-3 shadow-xl shadow-slate-900/20 active:scale-[0.98] transition-all"
              >
                Bắt đầu ngay <ChevronRight className="w-6 h-6" />
              </button>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <div className="fixed inset-0 z-[1000] bg-[#f8fafc] flex flex-col items-center justify-center p-6 overflow-y-auto">
      {/* Progress Bar */}
      <div className="w-full max-w-xl mb-8 flex items-center gap-2">
         {[1, 2, 3, 4].map(s => (
           <div 
             key={s} 
             className={`h-1.5 flex-1 rounded-full transition-all duration-500 ${step >= s ? 'bg-medblue' : 'bg-slate-200'}`}
           ></div>
         ))}
      </div>

      {step === 1 && renderStep1()}
      {step === 2 && renderStep2()}
      {step === 3 && renderStep3()}
      {step === 4 && renderStep4()}
      
      <p className="mt-8 text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em]">MedIntel Personalization Flow</p>
    </div>
  );
};
