
import React from 'react';

interface StepContainerProps {
  title: string;
  description?: string;
  children: React.ReactNode;
}

export const StepContainer: React.FC<StepContainerProps> = ({ title, description, children }) => {
  return (
    <div className="w-full max-w-xl mx-auto bg-white rounded-[2.5rem] shadow-2xl shadow-sky-100/40 p-8 md:p-12 border border-slate-100 transition-all animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="mb-10">
        <h2 className="text-3xl font-extrabold text-slate-900 tracking-tight mb-3">{title}</h2>
        {description && <p className="text-slate-500 font-medium leading-relaxed">{description}</p>}
        <div className="w-12 h-1.5 bg-medorange mt-6 rounded-full opacity-80"></div>
      </div>
      <div className="space-y-6">
        {children}
      </div>
    </div>
  );
};
