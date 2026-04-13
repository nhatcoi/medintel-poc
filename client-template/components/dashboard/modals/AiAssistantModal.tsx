
import React, { useState, useRef, useEffect, useMemo } from 'react';
import { X, Send, Sparkles, User, Bot, Loader2, Pill, Activity, Camera, PlusCircle, Search, FileText } from 'lucide-react';
import { Member, HealthLog, Dossier } from '../../../types';
import { chatWithHealthAssistant } from '../../../services/gemini';

interface AiAssistantModalProps {
  onClose: () => void;
  activeMember: Member;
  healthLogs: HealthLog[];
  dossiers: Dossier[];
  onTriggerAction: (action: string) => void;
}

interface Message {
  id: string;
  role: 'user' | 'ai';
  text: string;
  action?: string; // The function name returned by AI
  timestamp: Date;
}

// --- SUB-COMPONENT FOR FORMATTED TEXT ---
const FormattedMessage = ({ text, animate = false }: { text: string, animate?: boolean }) => {
  const [visibleCount, setVisibleCount] = useState(animate ? 0 : -1);
  
  const segments = useMemo(() => {
    const parts = text.split(/(\*\*.*?\*\*)/g);
    return parts.map(part => {
        if (part.startsWith('**') && part.endsWith('**')) {
            return { type: 'bold' as const, content: part.slice(2, -2) };
        }
        return { type: 'text' as const, content: part };
    });
  }, [text]);
  
  const totalLength = segments.reduce((acc, s) => acc + s.content.length, 0);

  useEffect(() => {
      if (!animate) {
          setVisibleCount(totalLength);
          return;
      }
      if (visibleCount < totalLength) {
          const timer = setTimeout(() => {
             setVisibleCount(prev => prev + 1);
          }, 15);
          return () => clearTimeout(timer);
      }
  }, [visibleCount, animate, totalLength]);

  const limit = animate ? visibleCount : totalLength;
  let currentCount = 0;

  return (
      <span className="whitespace-pre-wrap break-words">
          {segments.map((seg, i) => {
              const start = currentCount;
              // eslint-disable-next-line @typescript-eslint/no-unused-vars
              const end = currentCount + seg.content.length;
              currentCount += seg.content.length;

              if (limit <= start) return null;
              const sliceEnd = Math.min(seg.content.length, limit - start);
              const content = seg.content.slice(0, sliceEnd);

              if (seg.type === 'bold') {
                  return <strong key={i} className="font-bold text-white">{content}</strong>;
              }
              return <span key={i}>{content}</span>;
          })}
          {animate && limit < totalLength && (
              <span className="inline-block w-1.5 h-3.5 ml-0.5 align-middle bg-indigo-500 animate-pulse rounded-sm"></span>
          )}
      </span>
  );
};

// --- ACTION BUTTON COMPONENT ---
const ActionButton = ({ action, onClick }: { action: string, onClick: () => void }) => {
    let label = "";
    let icon = null;
    let colorClass = "";

    switch(action) {
        case 'open_add_medication':
            label = "Thêm thuốc mới";
            icon = <Pill className="w-5 h-5" />;
            colorClass = "bg-blue-500/20 text-blue-400 border-blue-500/30 hover:bg-blue-500/30";
            break;
        case 'scan_prescription':
            label = "Quét đơn thuốc";
            icon = <Camera className="w-5 h-5" />;
            colorClass = "bg-purple-500/20 text-purple-400 border-purple-500/30 hover:bg-purple-500/30";
            break;
        case 'open_add_habit':
            label = "Tạo thói quen";
            icon = <PlusCircle className="w-5 h-5" />;
            colorClass = "bg-emerald-500/20 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/30";
            break;
        case 'open_add_dossier':
            label = "Thêm hồ sơ";
            icon = <FileText className="w-5 h-5" />;
            colorClass = "bg-orange-500/20 text-orange-400 border-orange-500/30 hover:bg-orange-500/30";
            break;
        case 'open_add_tracker':
            label = "Ghi chỉ số";
            icon = <Activity className="w-5 h-5" />;
            colorClass = "bg-red-500/20 text-red-400 border-red-500/30 hover:bg-red-500/30";
            break;
        case 'open_drug_lookup':
            label = "Tra cứu thuốc";
            icon = <Search className="w-5 h-5" />;
            colorClass = "bg-cyan-500/20 text-cyan-400 border-cyan-500/30 hover:bg-cyan-500/30";
            break;
        default:
            return null;
    }

    return (
        <button 
            onClick={onClick}
            className={`mt-3 w-full flex items-center gap-3 p-3 rounded-xl border transition-all active:scale-[0.98] ${colorClass}`}
        >
            {icon}
            <span className="font-bold text-sm">{label}</span>
        </button>
    );
};


export const AiAssistantModal: React.FC<AiAssistantModalProps> = ({ 
  onClose, 
  activeMember,
  healthLogs,
  dossiers,
  onTriggerAction
}) => {
  const [messages, setMessages] = useState<Message[]>([
      {
          id: '1',
          role: 'ai',
          text: `Chào ${activeMember.name}! Mình là trợ lý MedIntel. Mình có thể giúp bạn thêm thuốc, đặt lịch nhắc nhở hoặc trả lời các câu hỏi sức khỏe.`,
          timestamp: new Date()
      }
  ]);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

  const handleSend = async () => {
      if (!inputText.trim()) return;

      const userMsg: Message = {
          id: Date.now().toString(),
          role: 'user',
          text: inputText,
          timestamp: new Date()
      };
      
      setMessages(prev => [...prev, userMsg]);
      setInputText('');
      setIsTyping(true);

      const todayStr = new Date().toISOString().split('T')[0];
      const memberLogs = healthLogs.filter(l => l.memberId === activeMember.id);

      try {
          const response = await chatWithHealthAssistant(userMsg.text, {
              member: activeMember,
              healthLogs: memberLogs,
              dossiers: dossiers,
              todayStr
          });

          const aiMsg: Message = {
              id: (Date.now() + 1).toString(),
              role: 'ai',
              text: response.text,
              action: response.action,
              timestamp: new Date()
          };
          setMessages(prev => [...prev, aiMsg]);
      } catch (error) {
          const errorMsg: Message = {
              id: (Date.now() + 1).toString(),
              role: 'ai',
              text: "Xin lỗi, mình đang gặp sự cố kết nối. Vui lòng thử lại sau.",
              timestamp: new Date()
          };
          setMessages(prev => [...prev, errorMsg]);
      } finally {
          setIsTyping(false);
      }
  };

  const handleQuickPrompt = (text: string) => {
      setInputText(text);
  };

  // Wrapper to close modal after action (optional)
  const handleActionClick = (action: string) => {
      onTriggerAction(action);
      // Optional: onClose(); if we want to close chat immediately
  };

  return (
    <div className="fixed inset-0 z-[400] flex flex-col items-center justify-end sm:justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto transition-opacity" onClick={onClose}></div>
      
      <div className="relative w-full max-w-md bg-[#0f172a] sm:rounded-[2rem] rounded-t-[2.5rem] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto border-t border-white/10 shadow-2xl h-[90vh] sm:h-[800px] overflow-hidden">
        
        {/* Header */}
        <div className="flex justify-between items-center px-6 pt-6 pb-4 bg-[#0f172a] z-10 border-b border-white/5 shadow-lg">
            <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/20">
                    <Sparkles className="w-5 h-5 text-white" />
                </div>
                <div>
                    <h3 className="text-base font-bold text-white">Trợ lý MedIntel</h3>
                    <div className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        <span className="text-[10px] text-emerald-400 font-medium">Đang hoạt động</span>
                    </div>
                </div>
            </div>
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center bg-zinc-800 rounded-full hover:bg-zinc-700 transition-colors">
                <X className="w-5 h-5 text-zinc-400" />
            </button>
        </div>

        {/* Chat Area */}
        <div className="flex-1 overflow-y-auto no-scrollbar p-4 space-y-6 bg-gradient-to-b from-[#0f172a] to-[#1e1e2e]">
            {messages.map((msg) => (
                <div key={msg.id} className={`flex items-end gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
                    {msg.role === 'ai' ? (
                        <div className="w-8 h-8 rounded-full bg-indigo-500/20 border border-indigo-500/30 flex items-center justify-center flex-shrink-0">
                            <Bot className="w-4 h-4 text-indigo-400" />
                        </div>
                    ) : (
                        <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center flex-shrink-0">
                            <User className="w-4 h-4 text-zinc-400" />
                        </div>
                    )}
                    
                    <div className={`max-w-[80%] p-4 rounded-2xl text-sm leading-relaxed shadow-md ${
                        msg.role === 'user' 
                        ? 'bg-[#00c2ff] text-white rounded-br-none' 
                        : 'bg-[#2c2c2e] text-zinc-200 border border-white/5 rounded-bl-none'
                    }`}>
                        <FormattedMessage text={msg.text} animate={msg.role === 'ai'} />
                        {msg.action && (
                            <div className="animate-in fade-in slide-in-from-bottom-2 duration-500 delay-300 fill-mode-forwards opacity-0" style={{ animationDelay: '500ms' }}>
                                <ActionButton action={msg.action} onClick={() => handleActionClick(msg.action!)} />
                            </div>
                        )}
                    </div>
                </div>
            ))}
            
            {isTyping && (
                <div className="flex items-end gap-3">
                     <div className="w-8 h-8 rounded-full bg-indigo-500/20 border border-indigo-500/30 flex items-center justify-center flex-shrink-0">
                        <Loader2 className="w-4 h-4 text-indigo-400 animate-spin" />
                    </div>
                    <div className="bg-[#2c2c2e] px-4 py-3 rounded-2xl rounded-bl-none border border-white/5">
                        <div className="flex gap-1">
                            <span className="w-1.5 h-1.5 bg-zinc-500 rounded-full animate-bounce"></span>
                            <span className="w-1.5 h-1.5 bg-zinc-500 rounded-full animate-bounce delay-100"></span>
                            <span className="w-1.5 h-1.5 bg-zinc-500 rounded-full animate-bounce delay-200"></span>
                        </div>
                    </div>
                </div>
            )}
            <div ref={messagesEndRef} />
        </div>

        {/* Suggestions & Input */}
        <div className="bg-[#1c1c1e] p-4 border-t border-white/5 z-20">
             {messages.length < 3 && (
                 <div className="flex gap-2 overflow-x-auto no-scrollbar mb-4 pb-2">
                     <button onClick={() => handleQuickPrompt("Tôi muốn thêm thuốc mới")} className="flex items-center gap-2 px-3 py-2 bg-zinc-800/50 hover:bg-zinc-800 rounded-xl border border-white/5 transition-colors whitespace-nowrap">
                         <Pill className="w-3.5 h-3.5 text-orange-400" />
                         <span className="text-xs text-zinc-300 font-medium">Thêm thuốc</span>
                     </button>
                     <button onClick={() => handleQuickPrompt("Quét đơn thuốc cho tôi")} className="flex items-center gap-2 px-3 py-2 bg-zinc-800/50 hover:bg-zinc-800 rounded-xl border border-white/5 transition-colors whitespace-nowrap">
                         <Camera className="w-3.5 h-3.5 text-purple-400" />
                         <span className="text-xs text-zinc-300 font-medium">Quét đơn</span>
                     </button>
                 </div>
             )}

             <div className="flex items-center gap-3">
                 <input 
                    type="text" 
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                    placeholder="Hỏi MedIntel..." 
                    className="flex-1 bg-zinc-900 text-white rounded-xl px-4 py-3.5 focus:outline-none focus:ring-1 focus:ring-indigo-500/50 border border-zinc-800 placeholder:text-zinc-600"
                 />
                 <button 
                    onClick={handleSend}
                    disabled={!inputText.trim() || isTyping}
                    className="w-12 h-12 rounded-xl bg-indigo-600 hover:bg-indigo-500 flex items-center justify-center text-white disabled:opacity-50 disabled:grayscale transition-all active:scale-95 shadow-lg shadow-indigo-600/20"
                 >
                     <Send className="w-5 h-5" />
                 </button>
             </div>
        </div>
      </div>
    </div>
  );
};
