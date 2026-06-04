enum NarrativeClaimDisposition {
  observed('observed'),
  proposed('proposed'),
  accepted('accepted'),
  questioned('questioned'),
  rejected('rejected'),
  superseded('superseded');

  const NarrativeClaimDisposition(this.id);

  final String id;

  static NarrativeClaimDisposition fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final disposition in NarrativeClaimDisposition.values) {
      if (disposition.id == clean) {
        return disposition;
      }
    }
    return NarrativeClaimDisposition.observed;
  }
}
