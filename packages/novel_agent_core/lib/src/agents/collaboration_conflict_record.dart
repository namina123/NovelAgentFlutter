import '../common/json_types.dart';
import '../common/value_readers.dart';

class CollaborationConflictRisks {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';

  static const Set<String> knownValues = <String>{low, medium, high};

  static String normalize(String value) {
    final normalized = value.trim().toLowerCase();
    if (knownValues.contains(normalized)) {
      return normalized;
    }
    return low;
  }

  static int rank(String value) {
    switch (normalize(value)) {
      case high:
        return 3;
      case medium:
        return 2;
      default:
        return 1;
    }
  }
}

class CollaborationConflictEvidence {
  const CollaborationConflictEvidence({
    this.kind = '',
    this.summary = '',
    this.reference = '',
    this.metadata = const <String, Object?>{},
  });

  final String kind;
  final String summary;
  final String reference;
  final JsonMap metadata;

  factory CollaborationConflictEvidence.fromJson(JsonMap json) {
    return CollaborationConflictEvidence(
      kind: ValueReaders.stringValue(json['kind']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      reference: ValueReaders.stringValue(json['reference']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'kind': kind,
      'summary': summary,
      'reference': reference,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    if (kind.trim().isEmpty &&
        summary.trim().isEmpty &&
        reference.trim().isEmpty) {
      return const <String>['missing_collaboration_conflict_evidence'];
    }
    return const <String>[];
  }
}

class CollaborationConflictRecord {
  const CollaborationConflictRecord({
    this.conflictId = '',
    this.groupKey = '',
    this.subject = '',
    this.target = '',
    this.agentId = '',
    this.agentName = '',
    this.task = '',
    this.risk = CollaborationConflictRisks.low,
    this.suggestion = '',
    this.adoptionHint = '',
    this.confidence = 0,
    this.evidence = const <CollaborationConflictEvidence>[],
    this.metadata = const <String, Object?>{},
  });

  final String conflictId;
  final String groupKey;
  final String subject;
  final String target;
  final String agentId;
  final String agentName;
  final String task;
  final String risk;
  final String suggestion;
  final String adoptionHint;
  final double confidence;
  final List<CollaborationConflictEvidence> evidence;
  final JsonMap metadata;

  factory CollaborationConflictRecord.fromJson(JsonMap json) {
    final evidenceEntries = ValueReaders.objectList(json['evidence']);
    final parsedEvidence = <CollaborationConflictEvidence>[];
    for (final raw in evidenceEntries) {
      final item = ValueReaders.mapValue(raw);
      if (item.isNotEmpty) {
        parsedEvidence.add(CollaborationConflictEvidence.fromJson(item));
        continue;
      }
      final summary = ValueReaders.stringValue(raw).trim();
      if (summary.isNotEmpty) {
        parsedEvidence.add(CollaborationConflictEvidence(summary: summary));
      }
    }
    return CollaborationConflictRecord(
      conflictId: ValueReaders.stringValue(
        json['conflict_id'],
        ValueReaders.stringValue(json['id']),
      ).trim(),
      groupKey: ValueReaders.stringValue(
        json['group_key'],
        ValueReaders.stringValue(json['conflict_key']),
      ).trim(),
      subject: ValueReaders.stringValue(
        json['subject'],
        ValueReaders.stringValue(json['title']),
      ).trim(),
      target: ValueReaders.stringValue(json['target']).trim(),
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      task: ValueReaders.stringValue(json['task']).trim(),
      risk: CollaborationConflictRisks.normalize(
        ValueReaders.stringValue(json['risk']),
      ),
      suggestion: ValueReaders.stringValue(json['suggestion']).trim(),
      adoptionHint: ValueReaders.stringValue(json['adoption_hint']).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      evidence: List<CollaborationConflictEvidence>.unmodifiable(
        parsedEvidence,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'conflict_id': conflictId,
      'group_key': groupKey,
      'subject': subject,
      'target': target,
      'agent_id': agentId,
      'agent_name': agentName,
      'task': task,
      'risk': risk,
      'suggestion': suggestion,
      'adoption_hint': adoptionHint,
      'confidence': confidence,
      'evidence': evidence
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (conflictId.trim().isEmpty) {
      result.add('missing_collaboration_conflict_id');
    }
    if (subject.trim().isEmpty) {
      result.add('missing_collaboration_conflict_subject');
    }
    if (!CollaborationConflictRisks.knownValues.contains(risk)) {
      result.add('invalid_collaboration_conflict_risk');
    }
    if (suggestion.trim().isEmpty) {
      result.add('missing_collaboration_conflict_suggestion');
    }
    if (adoptionHint.trim().isEmpty) {
      result.add('missing_collaboration_conflict_adoption_hint');
    }
    if (confidence < 0 || confidence > 1) {
      result.add('invalid_collaboration_conflict_confidence');
    }
    if (evidence.isEmpty ||
        evidence.expand((entry) => entry.validateBasics()).isNotEmpty) {
      result.add('invalid_collaboration_conflict_evidence');
    }
    return result;
  }
}
