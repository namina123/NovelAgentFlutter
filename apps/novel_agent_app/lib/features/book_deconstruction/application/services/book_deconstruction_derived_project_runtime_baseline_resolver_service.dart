class BookDeconstructionDerivedProjectRuntimeBaselineResolverService {
  const BookDeconstructionDerivedProjectRuntimeBaselineResolverService();

  String resolve({
    required String targetProjectTypeId,
    required String targetModeId,
  }) {
    if (targetProjectTypeId.trim() != 'long_novel') {
      return '';
    }
    switch (targetModeId.trim()) {
      case 'full_outline_consensus':
      case 'chapter_brief_supervised':
      case 'salvage_restructure_existing':
        return 'chapter_collaboration_autorun';
      case 'seed_autopilot_novel':
      case 'volume_checkpoint_handoff':
      default:
        return 'continuous_autonomous';
    }
  }
}
