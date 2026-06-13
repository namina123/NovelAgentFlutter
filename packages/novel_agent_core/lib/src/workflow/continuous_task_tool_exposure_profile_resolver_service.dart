import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/tool_capability_exposure_policy.dart';
import '../tools/tool_capability_family_catalog_service.dart';
import '../tools/tool_exposure_level.dart';
import 'continuous_task_family.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_run_kind.dart';
import 'continuous_task_tool_exposure_profile.dart';

class ContinuousTaskToolExposureProfileResolverService {
  const ContinuousTaskToolExposureProfileResolverService();

  ContinuousTaskToolExposureProfile resolveForTaskProfile(
    ContinuousTaskProfile taskProfile,
  ) {
    return resolve(
      familyId: taskProfile.familyId,
      runKind: taskProfile.runKind,
      metadata: <String, Object?>{
        'source_contract': 'continuous_task_profile_binding',
        if (taskProfile.workflowStrategyId.trim().isNotEmpty)
          'workflow_strategy_id': taskProfile.workflowStrategyId,
        if (taskProfile.modeId.trim().isNotEmpty) 'mode_id': taskProfile.modeId,
      },
    );
  }

  ContinuousTaskToolExposureProfile resolve({
    required String familyId,
    required String runKind,
    JsonMap metadata = const <String, Object?>{},
  }) {
    final cleanFamilyId = familyId.trim();
    switch (cleanFamilyId) {
      case ContinuousTaskFamilies.longFormWriting:
        return _buildProfile(
          profileId: 'long_form_writing.default',
          taskFamilyId: cleanFamilyId,
          runKind: runKind.trim().isEmpty
              ? ContinuousTaskRunKinds.chapterQueue
              : runKind.trim(),
          policies: <ToolCapabilityExposurePolicy>[
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
              rationale: '写作主链默认消费已挂载知识与摘要，不默认回到源材料重提取。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.writing,
              rationale: '长篇写作任务默认需要交付正文与叙事状态更新能力。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.review,
              rationale: '写作主链允许直接提交结构化复核与澄清结果。',
            ),
            _requiresConfirmation(
              ToolCapabilityFamilyCatalogService.research,
              rationale: '写作中若发现知识缺口，可申请研究能力，但不应默认展开重研究侧链。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceExtraction,
              rationale: '重型提取归档不默认铺给普通写作线程，应由提取/研究子流程承接。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceMountCommit,
              rationale: '项目事实源挂载与提交由宿主或 supervisor 控制，不交给普通写作轮次自行裁定。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.continuousTaskControl,
              rationale: '连续任务控制面能力属于宿主 / supervisor 权限边界。',
            ),
          ],
          metadata: metadata,
        );
      case ContinuousTaskFamilies.goalMode:
        return _buildProfile(
          profileId: 'goal_mode.default',
          taskFamilyId: cleanFamilyId,
          runKind: runKind.trim().isEmpty
              ? ContinuousTaskRunKinds.conversationLoop
              : runKind.trim(),
          policies: <ToolCapabilityExposurePolicy>[
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
              rationale: '目标模式默认优先消费已存在的挂载结果，避免轻量连续任务直接膨胀成提取侧链。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.review,
              rationale: '目标模式允许通过结构化澄清与复核维持目标连续推进。',
            ),
            _requiresConfirmation(
              ToolCapabilityFamilyCatalogService.writing,
              rationale: '目标模式可能演化成正文交付，但不应在未确认时默认进入正式写作产出。',
            ),
            _requiresConfirmation(
              ToolCapabilityFamilyCatalogService.research,
              rationale: '目标模式需要研究时应由明确确认或策略层放行，而不是默认拿满研究能力。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceExtraction,
              rationale: '重型提取能力不属于目标模式默认开放面。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceMountCommit,
              rationale: '挂载提交仍由宿主 / supervisor 负责。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.continuousTaskControl,
              rationale: '目标模式与其他连续任务族共享同一控制面宿主边界。',
            ),
          ],
          metadata: metadata,
        );
      case ContinuousTaskFamilies.referenceExtraction:
        return _buildProfile(
          profileId: 'reference_extraction.default',
          taskFamilyId: cleanFamilyId,
          runKind: runKind.trim().isEmpty
              ? ContinuousTaskRunKinds.batchPipeline
              : runKind.trim(),
          policies: <ToolCapabilityExposurePolicy>[
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
              rationale: '提取链也需要回读已挂载结果与摘要，避免重复抽取相同事实。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.review,
              rationale: '提取任务默认需要结构化复核与澄清能力。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.research,
              rationale: '提取/研究智能体组默认拥有研究采集能力，但具体联网仍受宿主权限控制。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.referenceExtraction,
              rationale: '重型提取归档能力默认属于提取主链，而不是写作线程的常驻能力。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceMountCommit,
              rationale: 'sqlite-first 挂载确认与项目事实源提交由宿主或 supervisor 收口。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.continuousTaskControl,
              rationale: '批次续跑、控制命令与生命周期切换由连续任务控制面统一裁定。',
            ),
          ],
          metadata: metadata,
        );
      case ContinuousTaskFamilies.researchConsolidation:
        return _buildProfile(
          profileId: 'research_consolidation.default',
          taskFamilyId: cleanFamilyId,
          runKind: runKind.trim().isEmpty
              ? ContinuousTaskRunKinds.researchSweep
              : runKind.trim(),
          policies: <ToolCapabilityExposurePolicy>[
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
              rationale: '研究整编先消费既有挂载结果，再决定是否扩展采集。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.review,
              rationale: '研究整编默认需要结构化复核与澄清能力。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.research,
              rationale: '研究整编默认拥有研究采集能力。',
            ),
            _defaultOpen(
              ToolCapabilityFamilyCatalogService.referenceExtraction,
              rationale: '研究整编可直接沉淀知识卡、设计元素与证据链接，不必借写作线程转手。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.referenceMountCommit,
              rationale: '研究结果进入项目主事实源前仍由宿主 / supervisor 确认挂载出口。',
            ),
            _hostOnly(
              ToolCapabilityFamilyCatalogService.continuousTaskControl,
              rationale: '研究整编与其他连续任务族共享同一控制面，不单独自管 pause/resume。',
            ),
          ],
          metadata: metadata,
        );
    }
    return _buildProfile(
      profileId: 'custom_continuous_task.default',
      taskFamilyId: cleanFamilyId,
      runKind: runKind.trim().isEmpty
          ? ContinuousTaskRunKinds.conversationLoop
          : runKind.trim(),
      policies: <ToolCapabilityExposurePolicy>[
        _defaultOpen(
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          rationale: '自定义连续任务默认只消费已挂载结果。',
        ),
        _requiresConfirmation(
          ToolCapabilityFamilyCatalogService.research,
          rationale: '自定义任务需要研究时应显式确认。',
        ),
        _hostOnly(
          ToolCapabilityFamilyCatalogService.continuousTaskControl,
          rationale: '连续任务控制命令保留在宿主 / supervisor 边界。',
        ),
      ],
      metadata: metadata,
    );
  }

  ContinuousTaskToolExposureProfile _buildProfile({
    required String profileId,
    required String taskFamilyId,
    required String runKind,
    required List<ToolCapabilityExposurePolicy> policies,
    JsonMap metadata = const <String, Object?>{},
  }) {
    return ContinuousTaskToolExposureProfile(
      profileId: profileId,
      taskFamilyId: taskFamilyId,
      runKind: runKind,
      capabilityPolicies: List<ToolCapabilityExposurePolicy>.unmodifiable(
        policies,
      ),
      metadata: <String, Object?>{
        'binding_contract': 'continuous_task_tool_exposure_profile',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ToolCapabilityExposurePolicy _defaultOpen(
    String familyId, {
    required String rationale,
  }) {
    return ToolCapabilityExposurePolicy(
      familyId: familyId,
      exposureLevel: ToolExposureLevels.defaultOpen,
      rationale: rationale,
    );
  }

  ToolCapabilityExposurePolicy _requiresConfirmation(
    String familyId, {
    required String rationale,
  }) {
    return ToolCapabilityExposurePolicy(
      familyId: familyId,
      exposureLevel: ToolExposureLevels.requiresConfirmation,
      rationale: rationale,
    );
  }

  ToolCapabilityExposurePolicy _hostOnly(
    String familyId, {
    required String rationale,
  }) {
    return ToolCapabilityExposurePolicy(
      familyId: familyId,
      exposureLevel: ToolExposureLevels.hostOrSupervisorOnly,
      rationale: rationale,
    );
  }
}
