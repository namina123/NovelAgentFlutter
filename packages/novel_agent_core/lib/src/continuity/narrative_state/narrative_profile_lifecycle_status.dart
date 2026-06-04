enum NarrativeProfileLifecycleStatus {
  draft('draft'),
  proposed('proposed'),
  accepted('accepted'),
  active('active'),
  deprecated('deprecated'),
  superseded('superseded'),
  rejected('rejected');

  const NarrativeProfileLifecycleStatus(this.id);

  final String id;

  static NarrativeProfileLifecycleStatus fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final status in NarrativeProfileLifecycleStatus.values) {
      if (status.id == clean) {
        return status;
      }
    }
    return NarrativeProfileLifecycleStatus.draft;
  }
}
