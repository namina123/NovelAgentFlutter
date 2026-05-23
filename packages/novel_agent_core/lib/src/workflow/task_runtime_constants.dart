final class TaskRuntimeConstants {
  static const String modeSingleChapterAtomic = 'single_chapter_atomic';
  static const String modeSupervisedChapterQueue = 'supervised_chapter_queue';
  static const String modeHumanOutlineAiDraft = 'human_outline_ai_draft';
  static const String modeSeedToFullNovel = 'seed_to_full_novel';

  static const String statusQueued = 'queued';
  static const String statusPlanning = 'planning';
  static const String statusRunning = 'running';
  static const String statusWaitingUser = 'waiting_user';
  static const String statusPaused = 'paused';
  static const String statusRetrying = 'retrying';
  static const String statusSucceeded = 'succeeded';
  static const String statusFailed = 'failed';
  static const String statusCancelled = 'cancelled';

  static const List<String> runnableStatuses = <String>[
    statusQueued,
    statusRetrying,
  ];

  static const List<String> terminalStatuses = <String>[
    statusSucceeded,
    statusCancelled,
  ];

  static const List<String> validStatuses = <String>[
    statusQueued,
    statusPlanning,
    statusRunning,
    statusWaitingUser,
    statusPaused,
    statusRetrying,
    statusSucceeded,
    statusFailed,
    statusCancelled,
  ];
}
