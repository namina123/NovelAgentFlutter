import '../common/json_types.dart';
import 'session_message_inclusion_strategy.dart';

class DefaultSessionMessageInclusionStrategy
    implements SessionMessageInclusionStrategy {
  @override
  bool includeInContext({
    required String role,
    String outcome = 'success',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 默认策略只把真实用户输入和成功助手正文纳入上下文，失败/重试提示保留在展示层。
    final normalizedRole = role.trim().toLowerCase();
    final normalizedOutcome = outcome.trim().toLowerCase();
    final _ = metadata;
    if (normalizedRole == 'user') {
      return true;
    }
    if (normalizedRole == 'assistant') {
      return normalizedOutcome == 'success';
    }
    return false;
  }
}
