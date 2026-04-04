class PrescriptionModel {
  const PrescriptionModel({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.rawOcrText,
  });

  final String id;
  final String userId;
  final String? imageUrl;
  final String? rawOcrText;
}
