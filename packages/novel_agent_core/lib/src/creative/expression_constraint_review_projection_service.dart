import '../common/json_types.dart';
import 'creative_rule_stack.dart';
import 'expression_constraint_kind.dart';
import 'expression_constraint_profile.dart';
import 'expression_constraint_review_projection.dart';

class ExpressionConstraintReviewProjectionService {
  const ExpressionConstraintReviewProjectionService();

  ExpressionConstraintReviewProjection buildFromCreativeRuleStack(
    JsonMap rawStack,
  ) {
    if (rawStack.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    return build(CreativeRuleStack.fromJson(rawStack).expressionConstraints);
  }

  ExpressionConstraintReviewProjection build(
    List<ExpressionConstraintProfile> profiles,
  ) {
    if (profiles.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    final reviewFocuses = <String>[];
    final continuityWatchItems = <String>[];
    final miniRecheckItems = <String>[];
    final voiceProtectionNotes = <String>[];
    var authenticityScore = 0;
    for (final profile in profiles) {
      final profileId = profile.id.trim().toLowerCase();
      switch (profile.kind) {
        case ExpressionConstraintKind.naturalExpression:
          authenticityScore = _max(authenticityScore, 2);
          _addUnique(reviewFocuses, '去模板化、去解释腔、去职业化表达，但不要把人物声音和题材纹理洗平。');
          _addUnique(miniRecheckItems, '确认真实性清理后主角与关键说话者仍然保留各自声音。');
          _addUnique(
            voiceProtectionNotes,
            '清理 generic AI 腔，不要顺手抹平角色口吻、叙述偏压和题材质地。',
          );
          break;
        case ExpressionConstraintKind.narrativeBoundary:
          _addUnique(reviewFocuses, '严查视角泄漏与信息边界混用。');
          _addUnique(reviewFocuses, '说话风格漂移要结合角色边界判断，不要只当成普通措辞问题。');
          _addUnique(continuityWatchItems, '视角泄漏');
          _addUnique(continuityWatchItems, '信息边界混用');
          _addUnique(continuityWatchItems, '说话风格漂移');
          _addUnique(miniRecheckItems, '确认修订后仍严格符合当前 POV 的可知信息边界。');
          break;
        case ExpressionConstraintKind.terminologyControl:
          authenticityScore = _max(authenticityScore, 2);
          _addUnique(reviewFocuses, '把分析腔、术语堆叠和空心概念句视为真实性风险。');
          _addUnique(miniRecheckItems, '确认压低术语和分析腔后，没有误删剧情真正需要的专业/时代/设定用语。');
          break;
        case ExpressionConstraintKind.rhythmControl:
          authenticityScore = _max(authenticityScore, 1);
          _addUnique(reviewFocuses, '检查工整排比、过度平衡句和段落节奏模板化。');
          _addUnique(miniRecheckItems, '确认段落节奏仍匹配项目段落模式，没有被修成整齐但发空的匀速 prose。');
          break;
        case ExpressionConstraintKind.continuityGuard:
          _addUnique(reviewFocuses, '把设定状态漂移、角色状态跳变和前后规则松动视为结构性问题。');
          _addUnique(continuityWatchItems, '设定状态漂移');
          _addUnique(continuityWatchItems, '角色状态漂移');
          _addUnique(miniRecheckItems, '确认修订没有改坏前后设定、关系压力与状态链。');
          break;
        case ExpressionConstraintKind.custom:
          break;
      }

      if (profileId == 'de_ai') {
        authenticityScore = _max(authenticityScore, 3);
        _addUnique(reviewFocuses, '重点清理 AI 味、假深刻句、总结腔与解释腔，但不能洗平人物声音。');
      } else if (profileId == 'strict_pov_boundary') {
        _addUnique(continuityWatchItems, '视角泄漏');
        _addUnique(continuityWatchItems, '信息边界混用');
      } else if (profileId == 'low_jargon_narration') {
        authenticityScore = _max(authenticityScore, 2);
        _addUnique(reviewFocuses, '把职业化、理论化、评论员式措辞视为真实性风险。');
      }
    }
    return ExpressionConstraintReviewProjection(
      authenticityPassLevel: _authenticityLevel(authenticityScore),
      reviewFocuses: reviewFocuses,
      continuityWatchItems: continuityWatchItems,
      miniRecheckItems: miniRecheckItems,
      voiceProtectionNotes: voiceProtectionNotes,
    );
  }

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

  void _addUnique(List<String> items, String value) {
    final clean = value.trim();
    if (clean.isNotEmpty && !items.contains(clean)) {
      items.add(clean);
    }
  }
}
