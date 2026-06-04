abstract final class ChapterDeliveryStateStatuses {
  static const String delivered = 'delivered';
  static const String deliveredNeedsRepair = 'delivered_needs_repair';
  static const String missingOutputRecoverable = 'missing_output_recoverable';
  static const String invalidOutputRewriteRequired =
      'invalid_output_rewrite_required';
  static const String pathMismatchRecoverable = 'path_mismatch_recoverable';
  static const String waitingUserChoice = 'waiting_user_choice';
  static const String manualAttentionRequired = 'manual_attention_required';
  static const String hardFailure = 'hard_failure';
}
