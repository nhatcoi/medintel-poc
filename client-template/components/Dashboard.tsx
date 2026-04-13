
import React, { useState, useMemo } from 'react';
import { FormData, Member, HealthLog, Dossier, ExtendedMedication, MetricType, HealthHabit, HabitLog, DrugReference } from '../types';
import { HEALTH_METRICS_CONFIG, COLOR_PALETTE } from '../constants';

// Tabs
import { TimelineTab } from './dashboard/tabs/TimelineTab';
import { MedicationsTab } from './dashboard/tabs/MedicationsTab';
import { TrackersTab } from './dashboard/tabs/TrackersTab';
import { DossiersTab } from './dashboard/tabs/DossiersTab';
import { ProfileTab } from './dashboard/tabs/ProfileTab';

// Refactored Components
import { Header } from './dashboard/Header';
import { BottomNav } from './dashboard/BottomNav';
import { PlusMenu } from './dashboard/PlusMenu';
import { DeleteConfirmationModal } from './dashboard/DeleteConfirmationModal';
import { HealthChartDetail } from './dashboard/HealthChartDetail';

// Modals
import { AddMedicationModal } from './dashboard/modals/AddMedicationModal';
import { AddDossierModal } from './dashboard/modals/AddDossierModal';
import { DossierDetailModal } from './dashboard/modals/DossierDetailModal';
import { MedicationActionModal } from './dashboard/modals/MedicationActionModal';
import { MedicationDetailModal } from './dashboard/modals/MedicationDetailModal';
import { AddHabitModal } from './dashboard/modals/AddHabitModal'; 
import { MedicationAddMenu } from './dashboard/modals/MedicationAddMenu'; 
import { ScanPrescriptionModal } from './dashboard/modals/ScanPrescriptionModal'; 
import { AddMemberModal } from './dashboard/modals/AddMemberModal'; 
import { HabitDetailModal } from './dashboard/modals/HabitDetailModal'; 
import { DrugLookupModal } from './dashboard/modals/DrugLookupModal'; 
import { SmartInputModal } from './dashboard/modals/SmartInputModal'; 
import { AiAssistantModal } from './dashboard/modals/AiAssistantModal'; 
import { Calendar, Clock, Sparkles } from 'lucide-react';

interface DashboardProps {
  formData: FormData;
}

type Tab = 'timeline' | 'meds' | 'trackers' | 'files' | 'profile';

export const Dashboard: React.FC<DashboardProps> = ({ formData }) => {
  const [activeTab, setActiveTab] = useState<Tab>('timeline');
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [isAddMemberOpen, setIsAddMemberOpen] = useState(false);
  const [selectedMedIndex, setSelectedMedIndex] = useState<number | null>(null);
  const [viewingCabinetMed, setViewingCabinetMed] = useState<ExtendedMedication | null>(null);
  
  // Sidebar State
  const [isPlusMenuOpen, setIsPlusMenuOpen] = useState(false);
  
  // Modal States
  const [isAddMedModalOpen, setIsAddMedModalOpen] = useState(false);
  const [isMedAddMenuOpen, setIsMedAddMenuOpen] = useState(false); 
  const [isScanPrescriptionOpen, setIsScanPrescriptionOpen] = useState(false); 
  const [isSmartInputOpen, setIsSmartInputOpen] = useState(false);
  const [isAiAssistantOpen, setIsAiAssistantOpen] = useState(false); 
  const [isAddDossierOpen, setIsAddDossierOpen] = useState(false);
  const [isTrackerInputOpen, setIsTrackerInputOpen] = useState(false);
  const [isAddHabitModalOpen, setIsAddHabitModalOpen] = useState(false); 
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);
  const [isDrugLookupOpen, setIsDrugLookupOpen] = useState(false);
  
  // Selection States
  const [viewingMetric, setViewingMetric] = useState<MetricType | null>(null);
  const [viewingDossier, setViewingDossier] = useState<Dossier | null>(null);
  const [isEditingDossier, setIsEditingDossier] = useState(false); 
  const [activeTrackerType, setActiveTrackerType] = useState<MetricType | null>(null);
  
  // Habit Selection
  const [viewingHabit, setViewingHabit] = useState<HealthHabit | null>(null);
  const [editingHabit, setEditingHabit] = useState<HealthHabit | null>(null);

  // Tracker Form State
  const [trackerValues, setTrackerValues] = useState<Record<string, string>>({});
  const [trackerTag, setTrackerTag] = useState<string | null>(null);
  const [trackerDate, setTrackerDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [trackerTime, setTrackerTime] = useState<string>(new Date().toLocaleTimeString('en-GB', {hour: '2-digit', minute:'2-digit'}));
  const [trackerNote, setTrackerNote] = useState<string>('');

  // Data States
  const [members, setMembers] = useState<Member[]>([
    {
      id: 'me',
      name: 'Tôi',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
      meds: [] 
    },
    {
      id: 'dad',
      name: 'Ba',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jack',
      meds: []
    },
    {
      id: 'mom',
      name: 'Mẹ',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka',
      meds: []
    }
  ]);

  const [healthLogs, setHealthLogs] = useState<HealthLog[]>([
    { id: '1', memberId: 'me', type: 'bp', values: { systolic: '120', diastolic: '80' }, timestamp: new Date().toISOString() },
    { id: '2', memberId: 'me', type: 'weight', values: { value: '68.5' }, timestamp: new Date(Date.now() - 86400000 * 5).toISOString() }
  ]);

  // Habits State
  const [habits, setHabits] = useState<HealthHabit[]>([
      { id: 'h1', memberId: 'me', name: 'Uống nước', category: 'nutrition', targetValue: 2000, unit: 'ml', frequency: 'daily', reminders: ['09:00', '14:00'], color: '#22d3ee' }
  ]);
  const [habitLogs, setHabitLogs] = useState<HabitLog[]>([]);

  const [dossiers, setDossiers] = useState<Dossier[]>([]);
  const [activeMemberId, setActiveMemberId] = useState('me');

  // Computed
  const activeMember = useMemo(() => members.find(m => m.id === activeMemberId) || members[0], [activeMemberId, members]);

  // CALCULATE MEDS FOR SELECTED DATE
  const medsByTime = useMemo(() => {
    const grouped: { [key: string]: ExtendedMedication[] } = {};
    const dateKey = selectedDate.toISOString().split('T')[0];
    
    activeMember.meds.forEach(med => {
      // 1. Check if Med is Scheduled for Selected Date
      let isScheduled = true;
      if (med.startDate) {
          const start = new Date(med.startDate);
          const current = new Date(dateKey);
          // Reset times for simple date comparison
          start.setHours(0,0,0,0);
          current.setHours(0,0,0,0);
          
          if (current < start) {
              isScheduled = false;
          } else if (med.frequencyType === 'interval' && med.interval) {
              const diffTime = Math.abs(current.getTime() - start.getTime());
              const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
              if (diffDays % med.interval !== 0) isScheduled = false;
          } else if (med.frequencyType === 'specific_days' && med.specificDays) {
              if (!med.specificDays.includes(current.getDay())) isScheduled = false;
          }
      } else if (!med.timeOfDay || med.timeOfDay.length === 0) {
        // No schedule = Not scheduled
        isScheduled = false;
      }

      if (isScheduled) {
          // 2. Get Status from History for this Date
          const historyEntry = med.history?.[dateKey];
          
          // Create a transient view object with status for this day
          const medForDay: ExtendedMedication = {
              ...med,
              taken: historyEntry?.taken || false,
              skipped: historyEntry?.skipped || false,
              takenAt: historyEntry?.takenAt
          };

          med.timeOfDay.forEach(time => {
            if (!grouped[time]) grouped[time] = [];
            grouped[time].push(medForDay);
          });
      }
    });
    return grouped;
  }, [activeMember, selectedDate]);

  const sortedTimes = Object.keys(medsByTime).sort((a, b) => new Date('1970/01/01 ' + a).getTime() - new Date('1970/01/01 ' + b).getTime());

  // Get list of existing unique Prescription IDs (Names)
  const existingPrescriptions = useMemo(() => {
    const groups = new Set<string>();
    activeMember.meds.forEach(m => {
        if (m.prescriptionId && m.prescriptionId.trim() !== '') {
            groups.add(m.prescriptionId);
        }
    });
    return Array.from(groups).sort();
  }, [activeMember.meds]);
  
  // Get list of all medications (unique by name/group) for the cabinet selection
  const cabinetMedications = useMemo(() => {
      return activeMember.meds;
  }, [activeMember.meds]);

  // Helpers
  const getMetricStyle = (type: MetricType) => {
    const config = HEALTH_METRICS_CONFIG[type];
    const paletteColor = COLOR_PALETTE.find(c => config.color.includes(c.class.split('-')[1]));
    return {
       hex: paletteColor ? paletteColor.hex : '#ffffff',
       class: config.color,
       bg: config.bgColor
    };
  };

  const getLatestLog = (type: MetricType) => {
      const logs = healthLogs.filter(log => log.memberId === activeMemberId && log.type === type)
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
      return logs[0];
  };

  // Handlers - Medication Logic
  const handleAddMedication = (med: ExtendedMedication) => {
    const groupId = Date.now().toString(); 
    
    let medInstances: ExtendedMedication[] = [];
    
    if (med.timeOfDay && med.timeOfDay.length > 0) {
        medInstances = med.timeOfDay.map((time, index) => ({
            ...med,
            id: `${groupId}-${index}`,
            groupId: groupId,
            timeOfDay: [time],
            taken: false,
            skipped: false,
            history: {}
        }));
    } else {
        medInstances = [{
            ...med,
            id: `${groupId}-0`,
            groupId: groupId,
            timeOfDay: [],
            taken: false,
            skipped: false,
            history: {}
        }];
    }

    setMembers(prev => prev.map(member => {
      if (member.id !== activeMemberId) return member;
      return { ...member, meds: [...member.meds, ...medInstances] };
    }));
    setIsAddMedModalOpen(false);
  };

  const handleAddMultipleMedications = (meds: ExtendedMedication[]) => {
     let allNewInstances: ExtendedMedication[] = [];
     
     meds.forEach(med => {
         const groupId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
         
         if (med.timeOfDay && med.timeOfDay.length > 0) {
             const instances = med.timeOfDay.map((time, index) => ({
                ...med,
                id: `${groupId}-${index}`,
                groupId: groupId,
                timeOfDay: [time],
                taken: false,
                skipped: false,
                history: {}
             }));
             allNewInstances = [...allNewInstances, ...instances];
         } else {
             const instance = {
                ...med,
                id: `${groupId}-0`,
                groupId: groupId,
                timeOfDay: [],
                taken: false,
                skipped: false,
                history: {}
             };
             allNewInstances = [...allNewInstances, instance];
         }
     });

     setMembers(prev => prev.map(member => {
        if (member.id !== activeMemberId) return member;
        return { ...member, meds: [...member.meds, ...allNewInstances] };
     }));

     setIsScanPrescriptionOpen(false);
     setIsSmartInputOpen(false); // Close Smart Input as well
  };
  
  // Add Medication from Drug Lookup
  const handleAddFromLookup = (drug: DrugReference) => {
      const newMed: ExtendedMedication = {
          name: drug.name,
          dosage: drug.dosage.split('.')[0] || '1 viên', // naive extract
          dosageUnit: 'viên',
          frequency: 'Mỗi ngày',
          frequencyType: 'daily',
          timeOfDay: ['08:00'],
          direction: 'Sau ăn',
          expectedDuration: '7 ngày',
          startDate: new Date().toISOString().split('T')[0],
          color: '#00c2ff',
          icon: drug.iconType,
          reminder: true,
          notes: `${drug.group}. ${drug.usage}`,
          taken: false
      };
      handleAddMedication(newMed);
      setIsDrugLookupOpen(false);
      setActiveTab('meds');
  };

  const handleMedicationAction = (action: 'take' | 'skip' | 'untake') => {
    if (selectedMedIndex === null) return;
    const now = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false });
    const dateKey = selectedDate.toISOString().split('T')[0];
    
    const updates: Partial<ExtendedMedication> = {};
    const historyUpdate = { taken: false, skipped: false, takenAt: undefined as string | undefined };

    if (action === 'take') {
        historyUpdate.taken = true;
        historyUpdate.takenAt = `${now}`;
        if (new Date().toDateString() === selectedDate.toDateString()) {
            updates.taken = true;
            updates.skipped = false;
            updates.takenAt = `${now}, hôm nay`;
        }
    } else if (action === 'skip') {
        historyUpdate.skipped = true;
        if (new Date().toDateString() === selectedDate.toDateString()) {
            updates.taken = false;
            updates.skipped = true;
            updates.takenAt = undefined;
        }
    } else { 
        if (new Date().toDateString() === selectedDate.toDateString()) {
            updates.taken = false;
            updates.skipped = false;
            updates.takenAt = undefined;
        }
    }

    setMembers(prev => prev.map(m => {
        if (m.id !== activeMemberId) return m;
        const newMeds = [...m.meds];
        const medToUpdate = newMeds[selectedMedIndex];
        
        const newHistory = { ...(medToUpdate.history || {}) };
        if (action === 'untake') {
            delete newHistory[dateKey];
        } else {
            newHistory[dateKey] = historyUpdate;
        }

        newMeds[selectedMedIndex] = { ...medToUpdate, ...updates, history: newHistory };
        return { ...m, meds: newMeds };
    }));
    
    setSelectedMedIndex(null);
  };

  const handleMedicationUpdate = (updatedMed: ExtendedMedication, scope: 'single' | 'all') => {
    if (selectedMedIndex === null) return;
    setMembers(prev => prev.map(m => {
        if (m.id !== activeMemberId) return m;
        let newMeds = [...m.meds];
        if (scope === 'single') {
            newMeds[selectedMedIndex] = updatedMed;
        } else {
            const targetGroupId = newMeds[selectedMedIndex].groupId;
            if (targetGroupId) {
                newMeds = newMeds.map(med => {
                    if (med.groupId === targetGroupId) {
                        return { ...med, ...updatedMed, timeOfDay: med.timeOfDay };
                    }
                    return med;
                });
            } else {
                newMeds[selectedMedIndex] = updatedMed;
            }
        }
        return { ...m, meds: newMeds };
    }));
  };

  const handleCabinetUpdate = (oldMed: ExtendedMedication, newMedDefinition: ExtendedMedication) => {
     const groupId = oldMed.groupId;
     if (!groupId) return; 

     // Handle schedule changes:
     const oldTimes = activeMember.meds.filter(m => m.groupId === groupId).map(m => m.timeOfDay[0]).filter(Boolean).sort();
     const newTimes = newMedDefinition.timeOfDay.sort();
     
     // Detect if schedule changed (or if it went from no-schedule to scheduled, or vice-versa)
     const scheduleChanged = JSON.stringify(oldTimes) !== JSON.stringify(newTimes);

     setMembers(prev => prev.map(m => {
        if (m.id !== activeMemberId) return m;
        if (scheduleChanged) {
            // Remove old instances
            const filteredMeds = m.meds.filter(med => med.groupId !== groupId);
            
            let newInstances: ExtendedMedication[] = [];
            
            if (newTimes.length > 0) {
                 newInstances = newTimes.map((time, index) => ({
                    ...newMedDefinition,
                    id: `${groupId}-${index}`,
                    groupId: groupId,
                    timeOfDay: [time],
                    taken: false,
                    skipped: false,
                    history: {} 
                }));
            } else {
                 // No times -> Cabinet only single instance
                 newInstances = [{
                    ...newMedDefinition,
                    id: `${groupId}-0`,
                    groupId: groupId,
                    timeOfDay: [],
                    taken: false,
                    skipped: false,
                    history: {}
                 }];
            }
            
            return { ...m, meds: [...filteredMeds, ...newInstances] };
        } else {
            // Update properties of existing instances
            const updatedMeds = m.meds.map(med => {
                if (med.groupId === groupId) {
                    return { ...med, ...newMedDefinition, timeOfDay: med.timeOfDay };
                }
                return med;
            });
            return { ...m, meds: updatedMeds };
        }
     }));
  };

  const handleCabinetDelete = (groupId: string) => {
      setMembers(prev => prev.map(m => {
          if (m.id !== activeMemberId) return m;
          return { ...m, meds: m.meds.filter(med => med.groupId !== groupId) };
      }));
      setViewingCabinetMed(null);
  };

  const handleMedicationDelete = () => {
    if (selectedMedIndex === null) return;
    setMembers(prev => prev.map(m => {
        if (m.id !== activeMemberId) return m;
        return { ...m, meds: m.meds.filter((_, i) => i !== selectedMedIndex) };
    }));
    setSelectedMedIndex(null);
  };
  
  // Member Handler
  const handleAddMember = (name: string, avatar: string) => {
      const newMember: Member = {
        id: Date.now().toString(),
        name,
        avatar,
        meds: []
      };
      setMembers(prev => [...prev, newMember]);
      setActiveMemberId(newMember.id);
      setIsAddMemberOpen(false);
  };

  // Dossier Handlers
  const handleSaveDossier = (newDossier: Dossier) => {
      setDossiers(prev => [newDossier, ...prev]);
      setIsAddDossierOpen(false);
  };

  const handleUpdateDossier = (updatedDossier: Dossier) => {
    setDossiers(prev => prev.map(d => d.id === updatedDossier.id ? updatedDossier : d));
    setViewingDossier(updatedDossier); 
  };

  const handleDeleteDossier = () => {
    if (!viewingDossier) return;
    setDossiers(prev => prev.filter(d => d.id !== viewingDossier.id));
    setViewingDossier(null);
    setIsDeleteConfirmOpen(false);
  };

  // Tracker Handlers
  const openTrackerModal = (type: MetricType) => {
    setActiveTrackerType(type);
    setTrackerValues({});
    setTrackerTag(null);
    setTrackerDate(new Date().toISOString().split('T')[0]);
    setTrackerTime(new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }));
    setTrackerNote('');
    setIsTrackerInputOpen(true);
    setIsPlusMenuOpen(false);
  };

  const handleSaveTracker = () => {
    if (!activeTrackerType) return;
    
    const config = HEALTH_METRICS_CONFIG[activeTrackerType];
    const isValid = config.inputs.every(i => trackerValues[i.key] && trackerValues[i.key].trim() !== '');
    
    if (!isValid) return; 

    const newLog: HealthLog = {
      id: Date.now().toString(),
      memberId: activeMemberId,
      type: activeTrackerType,
      values: trackerValues,
      tag: trackerTag || undefined,
      timestamp: `${trackerDate}T${trackerTime}`,
      note: trackerNote
    };

    setHealthLogs(prev => [newLog, ...prev]);
    setIsTrackerInputOpen(false);
  };

  // Habit Handlers
  const handleSaveHabit = (newHabit: HealthHabit) => {
      if (editingHabit) {
        setHabits(prev => prev.map(h => h.id === newHabit.id ? { ...newHabit, memberId: activeMemberId } : h));
        setEditingHabit(null);
        // If we were viewing this habit, update the view
        if (viewingHabit && viewingHabit.id === newHabit.id) {
            setViewingHabit(newHabit);
        }
      } else {
        setHabits(prev => [...prev, { ...newHabit, memberId: activeMemberId }]);
      }
      setIsAddHabitModalOpen(false);
  };

  const handleDeleteHabit = (id: string) => {
     setHabits(prev => prev.filter(h => h.id !== id));
     setHabitLogs(prev => prev.filter(l => l.habitId !== id));
     setIsAddHabitModalOpen(false);
     setViewingHabit(null);
     setEditingHabit(null);
  };

  const handleLogHabit = (habitId: string, value: number) => {
      const now = new Date();
      const dateKey = selectedDate.toISOString().split('T')[0];
      // Only log timestamp if today, otherwise just the date
      const timestamp = new Date().toDateString() === selectedDate.toDateString() 
          ? now.toISOString() 
          : `${dateKey}T12:00:00.000Z`;

      const newLog: HabitLog = {
          id: Date.now().toString(),
          habitId,
          date: dateKey,
          value,
          timestamp,
          completed: false 
      };
      setHabitLogs(prev => [...prev, newLog]);
  };
  
  const handleDeleteHabitLog = (logId: string) => {
      setHabitLogs(prev => prev.filter(l => l.id !== logId));
  };

  const handleSelectMedFromCabinet = (med: ExtendedMedication) => {
     const allTimes = activeMember.meds.filter(m => m.groupId === med.groupId).map(m => m.timeOfDay[0]).sort();
     const representativeMed = { ...med, timeOfDay: allTimes.length > 0 ? allTimes : med.timeOfDay };
     setViewingCabinetMed(representativeMed);
  };

  // --- AI ACTION HANDLER ---
  const handleAiAction = (action: string) => {
      // Close the assistant modal optionally, or keep it open.
      // Here we keep it open but trigger the other modal on top.
      switch(action) {
          case 'open_add_medication':
              setIsAddMedModalOpen(true);
              setIsAiAssistantOpen(false); // Close AI to focus on task
              break;
          case 'scan_prescription':
              setIsScanPrescriptionOpen(true);
              setIsAiAssistantOpen(false);
              break;
          case 'open_add_habit':
              setEditingHabit(null);
              setIsAddHabitModalOpen(true);
              setIsAiAssistantOpen(false);
              break;
          case 'open_add_dossier':
              setIsAddDossierOpen(true);
              setIsAiAssistantOpen(false);
              break;
          case 'open_add_tracker':
              setActiveTab('trackers');
              // Optionally pick a default metric like BP
              openTrackerModal('bp'); 
              setIsAiAssistantOpen(false);
              break;
          case 'open_drug_lookup':
              setIsDrugLookupOpen(true);
              setIsAiAssistantOpen(false);
              break;
      }
  };
  
  const activeMedForModal = selectedMedIndex !== null ? (() => {
      const realMed = activeMember.meds[selectedMedIndex];
      if (!realMed) return null;
      const dateKey = selectedDate.toISOString().split('T')[0];
      const historyEntry = realMed.history?.[dateKey];
      return {
          ...realMed,
          taken: historyEntry?.taken || false,
          skipped: historyEntry?.skipped || false,
          takenAt: historyEntry?.takenAt
      };
  })() : null;

  const isAnyModalOpen = isPlusMenuOpen || isAddMedModalOpen || isMedAddMenuOpen || isAddMemberOpen || selectedMedIndex !== null || isTrackerInputOpen || viewingMetric !== null || isAddDossierOpen || viewingDossier !== null || isDeleteConfirmOpen || viewingCabinetMed !== null || isAddHabitModalOpen || isScanPrescriptionOpen || viewingHabit !== null || isDrugLookupOpen || isSmartInputOpen || isAiAssistantOpen;

  return (
    <div className="fixed inset-0 bg-black flex flex-col max-w-md mx-auto overflow-hidden shadow-2xl font-sans text-white border-x border-zinc-900">
      
      <Header 
        activeMember={activeMember} 
        setActiveTab={setActiveTab} 
        setIsPlusMenuOpen={setIsPlusMenuOpen} 
        isBlurred={!!isAnyModalOpen} 
      />

      {/* MAIN CONTENT */}
      <main className={`flex-1 bg-black p-6 space-y-8 overflow-y-auto no-scrollbar pb-32 transition-all duration-300 ${isAnyModalOpen ? 'blur-md scale-[0.98]' : ''}`}>
         {activeTab === 'timeline' && <TimelineTab {...{ members, activeMemberId, setActiveMemberId, setIsAddMemberOpen, selectedDate, setSelectedDate, medsByTime, sortedTimes, activeMember, setSelectedMedIndex }} />}
         {activeTab === 'meds' && <MedicationsTab activeMember={activeMember} onAddMedication={() => setIsMedAddMenuOpen(true)} onSelectMedication={handleSelectMedFromCabinet} />}
         {activeTab === 'trackers' && <TrackersTab {...{ healthLogs, activeMemberId, setViewingMetric, openTrackerModal, getMetricStyle, getLatestLog, habits, habitLogs, onAddHabit: () => { setEditingHabit(null); setIsAddHabitModalOpen(true); }, onLogHabit: handleLogHabit, onViewHabit: setViewingHabit, selectedDate }} />}
         {activeTab === 'files' && <DossiersTab dossiers={dossiers} setViewingDossier={setViewingDossier} setIsEditingDossier={setIsEditingDossier} setIsAddDossierOpen={setIsAddDossierOpen} resetDossierForm={() => {}} />}
         {activeTab === 'profile' && <ProfileTab {...{ activeMember, members, activeMemberId, setActiveMemberId, setIsAddMemberOpen, handleLogout: () => window.location.reload() }} />}
      </main>

      {/* GLOBAL AI FLOATING BUTTON */}
      {!isAnyModalOpen && (
          <button 
             onClick={() => setIsAiAssistantOpen(true)}
             className="absolute bottom-24 right-5 z-20 w-14 h-14 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/40 animate-in zoom-in duration-300 hover:scale-105 transition-transform"
          >
              <Sparkles className="w-6 h-6 text-white animate-pulse" />
          </button>
      )}

      <BottomNav activeTab={activeTab} setActiveTab={setActiveTab} isBlurred={!!isAnyModalOpen} />

      {/* === MODALS === */}

      {isAddMedModalOpen && (
        <AddMedicationModal 
          onClose={() => setIsAddMedModalOpen(false)} 
          onAdd={handleAddMedication} 
          existingPrescriptions={existingPrescriptions}
          cabinetMedications={cabinetMedications}
        />
      )}
      
      {/* New Selection Menu for Medications */}
      <MedicationAddMenu
        isOpen={isMedAddMenuOpen}
        onClose={() => setIsMedAddMenuOpen(false)}
        onAddManually={() => { setIsMedAddMenuOpen(false); setIsAddMedModalOpen(true); }}
        onScan={() => { setIsMedAddMenuOpen(false); setIsScanPrescriptionOpen(true); }}
        onSmartInput={() => { setIsMedAddMenuOpen(false); setIsSmartInputOpen(true); }}
      />
      
      {/* Prescription Scanning Modal */}
      {isScanPrescriptionOpen && (
          <ScanPrescriptionModal 
            onClose={() => setIsScanPrescriptionOpen(false)}
            onSave={handleAddMultipleMedications}
          />
      )}
      
      {/* Smart AI Input Modal */}
      {isSmartInputOpen && (
          <SmartInputModal
            onClose={() => setIsSmartInputOpen(false)}
            onSave={handleAddMultipleMedications}
          />
      )}
      
      {/* Drug Lookup Modal */}
      {isDrugLookupOpen && (
          <DrugLookupModal 
             onClose={() => setIsDrugLookupOpen(false)}
             onAddToCabinet={handleAddFromLookup}
          />
      )}
      
      {/* AI ASSISTANT MODAL - Wired with Actions */}
      {isAiAssistantOpen && (
          <AiAssistantModal 
             onClose={() => setIsAiAssistantOpen(false)}
             activeMember={activeMember}
             healthLogs={healthLogs}
             dossiers={dossiers}
             onTriggerAction={handleAiAction}
          />
      )}

      {isAddDossierOpen && (
        <AddDossierModal onClose={() => setIsAddDossierOpen(false)} onSave={handleSaveDossier} />
      )}

      {/* Add/Edit Habit Modal */}
      {isAddHabitModalOpen && (
        <AddHabitModal 
            onClose={() => { setIsAddHabitModalOpen(false); setEditingHabit(null); }} 
            onSave={handleSaveHabit}
            initialData={editingHabit}
            onDelete={handleDeleteHabit}
        />
      )}
      
      {/* Habit Detail Modal */}
      {viewingHabit && (
          <HabitDetailModal 
             habit={viewingHabit}
             logs={habitLogs.filter(l => l.habitId === viewingHabit.id && l.date === selectedDate.toISOString().split('T')[0])}
             onClose={() => setViewingHabit(null)}
             onDeleteLog={handleDeleteHabitLog}
             onEdit={() => { 
                 setEditingHabit(viewingHabit); 
                 setViewingHabit(null); 
                 setIsAddHabitModalOpen(true); 
             }}
          />
      )}

      {/* Add Member Modal */}
      {isAddMemberOpen && (
        <AddMemberModal onClose={() => setIsAddMemberOpen(false)} onSave={handleAddMember} />
      )}

      {activeMedForModal && (
        <MedicationActionModal 
            medication={activeMedForModal} 
            onClose={() => setSelectedMedIndex(null)}
            onAction={handleMedicationAction}
            onUpdate={handleMedicationUpdate}
            onDelete={handleMedicationDelete}
        />
      )}

      {viewingCabinetMed && (
        <MedicationDetailModal 
            medication={viewingCabinetMed}
            onClose={() => setViewingCabinetMed(null)}
            onUpdate={handleCabinetUpdate}
            onDelete={handleCabinetDelete}
        />
      )}

      <PlusMenu 
        isOpen={isPlusMenuOpen} 
        onClose={() => setIsPlusMenuOpen(false)} 
        onOpenAddMed={() => setIsAddMedModalOpen(true)}
        onOpenTrackers={() => { setActiveTab('trackers'); }}
        onOpenDrugLookup={() => setIsDrugLookupOpen(true)}
      />

      <DeleteConfirmationModal 
        isOpen={isDeleteConfirmOpen} 
        onClose={() => setIsDeleteConfirmOpen(false)} 
        onConfirm={handleDeleteDossier} 
      />

      {viewingDossier && (
        <DossierDetailModal 
          dossier={viewingDossier}
          onClose={() => setViewingDossier(null)}
          onUpdate={handleUpdateDossier}
          onDeleteRequest={() => setIsDeleteConfirmOpen(true)}
        />
      )}

      {/* Tracker Input Modal (Form) */}
      {isTrackerInputOpen && activeTrackerType && (
        <div className="fixed inset-0 z-[300] flex flex-col items-center justify-end">
            <div className="absolute inset-0 bg-black/60 pointer-events-auto" onClick={() => setIsTrackerInputOpen(false)}></div>
            <div className="relative w-full max-w-md bg-[#0f1d2a] rounded-t-[2.5rem] flex flex-col animate-in slide-in-from-bottom duration-300 pointer-events-auto h-[92vh]">
                <header className="flex justify-between items-center px-6 pt-10 pb-4">
                    <button onClick={() => setIsTrackerInputOpen(false)} className="text-zinc-400 text-base font-medium hover:text-white transition-colors">Hủy</button>
                    <h2 className="text-white text-[17px] font-bold">Thêm chỉ số</h2>
                    <button onClick={handleSaveTracker} className="text-base font-bold text-[#00c2ff] hover:text-[#00c2ff]/80 transition-colors">Lưu</button>
                </header>
                
                {(() => {
                  const config = HEALTH_METRICS_CONFIG[activeTrackerType];
                  return (
                      <div className="flex-1 overflow-y-auto no-scrollbar pb-10">
                          {/* Hero Icon */}
                          <div className="flex flex-col items-center justify-center py-8">
                              <div className={`w-24 h-24 rounded-full flex items-center justify-center mb-4 relative ${config.bgColor}`}>
                                  <config.icon className={`w-12 h-12 ${config.color}`} />
                                  <div className={`absolute inset-0 rounded-full blur-xl opacity-40 ${config.bgColor.replace('/10', '/40')}`}></div>
                              </div>
                              <h2 className="text-2xl font-bold text-white text-center">{config.label}</h2>
                              <p className="text-zinc-500 text-sm font-medium mt-1">Nhập chỉ số mới</p>
                          </div>

                          <div className="px-6 space-y-6">
                              {/* Inputs */}
                              <div className="grid grid-cols-1 gap-4">
                                  {config.inputs.map((input) => (
                                      <div key={input.key}>
                                          <label className="block text-zinc-500 font-bold text-xs mb-2 uppercase tracking-wider">{input.label}</label>
                                          <div className="relative">
                                              <input
                                                  type="number"
                                                  value={trackerValues[input.key] || ''}
                                                  onChange={(e) => setTrackerValues({...trackerValues, [input.key]: e.target.value})}
                                                  placeholder={input.placeholder}
                                                  className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-2xl font-black focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5 placeholder:text-zinc-700"
                                                  autoFocus={config.inputs.indexOf(input) === 0}
                                              />
                                              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-zinc-600 font-bold text-sm">{config.unit}</span>
                                          </div>
                                      </div>
                                  ))}
                              </div>

                              {/* Tags */}
                              {config.tags && (
                                  <div>
                                      <label className="block text-zinc-500 font-bold text-xs mb-2 uppercase tracking-wider">Thời điểm</label>
                                      <div className="flex flex-wrap gap-2">
                                          {config.tags.map(tag => (
                                              <button
                                                  key={tag}
                                                  onClick={() => setTrackerTag(tag === trackerTag ? null : tag)}
                                                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all border ${
                                                      trackerTag === tag 
                                                      ? 'bg-[#00c2ff] text-white border-[#00c2ff]' 
                                                      : 'bg-[#1c1c1e] text-zinc-400 border-white/5 hover:bg-zinc-800'
                                                  }`}
                                              >
                                                  {tag}
                                              </button>
                                          ))}
                                      </div>
                                  </div>
                              )}

                              {/* Date & Time */}
                              <div className="grid grid-cols-2 gap-4">
                                  <div>
                                      <label className="block text-zinc-500 font-bold text-xs mb-2 uppercase tracking-wider">Ngày</label>
                                      <div className="bg-[#1c1c1e] rounded-2xl p-3 border border-white/5 flex items-center">
                                          <Calendar className="w-5 h-5 text-zinc-500 mr-2" />
                                          <input 
                                              type="date"
                                              value={trackerDate}
                                              onChange={(e) => setTrackerDate(e.target.value)}
                                              className="bg-transparent text-white font-bold text-sm w-full focus:outline-none"
                                          />
                                      </div>
                                  </div>
                                  <div>
                                      <label className="block text-zinc-500 font-bold text-xs mb-2 uppercase tracking-wider">Giờ</label>
                                      <div className="bg-[#1c1c1e] rounded-2xl p-3 border border-white/5 flex items-center">
                                          <Clock className="w-5 h-5 text-zinc-500 mr-2" />
                                          <input 
                                              type="time"
                                              value={trackerTime}
                                              onChange={(e) => setTrackerTime(e.target.value)}
                                              className="bg-transparent text-white font-bold text-sm w-full focus:outline-none"
                                          />
                                      </div>
                                  </div>
                              </div>
                              
                              {/* Note */}
                              <div>
                                  <label className="block text-zinc-500 font-bold text-xs mb-2 uppercase tracking-wider">Ghi chú</label>
                                  <textarea 
                                      value={trackerNote}
                                      onChange={(e) => setTrackerNote(e.target.value)}
                                      placeholder="Thêm ghi chú..."
                                      rows={3}
                                      className="w-full bg-[#1c1c1e] text-white rounded-2xl p-4 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#00c2ff]/50 border border-white/5 resize-none placeholder:text-zinc-700"
                                  />
                              </div>
                          </div>
                      </div>
                  );
                })()}
            </div>
        </div>
      )}

      {/* Detailed Chart View (The New Component) */}
      {viewingMetric && (
          <HealthChartDetail 
            metricType={viewingMetric}
            onClose={() => setViewingMetric(null)}
            healthLogs={healthLogs}
            onAddRecord={() => openTrackerModal(viewingMetric)}
          />
      )}

    </div>
  );
};
