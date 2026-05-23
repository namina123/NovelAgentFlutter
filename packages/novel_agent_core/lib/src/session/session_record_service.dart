import 'session_context_renderer_service.dart';
import 'session_history_service.dart';
import 'session_message_service.dart';
import 'session_mode_service.dart';
import 'session_record_mutation_service.dart';
import 'session_record_normalizer_service.dart';

class SessionRecordService {
  SessionRecordService({
    required this.mode,
    required this.messages,
    required this.normalizer,
    required this.mutations,
    required this.renderer,
    required this.history,
  });

  final SessionModeService mode;
  final SessionMessageService messages;
  final SessionRecordNormalizerService normalizer;
  final SessionRecordMutationService mutations;
  final SessionContextRendererService renderer;
  final SessionHistoryService history;
}
