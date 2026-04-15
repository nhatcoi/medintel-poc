import '../../../services/api_service.dart';
import '../../../core/constants/api_paths.dart';

enum InteractionSeverity { high, medium, low, unknown }

InteractionSeverity _parseSeverity(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'high':
      return InteractionSeverity.high;
    case 'medium':
      return InteractionSeverity.medium;
    case 'low':
      return InteractionSeverity.low;
    default:
      return InteractionSeverity.unknown;
  }
}

class DrugInteractionEvidence {
  const DrugInteractionEvidence({
    required this.drugName,
    required this.section,
    required this.content,
    required this.similarity,
  });

  final String drugName;
  final String section;
  final String content;
  final double similarity;

  factory DrugInteractionEvidence.fromJson(Map<String, dynamic> j) =>
      DrugInteractionEvidence(
        drugName: (j['drug_name'] ?? '').toString(),
        section: (j['section'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        similarity: (j['similarity'] as num?)?.toDouble() ?? 0,
      );
}

class DrugInteractionPair {
  const DrugInteractionPair({
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.summary,
    required this.evidence,
    required this.source,
  });

  final String drugA;
  final String drugB;
  final InteractionSeverity severity;
  final String summary;
  final List<DrugInteractionEvidence> evidence;
  final String source;

  factory DrugInteractionPair.fromJson(Map<String, dynamic> j) {
    final ev = (j['evidence'] as List?)
            ?.whereType<Map>()
            .map((e) => DrugInteractionEvidence.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList() ??
        const <DrugInteractionEvidence>[];
    return DrugInteractionPair(
      drugA: (j['drug_a'] ?? '').toString(),
      drugB: (j['drug_b'] ?? '').toString(),
      severity: _parseSeverity((j['severity'] ?? 'unknown').toString()),
      summary: (j['summary'] ?? '').toString(),
      evidence: ev,
      source: (j['source'] ?? 'rag').toString(),
    );
  }
}

class DrugInteractionRepository {
  const DrugInteractionRepository(this._api);

  final ApiService _api;

  Future<List<DrugInteractionPair>> check(List<String> drugs) async {
    if (drugs.length < 2) return const [];
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.ragDrugInteractions,
      data: {'drugs': drugs},
    );
    final raw = resp.data?['interactions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DrugInteractionPair.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
