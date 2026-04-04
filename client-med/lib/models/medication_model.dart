class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.prescriptionId,
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
  });

  final String id;
  final String prescriptionId;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
}
