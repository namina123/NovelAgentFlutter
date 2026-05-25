class CheckpointPolicy {
  const CheckpointPolicy({
    required this.id,
    required this.title,
    required this.description,
    this.defaultChapterInterval = 0,
    this.requireOutlineConfirmation = false,
    this.requireVolumeConfirmation = false,
  });

  final String id;
  final String title;
  final String description;
  final int defaultChapterInterval;
  final bool requireOutlineConfirmation;
  final bool requireVolumeConfirmation;
}
