
import { LucideIcon } from 'lucide-react';

export enum UserRole {
  PATIENT = 'PATIENT',
  CAREGIVER = 'CAREGIVER',
  BOTH = 'BOTH'
}

export enum TreatmentStage {
  NEW = 'NEW',
  MAINTENANCE = 'MAINTENANCE',
  LONG_TERM = 'LONG_TERM'
}

export interface Medication {
  name: string;
  dosage: string;
  dosageUnit?: string;
  frequency: string; // e.g., "Daily", "Every X days"
  frequencyType?: 'daily' | 'interval' | 'specific_days';
  interval?: number; // for "Every X days"
  specificDays?: number[]; // 0-6 for Sun-Sat
  timeOfDay: string[];
  direction?: string; // e.g., "Before meal", "After meal"
  expectedDuration: string;
  startDate?: string;
  color?: string;
  icon?: string;
  reminder?: boolean;
  notes?: string;
  photoUrl?: string;
}

export interface MedicationHistoryLog {
  taken: boolean;
  skipped: boolean;
  takenAt?: string;
}

export interface ExtendedMedication extends Medication {
  id?: string;      // Unique ID for this specific dose instance
  groupId?: string; // ID linking all doses of the same medication definition
  prescriptionId?: string; // ID/Name of the prescription group
  taken?: boolean;
  skipped?: boolean;
  takenAt?: string;
  history?: Record<string, MedicationHistoryLog>; // Key: YYYY-MM-DD
}

export interface DrugReference {
  id: string;
  name: string;           // Tên biệt dược (VD: Panadol)
  ingredient: string;     // Hoạt chất (VD: Paracetamol)
  group: string;          // Nhóm dược lý
  usage: string;          // Chỉ định/Công dụng
  dosage: string;         // Liều dùng tham khảo
  contraindication: string; // Chống chỉ định
  sideEffect: string;     // Tác dụng phụ
  warning: string;        // Thận trọng
  iconType: 'pill' | 'tablet' | 'syrup' | 'injection';
}

export interface Member {
  id: string;
  name: string;
  avatar: string;
  gender?: string;
  dob?: string;
  meds: ExtendedMedication[];
}

export type MetricType = 'bp' | 'glucose' | 'heart_rate' | 'temp' | 'weight' | 'height' | 'bmi' | 'body_fat';

export interface MetricConfig {
  id: MetricType;
  label: string;
  unit: string;
  icon: LucideIcon; // Changed from React.ElementType for stricter typing
  color: string;
  bgColor: string;
  inputs: {
    key: string;
    label: string;
    placeholder?: string;
  }[];
  tags?: string[];
}

export interface HealthLog {
  id: string;
  memberId: string;
  type: MetricType;
  values: Record<string, string>;
  tag?: string;
  timestamp: string;
  note?: string;
}

// --- HABITS DOMAIN ---

export type HabitCategory = 
  | 'nutrition' 
  | 'movement' 
  | 'mind' 
  | 'sleep' 
  | 'medication' 
  | 'hygiene' 
  | 'learning' 
  | 'social' 
  | 'work' 
  | 'leisure'
  | 'custom';

export interface HealthHabit {
  id: string;
  memberId: string;
  name: string;
  category: HabitCategory;
  targetValue: number;
  unit: string;
  frequency: string; // 'daily'
  reminders: string[];
  icon?: string; // key from HABIT_ICONS_MAP
  color?: string;
}

export interface HabitLog {
    id: string;
    habitId: string;
    date: string; // YYYY-MM-DD
    value: number; // current progress amount
    timestamp?: string; // ISO String for specific time log
    completed: boolean;
}

export interface Dossier {
    id: string;
    title: string;
    date: string;
    type: string;
    hospital?: string;
    doctor?: string;
    details?: string;
    images?: string[];
}

export interface FormData {
  // Phase 1: Identity
  emailOrPhone: string;
  password?: string;
  
  // Phase 2: User Profile
  userRole: UserRole | null;
  userName: string;
  userDob: string;
  userGender: string;
  caregiverRelationship?: string;

  // Phase 3: Patient Profile
  patientAge: string;
  patientGender: string;
  patientWeight: string;
  patientHeight: string;
  patientCity: string;
  mainDisease: string;
  diseaseDuration: string;
  coMorbidities: string[];
  treatmentStage: TreatmentStage | null;
  medications: Medication[];

  // Phase 4: Behavior
  forgotFrequency: string;
  forgotReasons: string[];
  hasHelper: boolean;
  smartphoneUsage: string;
  mostForgottenTime: string;

  // Phase 5: Consent
  personalizationConsent: boolean;
  aiAnalysisConsent: boolean;
  commercialOptOut: boolean;

  // Phase 6: Notifications
  notifyPush: boolean;
  notifySound: boolean;
  notifyCaregiver: boolean;
}

export const INITIAL_FORM_DATA: FormData = {
  emailOrPhone: '',
  userRole: null,
  userName: '',
  userDob: '',
  userGender: '',
  patientAge: '',
  patientGender: '',
  patientWeight: '',
  patientHeight: '',
  patientCity: '',
  mainDisease: '',
  diseaseDuration: '',
  coMorbidities: [],
  treatmentStage: null,
  medications: [],
  forgotFrequency: '',
  forgotReasons: [],
  hasHelper: false,
  smartphoneUsage: '',
  mostForgottenTime: '',
  personalizationConsent: false,
  aiAnalysisConsent: false,
  commercialOptOut: true,
  notifyPush: true,
  notifySound: true,
  notifyCaregiver: false,
};
