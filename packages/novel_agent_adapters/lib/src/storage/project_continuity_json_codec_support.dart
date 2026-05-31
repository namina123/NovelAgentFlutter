import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectContinuityJsonCodecSupport {
  const ProjectContinuityJsonCodecSupport();

  ContinuityCoverage parseCoverage(JsonMap raw) {
    return ContinuityCoverage(
      sourceLabel: ValueReaders.stringValue(raw['source_label']).trim(),
      sourcePaths: ValueReaders.stringList(raw['source_paths']),
      chapterStart: ValueReaders.intValue(raw['chapter_start']),
      chapterEnd: ValueReaders.intValue(raw['chapter_end']),
      isPartial: ValueReaders.boolValue(raw['is_partial']),
      inferredSections: ValueReaders.stringList(raw['inferred_sections']),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap coverageToDocument(ContinuityCoverage coverage) {
    return <String, Object?>{
      'source_label': coverage.sourceLabel,
      'source_paths': coverage.sourcePaths,
      'chapter_start': coverage.chapterStart,
      'chapter_end': coverage.chapterEnd,
      'is_partial': coverage.isPartial,
      'inferred_sections': coverage.inferredSections,
      'notes': coverage.notes,
      'metadata': ValueReaders.deepCopyMap(coverage.metadata),
    };
  }

  ContinuityAssetReference parseAssetReference(JsonMap raw) {
    return ContinuityAssetReference(
      assetKind: _enumByName(
        ContinuityAssetKind.values,
        ValueReaders.stringValue(raw['asset_kind']),
        ContinuityAssetKind.characterProfile,
      ),
      assetId: ValueReaders.stringValue(raw['asset_id']).trim(),
      role: _enumByName(
        ContinuityAssetReferenceRole.values,
        ValueReaders.stringValue(raw['role']),
        ContinuityAssetReferenceRole.canonicalFact,
      ),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      sourcePath: ValueReaders.stringValue(raw['source_path']).trim(),
      note: ValueReaders.stringValue(raw['note']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap assetReferenceToDocument(ContinuityAssetReference reference) {
    return <String, Object?>{
      'asset_kind': reference.assetKind.name,
      'asset_id': reference.assetId,
      'role': reference.role.name,
      'display_name': reference.displayName,
      'source_path': reference.sourcePath,
      'note': reference.note,
      'metadata': ValueReaders.deepCopyMap(reference.metadata),
    };
  }

  ContinuationScope parseScope(JsonMap raw) {
    return ContinuationScope(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      kind: _enumByName(
        ContinuationScopeKind.values,
        ValueReaders.stringValue(raw['kind']),
        ContinuationScopeKind.custom,
      ),
      parentScopeId: ValueReaders.stringValue(raw['parent_scope_id']).trim(),
      tags: ValueReaders.stringList(raw['tags']),
      activationSignals: ValueReaders.stringList(raw['activation_signals']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap scopeToDocument(ContinuationScope scope) {
    return <String, Object?>{
      'id': scope.id,
      'display_name': scope.displayName,
      'kind': scope.kind.name,
      'parent_scope_id': scope.parentScopeId,
      'tags': scope.tags,
      'activation_signals': scope.activationSignals,
      'metadata': ValueReaders.deepCopyMap(scope.metadata),
    };
  }

  ContinuationScopeOverlay parseScopeOverlay(JsonMap raw) {
    return ContinuationScopeOverlay(
      id: ValueReaders.stringValue(raw['id']).trim(),
      scopeId: ValueReaders.stringValue(raw['scope_id']).trim(),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      priority: ValueReaders.intValue(raw['priority']),
      assetReferences: ValueReaders.objectList(raw['asset_references'])
          .map((item) => parseAssetReference(ValueReaders.mapValue(item)))
          .where((item) => item.assetId.isNotEmpty)
          .toList(growable: false),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap scopeOverlayToDocument(ContinuationScopeOverlay overlay) {
    return <String, Object?>{
      'id': overlay.id,
      'scope_id': overlay.scopeId,
      'display_name': overlay.displayName,
      'priority': overlay.priority,
      'asset_references': overlay.assetReferences
          .map(assetReferenceToDocument)
          .cast<Object?>()
          .toList(growable: false),
      'notes': overlay.notes,
      'metadata': ValueReaders.deepCopyMap(overlay.metadata),
    };
  }

  ContinuityMechanicProfile parseMechanicProfile(JsonMap raw) {
    return ContinuityMechanicProfile(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      identityMode: _enumByName(
        ContinuityIdentityMode.values,
        ValueReaders.stringValue(raw['identity_mode']),
        ContinuityIdentityMode.stable,
      ),
      memoryMode: _enumByName(
        ContinuityMemoryMode.values,
        ValueReaders.stringValue(raw['memory_mode']),
        ContinuityMemoryMode.continuous,
      ),
      stateMode: _enumByName(
        ContinuityStateMode.values,
        ValueReaders.stringValue(raw['state_mode']),
        ContinuityStateMode.accumulative,
      ),
      causalMode: _enumByName(
        ContinuityCausalMode.values,
        ValueReaders.stringValue(raw['causal_mode']),
        ContinuityCausalMode.linear,
      ),
      branchMode: _enumByName(
        ContinuityBranchMode.values,
        ValueReaders.stringValue(raw['branch_mode']),
        ContinuityBranchMode.singleLine,
      ),
      visibilityMode: _enumByName(
        ContinuityVisibilityMode.values,
        ValueReaders.stringValue(raw['visibility_mode']),
        ContinuityVisibilityMode.defaultVisible,
      ),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap mechanicProfileToDocument(ContinuityMechanicProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'identity_mode': profile.identityMode.name,
      'memory_mode': profile.memoryMode.name,
      'state_mode': profile.stateMode.name,
      'causal_mode': profile.causalMode.name,
      'branch_mode': profile.branchMode.name,
      'visibility_mode': profile.visibilityMode.name,
      'notes': profile.notes,
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }

  ContinuityFrame parseFrame(JsonMap raw) {
    return ContinuityFrame(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      scopeId: ValueReaders.stringValue(raw['scope_id']).trim(),
      mechanicProfileId: ValueReaders.stringValue(
        raw['mechanic_profile_id'],
      ).trim(),
      parentFrameId: ValueReaders.stringValue(raw['parent_frame_id']).trim(),
      relation: _enumByName(
        ContinuityFrameRelation.values,
        ValueReaders.stringValue(raw['relation']),
        ContinuityFrameRelation.sameLine,
      ),
      stateReferences: ValueReaders.objectList(raw['state_references'])
          .map((item) => parseAssetReference(ValueReaders.mapValue(item)))
          .where((item) => item.assetId.isNotEmpty)
          .toList(growable: false),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap frameToDocument(ContinuityFrame frame) {
    return <String, Object?>{
      'id': frame.id,
      'display_name': frame.displayName,
      'scope_id': frame.scopeId,
      'mechanic_profile_id': frame.mechanicProfileId,
      'parent_frame_id': frame.parentFrameId,
      'relation': frame.relation.name,
      'state_references': frame.stateReferences
          .map(assetReferenceToDocument)
          .cast<Object?>()
          .toList(growable: false),
      'notes': frame.notes,
      'metadata': ValueReaders.deepCopyMap(frame.metadata),
    };
  }

  ContinuityBuildSpec parseBuildSpec(JsonMap raw) {
    return ContinuityBuildSpec(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(raw['display_name']).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      tier: _buildTierFromRaw(ValueReaders.stringValue(raw['tier'])),
      focusScopeIds: ValueReaders.stringList(raw['focus_scope_ids']),
      focusFrameId: ValueReaders.stringValue(raw['focus_frame_id']).trim(),
      requestedOutputs: _buildOutputKinds(
        ValueReaders.stringList(raw['requested_outputs']),
      ),
      preferredRuntimeHost: _buildRuntimeHostFromRaw(
        ValueReaders.stringValue(raw['preferred_runtime_host']),
      ),
      recommended: ValueReaders.boolValue(raw['recommended']),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap buildSpecToDocument(ContinuityBuildSpec spec) {
    return <String, Object?>{
      'id': spec.id,
      'display_name': spec.displayName,
      'summary': spec.summary,
      'tier': spec.tier.name,
      'focus_scope_ids': spec.focusScopeIds,
      'focus_frame_id': spec.focusFrameId,
      'requested_outputs': spec.requestedOutputs
          .map((item) => item.name)
          .cast<Object?>()
          .toList(growable: false),
      'preferred_runtime_host': spec.preferredRuntimeHost.name,
      'recommended': spec.recommended,
      'notes': spec.notes,
      'metadata': ValueReaders.deepCopyMap(spec.metadata),
    };
  }

  ContinuityBuildTier _buildTierFromRaw(String raw) {
    final clean = raw.trim();
    switch (clean) {
      case 'quick':
      case 'quick_bridge':
        return ContinuityBuildTier.quickBridge;
      case 'standard':
      case 'standard_foundation':
        return ContinuityBuildTier.standardFoundation;
      case 'deep':
      case 'deep_reconstruction':
        return ContinuityBuildTier.deepReconstruction;
      default:
        return _enumByName(
          ContinuityBuildTier.values,
          clean,
          ContinuityBuildTier.standardFoundation,
        );
    }
  }

  List<ContinuityBuildOutputKind> _buildOutputKinds(List<String> rawOutputs) {
    return rawOutputs
        .map(_buildOutputKindFromRaw)
        .toSet()
        .toList(growable: false);
  }

  ContinuityBuildOutputKind _buildOutputKindFromRaw(String raw) {
    final clean = raw.trim();
    switch (clean) {
      case 'tail_bridge':
      case 'continuation_point':
        return ContinuityBuildOutputKind.tailBridge;
      case 'bible':
      case 'global_bible':
        return ContinuityBuildOutputKind.globalBible;
      case 'arc_summary':
      case 'arc_summaries':
      case 'stage_summaries':
        return ContinuityBuildOutputKind.stageSummaries;
      case 'state_snapshot':
      case 'state_snapshots':
      case 'state_tables':
        return ContinuityBuildOutputKind.stateTables;
      case 'conflict_gap_analysis':
      case 'conflict_report':
        return ContinuityBuildOutputKind.conflictGapAnalysis;
      default:
        return _enumByName(
          ContinuityBuildOutputKind.values,
          clean,
          ContinuityBuildOutputKind.tailBridge,
        );
    }
  }

  ContinuityBuildRuntimeHost _buildRuntimeHostFromRaw(String raw) {
    final clean = raw.trim();
    switch (clean) {
      case 'resumable':
      case 'resumable_workflow':
      case 'resumable_workflow_engine':
        return ContinuityBuildRuntimeHost.resumableWorkflowEngine;
      case 'direct':
      case 'direct_execution':
        return ContinuityBuildRuntimeHost.directExecution;
      default:
        return _enumByName(
          ContinuityBuildRuntimeHost.values,
          clean,
          ContinuityBuildRuntimeHost.directExecution,
        );
    }
  }

  T _enumByName<T extends Enum>(Iterable<T> values, String raw, T fallback) {
    final clean = raw.trim();
    for (final value in values) {
      if (value.name == clean) {
        return value;
      }
    }
    return fallback;
  }
}
