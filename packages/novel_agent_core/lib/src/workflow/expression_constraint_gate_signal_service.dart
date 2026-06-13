import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_review_projection.dart';
import 'expression_constraint_gate_signal.dart';
import 'writing_execution_constraint_bridge_result.dart';

class ExpressionConstraintGateSignalService {
  const ExpressionConstraintGateSignalService();

  ExpressionConstraintGateSignal build({
    required WritingExecutionConstraintBridgeResult bridgeResult,
    required ExpressionConstraintReviewProjection review,
  }) {
    final active = bridgeResult.projectExpressionConstraintBindings.isNotEmpty;
    final policyMode =
        bridgeResult.expressionConstraintPolicyMode.trim().isEmpty
        ? ExpressionConstraintExecutionPolicyModes.disabled
        : bridgeResult.expressionConstraintPolicyMode.trim();
    final disabled =
        policyMode == ExpressionConstraintExecutionPolicyModes.disabled;
    final applied = active && bridgeResult.expressionConstraintApplied;
    final skipped =
        active &&
        !disabled &&
        !applied &&
        (bridgeResult.expressionConstraintSkippedReasons.isNotEmpty ||
            bridgeResult.expressionConstraintTechnicalTurnExcluded);
    if (!active || disabled || skipped || !applied) {
      return const ExpressionConstraintGateSignal();
    }

    final reviewRequired =
        bridgeResult.expressionConstraintReviewRequirement.trim() !=
        ExpressionConstraintReviewRequirements.none;
    final reviewProvided = !review.isEmpty;
    final profileRiskSignals = _activeProfileRiskSignals(bridgeResult);
    if (reviewRequired && !reviewProvided) {
      return ExpressionConstraintGateSignal(
        present: true,
        severity: ExpressionConstraintGateSeverities.blocking,
        recommendedDisposition:
            ExpressionConstraintGateRecommendedDispositions.repair,
        reason: 'expression_constraint_review_missing',
        summary: '表达限制要求复核，但当前缺少复核证据。',
        riskSignals: List<String>.unmodifiable(profileRiskSignals.take(4)),
        naturalUsage: false,
        repeatedPattern: false,
        repairRequired: true,
        adjustNextChapter: false,
        metadata: <String, Object?>{
          'policy_mode': policyMode,
          'review_required': reviewRequired,
          'review_provided': false,
        },
      );
    }

    if (!reviewProvided) {
      return const ExpressionConstraintGateSignal();
    }

    final aggressive =
        review.authenticityPassLevel ==
        ExpressionConstraintReviewProjection.authenticityAggressive;
    final medium =
        review.authenticityPassLevel ==
        ExpressionConstraintReviewProjection.authenticityMedium;
    final continuityRisk = review.continuityWatchItems.isNotEmpty;
    final repeatedPattern =
        bridgeResult.expressionConstraintRuntimeEscalated ||
        _hasRepeatedRiskEvidence(review.continuityWatchItems) ||
        _hasRepeatedRiskEvidence(review.miniRecheckItems);
    final naturalUsage =
        !aggressive &&
        review.continuityWatchItems.isEmpty &&
        review.miniRecheckItems.isEmpty;
    final riskSignals = _riskSignals(
      review,
      profileRiskSignals: profileRiskSignals,
      includeProfileSignals: false,
    );
    final hasRiskEvidence =
        riskSignals.isNotEmpty || aggressive || medium || repeatedPattern;
    if (!hasRiskEvidence) {
      return ExpressionConstraintGateSignal(
        present: true,
        severity: ExpressionConstraintGateSeverities.info,
        recommendedDisposition:
            ExpressionConstraintGateRecommendedDispositions.none,
        reason: 'expression_constraint_natural_usage',
        summary: '表达限制复核已提供，当前文本未见明显额外处置需求。',
        naturalUsage: naturalUsage,
        repeatedPattern: false,
        riskSignals: const <String>[],
        metadata: <String, Object?>{
          'policy_mode': policyMode,
          'review_required': reviewRequired,
          'review_provided': true,
        },
      );
    }

    final repairDispositionRequested =
        bridgeResult.expressionConstraintViolationDisposition.trim() ==
        ExpressionConstraintViolationDispositions.repair;
    final repairRequired =
        repairDispositionRequested &&
        (aggressive || continuityRisk || repeatedPattern);
    final recommendedDisposition = repairRequired
        ? ExpressionConstraintGateRecommendedDispositions.repair
        : continuityRisk || repeatedPattern
        ? ExpressionConstraintGateRecommendedDispositions.adjustNext
        : ExpressionConstraintGateRecommendedDispositions.remind;
    final severity =
        recommendedDisposition ==
            ExpressionConstraintGateRecommendedDispositions.repair
        ? ExpressionConstraintGateSeverities.blocking
        : recommendedDisposition ==
              ExpressionConstraintGateRecommendedDispositions.adjustNext
        ? ExpressionConstraintGateSeverities.warning
        : ExpressionConstraintGateSeverities.info;
    return ExpressionConstraintGateSignal(
      present: true,
      severity: severity,
      recommendedDisposition: recommendedDisposition,
      reason: _reasonForDisposition(
        recommendedDisposition,
        repeatedPattern: repeatedPattern,
        continuityRisk: continuityRisk,
        aggressive: aggressive,
      ),
      summary: _summaryForDisposition(
        recommendedDisposition,
        repeatedPattern: repeatedPattern,
        naturalUsage: naturalUsage,
      ),
      riskSignals: List<String>.unmodifiable(riskSignals),
      naturalUsage: naturalUsage,
      repeatedPattern: repeatedPattern,
      repairRequired:
          recommendedDisposition ==
          ExpressionConstraintGateRecommendedDispositions.repair,
      adjustNextChapter:
          recommendedDisposition ==
          ExpressionConstraintGateRecommendedDispositions.adjustNext,
      metadata: <String, Object?>{
        'policy_mode': policyMode,
        'review_required': reviewRequired,
        'review_provided': true,
        'aggressive_authenticity': aggressive,
        'medium_authenticity': medium,
        'runtime_escalated': bridgeResult.expressionConstraintRuntimeEscalated,
      },
    );
  }

  List<String> _riskSignals(
    ExpressionConstraintReviewProjection review, {
    required List<String> profileRiskSignals,
    required bool includeProfileSignals,
  }) {
    final result = <String>[];
    void addAll(List<String> values) {
      for (final value in values) {
        final clean = value.trim();
        if (clean.isNotEmpty && !result.contains(clean)) {
          result.add(clean);
        }
      }
    }

    addAll(review.continuityWatchItems);
    addAll(review.miniRecheckItems);
    if (includeProfileSignals) {
      addAll(profileRiskSignals.take(4).toList(growable: false));
    }
    return result;
  }

  List<String> _activeProfileRiskSignals(
    WritingExecutionConstraintBridgeResult bridgeResult,
  ) {
    final activeProfileIds = bridgeResult.projectExpressionConstraintBindings
        .where((binding) => binding.enabled)
        .map((binding) => binding.profileId.trim())
        .where((profileId) => profileId.isNotEmpty)
        .toSet();
    if (activeProfileIds.isEmpty) {
      return const <String>[];
    }
    final result = <String>[];
    for (final profile in bridgeResult.expressionConstraintProfiles) {
      if (!activeProfileIds.contains(profile.id.trim())) {
        continue;
      }
      for (final signal in profile.riskSignals) {
        final clean = signal.trim();
        if (clean.isNotEmpty && !result.contains(clean)) {
          result.add(clean);
        }
      }
    }
    return List<String>.unmodifiable(result);
  }

  String _reasonForDisposition(
    String disposition, {
    required bool repeatedPattern,
    required bool continuityRisk,
    required bool aggressive,
  }) {
    if (disposition == ExpressionConstraintGateRecommendedDispositions.repair) {
      return repeatedPattern
          ? 'expression_constraint_force_repair_repeated_pattern'
          : continuityRisk
          ? 'expression_constraint_force_repair_continuity_risk'
          : aggressive
          ? 'expression_constraint_force_repair_authenticity'
          : 'expression_constraint_force_repair';
    }
    if (disposition ==
        ExpressionConstraintGateRecommendedDispositions.adjustNext) {
      return repeatedPattern
          ? 'expression_constraint_adjust_next_repeated_pattern'
          : continuityRisk
          ? 'expression_constraint_adjust_next_continuity_risk'
          : 'expression_constraint_adjust_next';
    }
    return aggressive
        ? 'expression_constraint_remind_authenticity'
        : 'expression_constraint_remind_natural_usage';
  }

  String _summaryForDisposition(
    String disposition, {
    required bool repeatedPattern,
    required bool naturalUsage,
  }) {
    if (disposition == ExpressionConstraintGateRecommendedDispositions.repair) {
      return repeatedPattern
          ? '表达限制风险已连续出现，当前轮次需要先修订再继续。'
          : '表达限制风险已达到强修复门槛，当前轮次需要先修订。';
    }
    if (disposition ==
        ExpressionConstraintGateRecommendedDispositions.adjustNext) {
      return repeatedPattern
          ? '表达限制风险开始连续出现，建议下一章优先回调。'
          : '表达限制出现结构性风险，建议下一章优先调整。';
    }
    if (disposition == ExpressionConstraintGateRecommendedDispositions.remind) {
      return naturalUsage ? '表达限制复核已提供，可记录轻量提醒后继续。' : '表达限制复核已提供，建议记录提醒并继续观察。';
    }
    return '表达限制复核已提供，当前没有额外 gate 动作。';
  }

  bool _hasRepeatedRiskEvidence(List<String> items) {
    if (items.isEmpty) {
      return false;
    }
    final surfaceItems = items
        .where(_isSurfaceRiskItem)
        .toList(growable: false);
    if (surfaceItems.isEmpty) {
      return items.length >= 2;
    }
    var surfaceHitTotal = 0;
    for (final item in surfaceItems) {
      surfaceHitTotal += _surfaceRiskHitCount(item);
    }
    if (surfaceHitTotal >= 3) {
      return true;
    }
    final nonSurfaceCount = items.length - surfaceItems.length;
    return nonSurfaceCount >= 2;
  }

  bool _isSurfaceRiskItem(String item) => item.trim().startsWith('正文表面风险命中：');

  int _surfaceRiskHitCount(String item) {
    final match = RegExp(r'\sx(\d+)\s*$').firstMatch(item.trim());
    if (match == null) {
      return 1;
    }
    return int.tryParse(match.group(1) ?? '') ?? 1;
  }
}
