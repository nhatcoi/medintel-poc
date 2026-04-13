class HomeDoseSection {
  const HomeDoseSection({required this.timeLabel, required this.items});

  final String timeLabel;
  final List<HomeDoseSectionItem> items;
}

class HomeDoseSectionItem {
  const HomeDoseSectionItem({
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.status,
  });

  final String medicationId;
  final String name;
  final String? dosage;
  final String? frequency;
  final HomeDoseStatus status;
}

enum HomeDoseStatus { taken, missed, upcoming }
