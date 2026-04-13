
import React, { useState } from 'react';
import { FormData, INITIAL_FORM_DATA } from './types';
import { Dashboard } from './components/Dashboard';

const App: React.FC = () => {
  // Initialize with default data, bypassing registration
  const [formData] = useState<FormData>(INITIAL_FORM_DATA);

  return (
    <div className="min-h-screen bg-black select-none text-white overflow-hidden">
      <Dashboard formData={formData} />
    </div>
  );
};

export default App;
