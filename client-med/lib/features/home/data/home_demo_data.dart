import 'package:flutter/material.dart';

enum HomeDoseStatus { taken, missed, upcoming }

@immutable
class HomeDoseItem {
  const HomeDoseItem({
    required this.name,
    required this.dosageLabel,
    required this.timeLabel,
    required this.status,
    this.icon = Icons.medication_rounded,
  });

  final String name;
  final String dosageLabel;
  final String timeLabel;
  final HomeDoseStatus status;
  final IconData icon;
}

@immutable
class HomeUiModel {
  const HomeUiModel({
    required this.userName,
    required this.adherenceFraction,
    required this.dosesTaken,
    required this.dosesTotal,
    required this.nextDose,
    required this.todaySchedule,
  });

  final String userName;
  final double adherenceFraction;
  final int dosesTaken;
  final int dosesTotal;
  final HomeDoseItem? nextDose;
  final List<HomeDoseItem> todaySchedule;
}

HomeUiModel homeDemoModel() {
  const schedule = [
    HomeDoseItem(
      name: 'Lisinopril',
      dosageLabel: '10mg · Viên uống',
      timeLabel: '7:00 SA',
      status: HomeDoseStatus.taken,
      icon: Icons.medication_liquid_rounded,
    ),
    HomeDoseItem(
      name: 'Metformin',
      dosageLabel: '500mg · Viên uống',
      timeLabel: '12:00 TR',
      status: HomeDoseStatus.taken,
      icon: Icons.medication_rounded,
    ),
    HomeDoseItem(
      name: 'Atorvastatin',
      dosageLabel: '20mg · Viên uống',
      timeLabel: '6:00 CH',
      status: HomeDoseStatus.upcoming,
      icon: Icons.medication_rounded,
    ),
    HomeDoseItem(
      name: 'Amlodipine',
      dosageLabel: '5mg · Viên uống',
      timeLabel: '9:00 CH',
      status: HomeDoseStatus.upcoming,
      icon: Icons.medication_liquid_rounded,
    ),
  ];

  return const HomeUiModel(
    userName: 'Nguyễn Văn An',
    adherenceFraction: 0.5,
    dosesTaken: 2,
    dosesTotal: 4,
    nextDose: HomeDoseItem(
      name: 'Atorvastatin',
      dosageLabel: '20mg · Viên uống',
      timeLabel: '6:00 CH',
      status: HomeDoseStatus.upcoming,
      icon: Icons.medication_rounded,
    ),
    todaySchedule: schedule,
  );
}
