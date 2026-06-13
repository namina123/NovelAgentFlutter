import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class ExpressionConstraintGateSeverities {
  static const String none = 'none';
  static const String info = 'info';
  static const String warning = 'warning';
  static const String blocking = 'blocking';

  static const List<String> knownValues = <String>[
    none,
    info,
    warning,
    blocking,
  ];
}

abstract final class ExpressionConstraintGateRecommendedDispositions {
  static const String none = 'none';
  static const String remind = 'remind';
  static const String adjustNext = 'adjust_next';
  static const String repair = 'repair';

  static const List<String> knownValues = <String>[
    none,
    remind,
    adjustNext,
    repair,
  ];
}

class ExpressionConstraintGateSignal {
  const ExpressionConstraintGateSignal({
    this.present = false,
    this.severity = ExpressionConstraintGateSeverities.none,
    this.recommendedDisposition =
        ExpressionConstraintGateRecommendedDispositions.none,
    this.reason = '',
    this.summary = '',
    this.riskSignals = const <String>[],
    this.naturalUsage = false,
    this.repeatedPattern = false,
    this.repairRequired = false,
    this.adjustNextChapter = false,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String severity;
  final String recommendedDisposition;
  final String reason;
  final String summary;
  final List<String> riskSignals;
  final bool naturalUsage;
  final bool repeatedPattern;
  final bool repairRequired;
  final bool adjustNextChapter;
  final JsonMap metadata;

  factory ExpressionConstraintGateSignal.fromJson(JsonMap json) {
    final recommendedDisposition = _normalizeDisposition(
      ValueReaders.stringValue(
        json['recommended_disposition'],
        ValueReaders.stringValue(json['category']),
      ).trim(),
    );
    return ExpressionConstraintGateSignal(
      present:
          ValueReaders.boolValue(json['present']) ||
          recommendedDisposition !=
              ExpressionConstraintGateRecommendedDispositions.none ||
          ValueReaders.stringList(json['risk_signals']).isNotEmpty ||
          ValueReaders.stringValue(json['summary']).trim().isNotEmpty,
      severity: _normalizeSeverity(
        ValueReaders.stringValue(json['severity']).trim(),
        recommendedDisposition: recommendedDisposition,
      ),
      recommendedDisposition: recommendedDisposition,
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      riskSignals: List<String>.unmodifiable(
        ValueReaders.stringList(json['risk_signals']),
      ),
      naturalUsage: ValueReaders.boolValue(json['natural_usage']),
      repeatedPattern: ValueReaders.boolValue(json['repeated_pattern']),
      repairRequired:
          ValueReaders.boolValue(json['repair_required']) ||
          recommendedDisposition ==
              ExpressionConstraintGateRecommendedDispositions.repair,
      adjustNextChapter:
          ValueReaders.boolValue(json['adjust_next_chapter']) ||
          recommendedDisposition ==
              ExpressionConstraintGateRecommendedDispositions.adjustNext,
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'present': present,
      'severity': severity,
      'recommended_disposition': recommendedDisposition,
      'category': recommendedDisposition,
      'reason': reason,
      'summary': summary,
      'risk_signals': ValueReaders.deepCopyList(riskSignals.cast<Object?>()),
      'natural_usage': naturalUsage,
      'repeated_pattern': repeatedPattern,
      'repair_required': repairRequired,
      'adjust_next_chapter': adjustNextChapter,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (!ExpressionConstraintGateSeverities.knownValues.contains(severity)) {
      result.add('invalid_expression_constraint_gate_severity');
    }
    if (!ExpressionConstraintGateRecommendedDispositions.knownValues.contains(
      recommendedDisposition,
    )) {
      result.add('invalid_expression_constraint_gate_disposition');
    }
    if (repairRequired &&
        recommendedDisposition !=
            ExpressionConstraintGateRecommendedDispositions.repair) {
      result.add('invalid_expression_constraint_gate_repair_state');
    }
    if (adjustNextChapter &&
        recommendedDisposition !=
            ExpressionConstraintGateRecommendedDispositions.adjustNext) {
      result.add('invalid_expression_constraint_gate_adjust_state');
    }
    return result;
  }

  static String _normalizeDisposition(String value) {
    if (ExpressionConstraintGateRecommendedDispositions.knownValues.contains(
      value,
    )) {
      return value;
    }
    return ExpressionConstraintGateRecommendedDispositions.none;
  }

  static String _normalizeSeverity(
    String value, {
    required String recommendedDisposition,
  }) {
    if (ExpressionConstraintGateSeverities.knownValues.contains(value)) {
      return value;
    }
    if (recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.repair) {
      return ExpressionConstraintGateSeverities.blocking;
    }
    if (recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.adjustNext) {
      return ExpressionConstraintGateSeverities.warning;
    }
    if (recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.remind) {
      return ExpressionConstraintGateSeverities.info;
    }
    return ExpressionConstraintGateSeverities.none;
  }
}
