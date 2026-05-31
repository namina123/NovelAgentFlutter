class LongTaskContinuityContextProjection {
  const LongTaskContinuityContextProjection({
    this.scopeIds = const <String>[],
    this.frameId = '',
    this.canonicalPaths = const <String>[],
    this.overlayPaths = const <String>[],
    this.statePaths = const <String>[],
    this.tailWindowPaths = const <String>[],
  });

  final List<String> scopeIds;
  final String frameId;
  final List<String> canonicalPaths;
  final List<String> overlayPaths;
  final List<String> statePaths;
  final List<String> tailWindowPaths;

  List<String> get persistentPaths {
    return <String>[
      ...canonicalPaths,
      ...overlayPaths,
      ...statePaths,
      ...tailWindowPaths,
    ];
  }
}
