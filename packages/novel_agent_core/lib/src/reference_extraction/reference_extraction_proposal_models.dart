import '../common/json_types.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../information/information_source_ref.dart';

class ReferenceExtractionProposal {
  const ReferenceExtractionProposal({
    required this.proposalId,
    required this.entryId,
    required this.entryNamespace,
    required this.entryKind,
    required this.title,
    required this.summary,
    this.payload = const <String, Object?>{},
    this.sourceRefs = const <InformationSourceRef>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.tags = const <String>[],
    this.coverageDimensionIds = const <String>[],
    this.confidence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String proposalId;
  final String entryId;
  final String entryNamespace;
  final String entryKind;
  final String title;
  final String summary;
  final JsonMap payload;
  final List<InformationSourceRef> sourceRefs;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<String> tags;
  final List<String> coverageDimensionIds;
  final double confidence;
  final JsonMap metadata;

  ReferenceExtractionProposal copyWith({
    String? proposalId,
    String? entryId,
    String? entryNamespace,
    String? entryKind,
    String? title,
    String? summary,
    JsonMap? payload,
    List<InformationSourceRef>? sourceRefs,
    List<NarrativeEvidenceRef>? evidenceRefs,
    List<String>? tags,
    List<String>? coverageDimensionIds,
    double? confidence,
    JsonMap? metadata,
  }) {
    return ReferenceExtractionProposal(
      proposalId: proposalId ?? this.proposalId,
      entryId: entryId ?? this.entryId,
      entryNamespace: entryNamespace ?? this.entryNamespace,
      entryKind: entryKind ?? this.entryKind,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      payload: payload ?? this.payload,
      sourceRefs: sourceRefs ?? this.sourceRefs,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      tags: tags ?? this.tags,
      coverageDimensionIds: coverageDimensionIds ?? this.coverageDimensionIds,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }
}
