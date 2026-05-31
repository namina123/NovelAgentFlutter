import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationRequestAgentResolution {
  const ConversationRequestAgentResolution({
    required this.agentId,
    required this.agent,
  });

  final String agentId;
  final JsonMap agent;
}
