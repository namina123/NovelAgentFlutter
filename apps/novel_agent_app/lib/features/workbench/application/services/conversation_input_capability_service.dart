import '../../presentation/models/conversation_input_capability_context.dart';
import '../../presentation/models/conversation_input_capability_state.dart';
import 'conversation_input_capability_resolver.dart';

class ConversationInputCapabilityService {
  const ConversationInputCapabilityService({
    ConversationInputCapabilityResolver? resolver,
  }) : _resolver = resolver ?? const ConversationInputCapabilityResolver();

  final ConversationInputCapabilityResolver _resolver;

  ConversationInputCapabilityState resolve({
    required ConversationInputCapabilityContext context,
  }) {
    // 中文注释: 这里保留轻量 facade，只负责把调用点接到正式 resolver，避免 widget 直接依赖判定细节。
    return _resolver.resolve(context);
  }
}
