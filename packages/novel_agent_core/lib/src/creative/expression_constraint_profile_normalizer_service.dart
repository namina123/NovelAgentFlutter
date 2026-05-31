import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'expression_constraint_kind.dart';
import 'expression_constraint_profile.dart';
import 'expression_constraint_scope_normalizer_service.dart';

class ExpressionConstraintProfileNormalizerService {
  const ExpressionConstraintProfileNormalizerService({
    ExpressionConstraintScopeNormalizerService? scopeNormalizerService,
  }) : _scopeNormalizerService =
           scopeNormalizerService ??
           const ExpressionConstraintScopeNormalizerService();

  final ExpressionConstraintScopeNormalizerService _scopeNormalizerService;

  ExpressionConstraintProfile normalize(JsonMap raw) {
    final recommendedScope = ValueReaders.mapValue(raw['recommended_scope']);
    return ExpressionConstraintProfile(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'],
        ValueReaders.stringValue(raw['name']),
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      kind: _parseKind(ValueReaders.stringValue(raw['kind'], 'custom').trim()),
      rules: ValueReaders.stringList(raw['rules']),
      riskSignals: ValueReaders.stringList(
        raw['risk_signals'] ?? raw['signals'],
      ),
      recommendedScope: recommendedScope.isNotEmpty
          ? _scopeNormalizerService.normalize(recommendedScope)
          : _scopeNormalizerService.normalize(raw),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ExpressionConstraintProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
      'kind': _kindValue(profile.kind),
      'rules': ValueReaders.deepCopyList(profile.rules.cast<Object?>()),
      'risk_signals': ValueReaders.deepCopyList(
        profile.riskSignals.cast<Object?>(),
      ),
      'recommended_scope': _scopeNormalizerService.toDocument(
        profile.recommendedScope,
      ),
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }

  ExpressionConstraintKind _parseKind(String raw) {
    switch (raw) {
      case 'natural_expression':
        return ExpressionConstraintKind.naturalExpression;
      case 'narrative_boundary':
        return ExpressionConstraintKind.narrativeBoundary;
      case 'terminology_control':
        return ExpressionConstraintKind.terminologyControl;
      case 'rhythm_control':
        return ExpressionConstraintKind.rhythmControl;
      case 'continuity_guard':
        return ExpressionConstraintKind.continuityGuard;
      default:
        return ExpressionConstraintKind.custom;
    }
  }

  String _kindValue(ExpressionConstraintKind kind) {
    switch (kind) {
      case ExpressionConstraintKind.naturalExpression:
        return 'natural_expression';
      case ExpressionConstraintKind.narrativeBoundary:
        return 'narrative_boundary';
      case ExpressionConstraintKind.terminologyControl:
        return 'terminology_control';
      case ExpressionConstraintKind.rhythmControl:
        return 'rhythm_control';
      case ExpressionConstraintKind.continuityGuard:
        return 'continuity_guard';
      case ExpressionConstraintKind.custom:
        return 'custom';
    }
  }
}
