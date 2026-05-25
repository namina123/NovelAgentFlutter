enum LongTaskRunStatus {
  draftingGuidance('drafting_guidance'),
  readyToStart('ready_to_start'),
  running('running'),
  waitingGate('waiting_gate'),
  paused('paused'),
  recovering('recovering'),
  failedManualAttention('failed_manual_attention'),
  stopped('stopped');

  const LongTaskRunStatus(this.id);

  final String id;

  static LongTaskRunStatus fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final status in LongTaskRunStatus.values) {
      if (status.id == clean) {
        return status;
      }
    }
    return LongTaskRunStatus.draftingGuidance;
  }
}

extension LongTaskRunStatusX on LongTaskRunStatus {
  bool get isActive =>
      this == LongTaskRunStatus.running ||
      this == LongTaskRunStatus.waitingGate ||
      this == LongTaskRunStatus.recovering;

  bool get requiresManualAttention =>
      this == LongTaskRunStatus.waitingGate ||
      this == LongTaskRunStatus.failedManualAttention ||
      this == LongTaskRunStatus.paused;

  bool get isTerminal => this == LongTaskRunStatus.stopped;
}
