import 'character_profile.dart';
import 'character_stage_state_record.dart';
import 'character_state_update_plan.dart';
import 'character_state_update_request.dart';

class CharacterStateUpdatePlannerService {
  const CharacterStateUpdatePlannerService();

  CharacterStateUpdatePlan plan({
    required CharacterStateUpdateRequest request,
    CharacterProfile? existingProfile,
    String updatedAt = '',
  }) {
    // 中文注释: 规划器只决定“角色主档如何合并 + latest 状态如何表达”，不触碰任何文件系统细节。
    final current = existingProfile;
    final displayName = _displayNameOf(request, current);
    final characterId = _characterIdOf(request, current, displayName);
    final now = updatedAt.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : updatedAt.trim();
    final aliases = _mergeAliases(current, displayName);
    final nameHistory = _mergeNameHistory(current, displayName);
    final summary = _summaryOf(request, current);
    final currentStatus = _pickFirst(
      request.status,
      current?.currentStatus ?? '',
    );
    final currentStateSummary = _pickFirst(
      request.content,
      request.status,
      current?.currentStateSummary ?? '',
    );
    final latestStageLabel = _pickFirst(
      request.stageLabel,
      current?.latestStageLabel ?? '',
    );
    final storyRole = _pickFirst(request.role, current?.storyRole ?? '');
    final latestSourcePaths = request.sourcePaths.isEmpty
        ? (current?.latestSourcePaths ?? const <String>[])
        : request.sourcePaths;
    final profile = CharacterProfile(
      id: characterId,
      displayName: displayName,
      summary: summary,
      currentStatus: currentStatus,
      currentStateSummary: currentStateSummary,
      latestStageLabel: latestStageLabel,
      latestUpdatedAt: now,
      latestSourcePaths: latestSourcePaths,
      aliases: aliases,
      nameHistory: nameHistory,
      storyRole: storyRole,
      traits: current?.traits ?? const <String>[],
      organizationIds: current?.organizationIds ?? const <String>[],
      sourcePath: current?.sourcePath ?? '',
      metadata: <String, Object?>{...?current?.metadata, ...request.metadata},
    );
    final latestState = CharacterStageStateRecord(
      id: _stateRecordId(request, characterId),
      characterId: characterId,
      displayName: displayName,
      stageId: _safeToken(request.stageId),
      stageLabel: latestStageLabel,
      status: currentStatus,
      summary: currentStateSummary,
      sourcePaths: latestSourcePaths,
      relatedTimelineIds: request.relatedTimelineIds,
      updatedAt: now,
      metadata: <String, Object?>{'role': storyRole, ...request.metadata},
    );
    return CharacterStateUpdatePlan(profile: profile, latestState: latestState);
  }

  String _displayNameOf(
    CharacterStateUpdateRequest request,
    CharacterProfile? existingProfile,
  ) {
    return _pickFirst(
      request.name,
      existingProfile?.displayName ?? '',
      '未命名角色',
    );
  }

  String _characterIdOf(
    CharacterStateUpdateRequest request,
    CharacterProfile? existingProfile,
    String displayName,
  ) {
    return _pickFirst(
      request.characterId,
      existingProfile?.id ?? '',
      _safeToken(displayName),
      'character',
    );
  }

  List<String> _mergeAliases(
    CharacterProfile? existingProfile,
    String displayName,
  ) {
    final values = <String>[...?existingProfile?.aliases];
    final previousName = existingProfile?.displayName ?? '';
    if (previousName.trim().isNotEmpty && previousName.trim() != displayName) {
      values.add(previousName.trim());
    }
    return _deduplicate(values);
  }

  List<String> _mergeNameHistory(
    CharacterProfile? existingProfile,
    String displayName,
  ) {
    final values = <String>[...?existingProfile?.nameHistory];
    final previousName = existingProfile?.displayName ?? '';
    if (previousName.trim().isNotEmpty && previousName.trim() != displayName) {
      values.add(previousName.trim());
    }
    return _deduplicate(values);
  }

  String _summaryOf(
    CharacterStateUpdateRequest request,
    CharacterProfile? existingProfile,
  ) {
    return _pickFirst(
      existingProfile?.summary ?? '',
      request.content,
      request.status,
      '请补充角色简介。',
    );
  }

  String _stateRecordId(
    CharacterStateUpdateRequest request,
    String characterId,
  ) {
    final stageToken = _pickFirst(
      _safeToken(request.stageId),
      _safeToken(request.stageLabel),
      'latest',
    );
    return '$characterId.$stageToken';
  }

  String _pickFirst(
    String first, [
    String second = '',
    String third = '',
    String fourth = '',
  ]) {
    for (final candidate in <String>[first, second, third, fourth]) {
      if (candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }

  List<String> _deduplicate(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || result.contains(trimmed)) {
        continue;
      }
      result.add(trimmed);
    }
    return result;
  }

  String _safeToken(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result;
  }
}
