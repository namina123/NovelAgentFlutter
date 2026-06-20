class LongTaskStationSession {
  const LongTaskStationSession({
    required this.isVisible,
    required this.isInitialized,
    required this.autoRefreshEnabled,
  });

  final bool isVisible;
  final bool isInitialized;
  final bool autoRefreshEnabled;

  factory LongTaskStationSession.initial() {
    return const LongTaskStationSession(
      isVisible: false,
      isInitialized: false,
      autoRefreshEnabled: false,
    );
  }

  LongTaskStationSession copyWith({
    bool? isVisible,
    bool? isInitialized,
    bool? autoRefreshEnabled,
  }) {
    return LongTaskStationSession(
      isVisible: isVisible ?? this.isVisible,
      isInitialized: isInitialized ?? this.isInitialized,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
    );
  }
}
