import 'expression_constraint_kind.dart';
import 'expression_constraint_profile.dart';
import 'expression_constraint_review_projection.dart';
import 'project_expression_constraint_binding.dart';

class ExpressionConstraintSurfaceRiskScanService {
  const ExpressionConstraintSurfaceRiskScanService();

  ExpressionConstraintReviewProjection scan({
    required List<ExpressionConstraintProfile> profiles,
    required Iterable<String> texts,
    List<ProjectExpressionConstraintBinding> bindings = const [],
    int maxItems = 6,
  }) {
    final effectiveProfiles = _effectiveProfiles(profiles, bindings);
    final combinedText = texts
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
    if (combinedText.trim().isEmpty || effectiveProfiles.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }

    final reviewFocuses = <String>[];
    final continuityWatchItems = <String>[];
    final miniRecheckItems = <String>[];
    final voiceProtectionNotes = <String>[];
    var authenticityScore = 0;

    for (final profile in effectiveProfiles) {
      var profileHitCount = 0;
      for (final signal in profile.riskSignals) {
        final hitCount = _countSignal(combinedText, signal);
        if (hitCount <= 0) {
          continue;
        }
        profileHitCount += hitCount;
        final label =
            '${profile.displayName.trim().isEmpty ? profile.id : profile.displayName}：${signal.trim()} x$hitCount';
        if (_isContinuityLike(profile.kind)) {
          _addUnique(continuityWatchItems, '正文表面风险命中：$label');
        } else {
          _addUnique(miniRecheckItems, '正文表面风险命中：$label');
        }
        if (miniRecheckItems.length + continuityWatchItems.length >= maxItems) {
          break;
        }
      }
      if (profileHitCount <= 0) {
        continue;
      }
      _addUnique(
        reviewFocuses,
        '正文已命中 ${profile.displayName} 的风险信号，需按该表达限制回查。',
      );
      if (_isAuthenticityLike(profile.kind)) {
        authenticityScore = _max(
          authenticityScore,
          profileHitCount >= 3 ? 3 : 2,
        );
        _addUnique(voiceProtectionNotes, '修订表达风险时保留人物口吻、时代质感和场面推进，不要洗成统一文案腔。');
      }
      if (miniRecheckItems.length + continuityWatchItems.length >= maxItems) {
        break;
      }
    }

    if (reviewFocuses.isEmpty &&
        continuityWatchItems.isEmpty &&
        miniRecheckItems.isEmpty &&
        voiceProtectionNotes.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    return ExpressionConstraintReviewProjection(
      authenticityPassLevel: _authenticityLevel(authenticityScore),
      reviewFocuses: List<String>.unmodifiable(reviewFocuses.take(maxItems)),
      continuityWatchItems: List<String>.unmodifiable(
        continuityWatchItems.take(maxItems),
      ),
      miniRecheckItems: List<String>.unmodifiable(
        miniRecheckItems.take(maxItems),
      ),
      voiceProtectionNotes: List<String>.unmodifiable(
        voiceProtectionNotes.take(maxItems),
      ),
    );
  }

  List<ExpressionConstraintProfile> _effectiveProfiles(
    List<ExpressionConstraintProfile> profiles,
    List<ProjectExpressionConstraintBinding> bindings,
  ) {
    if (bindings.isEmpty) {
      return profiles;
    }
    final activeProfileIds = bindings
        .where((binding) => binding.enabled)
        .map((binding) => binding.profileId.trim())
        .where((profileId) => profileId.isNotEmpty)
        .toSet();
    if (activeProfileIds.isEmpty) {
      return const <ExpressionConstraintProfile>[];
    }
    return profiles
        .where((profile) => activeProfileIds.contains(profile.id.trim()))
        .toList(growable: false);
  }

  ExpressionConstraintReviewProjection merge(
    ExpressionConstraintReviewProjection base,
    ExpressionConstraintReviewProjection surface,
  ) {
    if (base.isEmpty) {
      return surface;
    }
    if (surface.isEmpty) {
      return base;
    }
    return ExpressionConstraintReviewProjection(
      authenticityPassLevel: _strongerAuthenticity(
        base.authenticityPassLevel,
        surface.authenticityPassLevel,
      ),
      reviewFocuses: _mergeUnique(base.reviewFocuses, surface.reviewFocuses),
      continuityWatchItems: _mergeUnique(
        base.continuityWatchItems,
        surface.continuityWatchItems,
      ),
      miniRecheckItems: _mergeUnique(
        base.miniRecheckItems,
        surface.miniRecheckItems,
      ),
      voiceProtectionNotes: _mergeUnique(
        base.voiceProtectionNotes,
        surface.voiceProtectionNotes,
      ),
    );
  }

  int _countSignal(String text, String signal) {
    final cleanSignal = signal.trim();
    if (cleanSignal.isEmpty) {
      return 0;
    }
    final wildcardParts = cleanSignal
        .split('……')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (wildcardParts.length >= 2) {
      return _countOrderedParts(text, wildcardParts);
    }
    return _countLiteral(text, cleanSignal);
  }

  int _countOrderedParts(String text, List<String> parts) {
    var count = 0;
    var searchStart = 0;
    while (searchStart < text.length) {
      var partStart = text.indexOf(parts.first, searchStart);
      if (partStart < 0) {
        break;
      }
      var cursor = partStart + parts.first.length;
      var matched = true;
      for (var index = 1; index < parts.length; index += 1) {
        final next = text.indexOf(parts[index], cursor);
        if (next < 0 || next - cursor > 80) {
          matched = false;
          break;
        }
        cursor = next + parts[index].length;
      }
      if (matched) {
        count += 1;
        searchStart = cursor;
      } else {
        searchStart = partStart + parts.first.length;
      }
    }
    return count;
  }

  int _countLiteral(String text, String signal) {
    var count = 0;
    var index = text.indexOf(signal);
    while (index >= 0) {
      count += 1;
      index = text.indexOf(signal, index + signal.length);
    }
    return count;
  }

  bool _isContinuityLike(ExpressionConstraintKind kind) =>
      kind == ExpressionConstraintKind.narrativeBoundary ||
      kind == ExpressionConstraintKind.continuityGuard;

  bool _isAuthenticityLike(ExpressionConstraintKind kind) =>
      kind == ExpressionConstraintKind.naturalExpression ||
      kind == ExpressionConstraintKind.terminologyControl ||
      kind == ExpressionConstraintKind.rhythmControl;

  int _max(int left, int right) => left >= right ? left : right;

  String _authenticityLevel(int score) {
    if (score >= 3) {
      return ExpressionConstraintReviewProjection.authenticityAggressive;
    }
    if (score == 2) {
      return ExpressionConstraintReviewProjection.authenticityMedium;
    }
    if (score == 1) {
      return ExpressionConstraintReviewProjection.authenticityLight;
    }
    return ExpressionConstraintReviewProjection.authenticityDisabled;
  }

  String _strongerAuthenticity(String left, String right) =>
      _authenticityRank(left) >= _authenticityRank(right) ? left : right;

  int _authenticityRank(String value) {
    switch (value) {
      case ExpressionConstraintReviewProjection.authenticityAggressive:
        return 3;
      case ExpressionConstraintReviewProjection.authenticityMedium:
        return 2;
      case ExpressionConstraintReviewProjection.authenticityLight:
        return 1;
      default:
        return 0;
    }
  }

  List<String> _mergeUnique(List<String> left, List<String> right) {
    final result = <String>[];
    for (final item in <String>[...left, ...right]) {
      _addUnique(result, item);
    }
    return List<String>.unmodifiable(result);
  }

  void _addUnique(List<String> items, String value) {
    final clean = value.trim();
    if (clean.isNotEmpty && !items.contains(clean)) {
      items.add(clean);
    }
  }
}
