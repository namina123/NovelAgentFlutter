import '../inspiration/inspiration_convergence_stage_catalog_service.dart';
import '../inspiration/inspiration_field_key.dart';
import '../inspiration/inspiration_field_value.dart';
import '../inspiration/inspiration_record.dart';
import '../strategy/strategy_catalog_service.dart';
import 'mode_guidance_state.dart';

class ModeGuidanceInspirationRecordMapperService {
  const ModeGuidanceInspirationRecordMapperService({
    InspirationConvergenceStageCatalogService? stageCatalogService,
    StrategyCatalogService? strategyCatalogService,
  }) : _stageCatalogService =
           stageCatalogService ?? const InspirationConvergenceStageCatalogService(),
       _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final InspirationConvergenceStageCatalogService _stageCatalogService;
  final StrategyCatalogService _strategyCatalogService;

  InspirationRecord map(ModeGuidanceState state) {
    final fieldValues = <InspirationFieldValue>[];
    final completedStageIds = <String>{};
    for (final answer in state.answers) {
      final canonicalFieldKey = _canonicalFieldKey(answer.fieldKey);
      if (canonicalFieldKey.isEmpty) {
        continue;
      }
      final stageId = _stageCatalogService.stageIdForFieldKey(
        canonicalFieldKey,
      );
      if (stageId.isNotEmpty) {
        completedStageIds.add(stageId);
      }
      fieldValues.add(
        InspirationFieldValue(
          stageId: stageId,
          fieldKey: canonicalFieldKey,
          value: answer.value.trim(),
          label: answer.label,
          source: answer.source,
          updatedAt: answer.updatedAt,
        ),
      );
    }
    for (final rawStageId in state.completedStageIds) {
      final stageId = _canonicalStageId(rawStageId);
      if (stageId.isNotEmpty) {
        completedStageIds.add(stageId);
      }
    }
    if (state.isReady) {
      completedStageIds.add(InspirationConvergenceStageCatalogService.readyStageId);
    }
    return InspirationRecord(
      id: _recordId(state.modeId),
      title: _recordTitle(state.modeId),
      sourceId: state.modeId,
      fieldValues: fieldValues,
      completedStageIds: completedStageIds.toList(growable: false),
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      metadata: <String, Object?>{
        'project_strategy_id': state.projectStrategyId,
        'workflow_strategy_id': state.workflowStrategyId,
        'status': state.status,
      },
    );
  }

  String _recordId(String modeId) {
    final cleanModeId = modeId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    return 'mode_$cleanModeId';
  }

  String _recordTitle(String modeId) {
    for (final definition in _strategyCatalogService.modeDefinitions()) {
      if (definition.id == modeId.trim()) {
        return '${definition.title}灵感记录';
      }
    }
    return '灵感收束记录';
  }

  String _canonicalStageId(String rawStageId) {
    return _stageCatalogService.stageIdForFieldKey(_canonicalFieldKey(rawStageId));
  }

  String _canonicalFieldKey(String rawFieldKey) {
    switch (rawFieldKey.trim()) {
      case 'seed_scope':
        return InspirationFieldKey.seedMaterial;
      case 'book_premise':
        return InspirationFieldKey.premise;
      case 'core_promise':
        return InspirationFieldKey.corePromise;
      case 'main_arc':
        return InspirationFieldKey.mainArc;
      case 'volume_map':
        return InspirationFieldKey.volumeMap;
      case 'ending_commitment':
        return InspirationFieldKey.endingCommitment;
      case 'world_anchor':
        return InspirationFieldKey.worldAnchor;
      case 'protagonist_drive':
        return InspirationFieldKey.protagonistDrive;
      case 'style_target':
      case 'style_and_boundaries':
        return InspirationFieldKey.styleTarget;
      case 'autonomy_guardrails':
        return InspirationFieldKey.autonomyGuardrails;
      case 'review_ready':
      case 'consensus_confirm':
        return InspirationFieldKey.readySignal;
      default:
        return '';
    }
  }
}
