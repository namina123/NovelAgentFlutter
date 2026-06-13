import 'information_evidence_projection_item.dart';

class InformationEvidenceProjection {
  const InformationEvidenceProjection({
    this.present = false,
    this.status = '',
    this.statusLabel = '',
    this.summary = '',
    this.subtitle = '',
    this.knowledgeCount = 0,
    this.designCount = 0,
    this.researchCount = 0,
    this.referenceCount = 0,
    this.projectionPaths = const <String>[],
    this.projectionItems = const <InformationEvidenceProjectionItem>[],
    this.userActionItems = const <InformationEvidenceProjectionItem>[],
    this.userLines = const <String>[],
    this.diagnosticLines = const <String>[],
  });

  final bool present;
  final String status;
  final String statusLabel;
  final String summary;
  final String subtitle;
  final int knowledgeCount;
  final int designCount;
  final int researchCount;
  final int referenceCount;
  final List<String> projectionPaths;
  final List<InformationEvidenceProjectionItem> projectionItems;
  final List<InformationEvidenceProjectionItem> userActionItems;
  final List<String> userLines;
  final List<String> diagnosticLines;

  bool get hasContent =>
      present || projectionItems.isNotEmpty || userActionItems.isNotEmpty;
}
