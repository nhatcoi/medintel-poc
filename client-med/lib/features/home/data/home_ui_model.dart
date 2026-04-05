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
