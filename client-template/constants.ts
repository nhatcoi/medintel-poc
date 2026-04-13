
import { 
  Activity, Droplets, Heart, Thermometer, Scale, Ruler, Percent,
  Stethoscope, TestTube, Pill, Image as ImageIcon, TrendingUp, FileText,
  Tablet, Syringe, GlassWater, Footprints, Moon, Brain, Apple,
  ShowerHead, BookOpen, Users, Briefcase, Gamepad2, Sparkles, Sun, Star, Zap, Music, Coffee
} from 'lucide-react';
import { MetricConfig, MetricType, HabitCategory } from './types';

export const HEALTH_METRICS_CONFIG: Record<MetricType, MetricConfig> = {
  bp: {
    id: 'bp',
    label: 'Huyết áp',
    unit: 'mmHg',
    icon: Activity,
    color: 'text-red-400',
    bgColor: 'bg-red-500/10',
    inputs: [
      { key: 'systolic', label: 'Tâm thu (Sys)', placeholder: '120' },
      { key: 'diastolic', label: 'Tâm trương (Dia)', placeholder: '80' }
    ]
  },
  glucose: {
    id: 'glucose',
    label: 'Đường huyết',
    unit: 'mmol/L',
    icon: Droplets,
    color: 'text-cyan-400',
    bgColor: 'bg-cyan-500/10',
    inputs: [
      { key: 'value', label: 'Chỉ số', placeholder: '5.5' }
    ],
    tags: ['Trước ăn', 'Sau ăn', 'Lúc đói']
  },
  heart_rate: {
    id: 'heart_rate',
    label: 'Nhịp tim',
    unit: 'bpm',
    icon: Heart,
    color: 'text-rose-500',
    bgColor: 'bg-rose-500/10',
    inputs: [
      { key: 'value', label: 'Nhịp/phút', placeholder: '75' }
    ]
  },
  temp: {
    id: 'temp',
    label: 'Nhiệt độ',
    unit: '°C',
    icon: Thermometer,
    color: 'text-orange-400',
    bgColor: 'bg-orange-500/10',
    inputs: [
      { key: 'value', label: 'Nhiệt độ', placeholder: '37.0' }
    ]
  },
  weight: {
    id: 'weight',
    label: 'Cân nặng',
    unit: 'kg',
    icon: Scale,
    color: 'text-indigo-400',
    bgColor: 'bg-indigo-500/10',
    inputs: [
      { key: 'value', label: 'Cân nặng', placeholder: '65.5' }
    ]
  },
  height: {
    id: 'height',
    label: 'Chiều cao',
    unit: 'cm',
    icon: Ruler,
    color: 'text-blue-400',
    bgColor: 'bg-blue-500/10',
    inputs: [
      { key: 'value', label: 'Chiều cao', placeholder: '170' }
    ]
  },
  bmi: {
    id: 'bmi',
    label: 'BMI',
    unit: 'kg/m²',
    icon: Activity,
    color: 'text-emerald-400',
    bgColor: 'bg-emerald-500/10',
    inputs: [
      { key: 'value', label: 'Chỉ số BMI', placeholder: '22.5' }
    ]
  },
  body_fat: {
    id: 'body_fat',
    label: '% Mỡ cơ thể',
    unit: '%',
    icon: Percent,
    color: 'text-yellow-400',
    bgColor: 'bg-yellow-500/10',
    inputs: [
      { key: 'value', label: 'Tỷ lệ mỡ', placeholder: '18.5' }
    ]
  }
};

// Map string keys to Lucide components for storage/retrieval
export const HABIT_ICONS_MAP: Record<string, any> = {
    'apple': Apple,
    'footprints': Footprints,
    'moon': Moon,
    'brain': Brain,
    'pill': Pill,
    'shower': ShowerHead,
    'book': BookOpen,
    'users': Users,
    'briefcase': Briefcase,
    'gamepad': Gamepad2,
    'sparkles': Sparkles,
    'sun': Sun,
    'star': Star,
    'zap': Zap,
    'music': Music,
    'coffee': Coffee,
    'droplets': Droplets
};

export const HABIT_CATEGORIES_CONFIG: Record<HabitCategory, { label: string, icon: any, color: string, bg: string, defaultIconKey: string }> = {
  nutrition: { label: 'Dinh dưỡng', icon: Apple, color: 'text-green-400', bg: 'bg-green-500/10', defaultIconKey: 'apple' },
  movement: { label: 'Vận động', icon: Footprints, color: 'text-orange-400', bg: 'bg-orange-500/10', defaultIconKey: 'footprints' },
  sleep: { label: 'Giấc ngủ', icon: Moon, color: 'text-indigo-400', bg: 'bg-indigo-500/10', defaultIconKey: 'moon' },
  mind: { label: 'Tâm trí', icon: Brain, color: 'text-purple-400', bg: 'bg-purple-500/10', defaultIconKey: 'brain' },
  hygiene: { label: 'Vệ sinh', icon: ShowerHead, color: 'text-cyan-400', bg: 'bg-cyan-500/10', defaultIconKey: 'shower' },
  learning: { label: 'Học tập', icon: BookOpen, color: 'text-yellow-400', bg: 'bg-yellow-500/10', defaultIconKey: 'book' },
  social: { label: 'Xã hội', icon: Users, color: 'text-pink-400', bg: 'bg-pink-500/10', defaultIconKey: 'users' },
  work: { label: 'Công việc', icon: Briefcase, color: 'text-slate-400', bg: 'bg-slate-500/10', defaultIconKey: 'briefcase' },
  leisure: { label: 'Giải trí', icon: Gamepad2, color: 'text-rose-400', bg: 'bg-rose-500/10', defaultIconKey: 'gamepad' },
  custom: { label: 'Tùy chỉnh', icon: Sparkles, color: 'text-white', bg: 'bg-white/10', defaultIconKey: 'sparkles' },
  medication: { label: 'Thuốc', icon: Pill, color: 'text-blue-400', bg: 'bg-blue-500/10', defaultIconKey: 'pill' }
};

export const COLOR_PALETTE = [
  { name: 'Red', hex: '#f87171', class: 'text-red-400', bg: 'bg-red-500/10' },
  { name: 'Rose', hex: '#fb7185', class: 'text-rose-400', bg: 'bg-rose-500/10' },
  { name: 'Orange', hex: '#fb923c', class: 'text-orange-400', bg: 'bg-orange-500/10' },
  { name: 'Yellow', hex: '#facc15', class: 'text-yellow-400', bg: 'bg-yellow-500/10' },
  { name: 'Green', hex: '#34d399', class: 'text-emerald-400', bg: 'bg-emerald-500/10' },
  { name: 'Cyan', hex: '#22d3ee', class: 'text-cyan-400', bg: 'bg-cyan-500/10' },
  { name: 'Blue', hex: '#60a5fa', class: 'text-blue-400', bg: 'bg-blue-500/10' },
  { name: 'Indigo', hex: '#818cf8', class: 'text-indigo-400', bg: 'bg-indigo-500/10' },
  { name: 'Purple', hex: '#c084fc', class: 'text-purple-400', bg: 'bg-purple-500/10' },
  { name: 'Pink', hex: '#f472b6', class: 'text-pink-400', bg: 'bg-pink-500/10' },
  { name: 'Slate', hex: '#94a3b8', class: 'text-slate-400', bg: 'bg-slate-500/10' },
];

export const DOSSIER_TYPES: Record<string, { label: string, icon: any, color: string, bg: string }> = {
    'Exam': { label: 'Khám bệnh', icon: Stethoscope, color: 'text-blue-400', bg: 'bg-blue-500/10' },
    'Lab': { label: 'Xét nghiệm', icon: TestTube, color: 'text-purple-400', bg: 'bg-purple-500/10' },
    'Rx': { label: 'Đơn thuốc', icon: Pill, color: 'text-green-400', bg: 'bg-green-500/10' },
    'Image': { label: 'Chẩn đoán hình ảnh', icon: ImageIcon, color: 'text-orange-400', bg: 'bg-orange-500/10' },
    'Progression': { label: 'Diễn biến bệnh', icon: TrendingUp, color: 'text-pink-400', bg: 'bg-pink-500/10' },
    'Cert': { label: 'Giấy tờ khác', icon: FileText, color: 'text-gray-400', bg: 'bg-gray-500/10' },
};

export const MEDICATION_ICONS: Record<string, any> = {
  'pill': Pill,
  'tablet': Tablet,
  'syrup': Droplets,
  'injection': Syringe
};

export const DOSAGE_UNITS = {
  forms: ['viên', 'ống', 'gói', 'chai/lọ', 'miếng'],
  mass: ['µg', 'mg', 'g'],
  volume: ['ml', 'l'],
  concentration: ['mg/ml', '%', 'IU']
};
