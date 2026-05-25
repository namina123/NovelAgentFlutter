import 'package:novel_agent_core/novel_agent_core.dart';

class LongTaskHeartbeatEvent {
  const LongTaskHeartbeatEvent({
    required this.runInstance,
    required this.occurredAt,
    required this.reason,
    required this.stale,
    this.nextHeartbeatAt,
  });

  final RunInstance runInstance;
  final DateTime occurredAt;
  final String reason;
  final bool stale;
  final DateTime? nextHeartbeatAt;
}
