enum AdherenceStatus { taken, skipped, late, unknown }

class AdherenceLogModel {
  const AdherenceLogModel({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    this.status = AdherenceStatus.unknown,
  });

  final String id;
  final String medicationId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final AdherenceStatus status;
}
