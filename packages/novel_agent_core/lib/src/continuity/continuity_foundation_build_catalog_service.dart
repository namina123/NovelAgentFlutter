import 'continuity_build_spec.dart';
import 'continuity_foundation_build_flow.dart';
import 'continuity_foundation_build_stage.dart';

class ContinuityFoundationBuildCatalogService {
  const ContinuityFoundationBuildCatalogService();

  List<ContinuityBuildSpec> builtinSpecs({
    List<String> focusScopeIds = const <String>[],
    String focusFrameId = '',
  }) {
    return <ContinuityBuildSpec>[
      specOfTier(
        ContinuityBuildTier.quickBridge,
        focusScopeIds: focusScopeIds,
        focusFrameId: focusFrameId,
      ),
      specOfTier(
        ContinuityBuildTier.standardFoundation,
        focusScopeIds: focusScopeIds,
        focusFrameId: focusFrameId,
      ),
      specOfTier(
        ContinuityBuildTier.deepReconstruction,
        focusScopeIds: focusScopeIds,
        focusFrameId: focusFrameId,
      ),
    ];
  }

  ContinuityBuildSpec specOfTier(
    ContinuityBuildTier tier, {
    List<String> focusScopeIds = const <String>[],
    String focusFrameId = '',
  }) {
    switch (tier) {
      case ContinuityBuildTier.quickBridge:
        return ContinuityBuildSpec(
          id: 'quick_bridge',
          displayName: '快速承接',
          summary: '聚焦最近剧情承接、尾部窗口与近期状态，尽快进入续写。',
          tier: tier,
          focusScopeIds: focusScopeIds,
          focusFrameId: focusFrameId,
          requestedOutputs: const <ContinuityBuildOutputKind>[
            ContinuityBuildOutputKind.tailBridge,
            ContinuityBuildOutputKind.stateTables,
          ],
          preferredRuntimeHost: ContinuityBuildRuntimeHost.directExecution,
          metadata: const <String, Object?>{
            'build_kind': 'continuation_foundation',
          },
        );
      case ContinuityBuildTier.standardFoundation:
        return ContinuityBuildSpec(
          id: 'standard_foundation',
          displayName: '标准基座',
          summary: '默认推荐档，补齐全局圣经、分阶段摘要、状态表与尾部承接。',
          tier: tier,
          focusScopeIds: focusScopeIds,
          focusFrameId: focusFrameId,
          requestedOutputs: const <ContinuityBuildOutputKind>[
            ContinuityBuildOutputKind.tailBridge,
            ContinuityBuildOutputKind.globalBible,
            ContinuityBuildOutputKind.stageSummaries,
            ContinuityBuildOutputKind.stateTables,
          ],
          preferredRuntimeHost:
              ContinuityBuildRuntimeHost.resumableWorkflowEngine,
          recommended: true,
          metadata: const <String, Object?>{
            'build_kind': 'continuation_foundation',
          },
        );
      case ContinuityBuildTier.deepReconstruction:
        return ContinuityBuildSpec(
          id: 'deep_reconstruction',
          displayName: '深度重构',
          summary: '面向超长篇或结构混乱项目，补齐重构摘要与冲突缺口分析。',
          tier: tier,
          focusScopeIds: focusScopeIds,
          focusFrameId: focusFrameId,
          requestedOutputs: const <ContinuityBuildOutputKind>[
            ContinuityBuildOutputKind.tailBridge,
            ContinuityBuildOutputKind.globalBible,
            ContinuityBuildOutputKind.stageSummaries,
            ContinuityBuildOutputKind.stateTables,
            ContinuityBuildOutputKind.conflictGapAnalysis,
          ],
          preferredRuntimeHost:
              ContinuityBuildRuntimeHost.resumableWorkflowEngine,
          metadata: const <String, Object?>{
            'build_kind': 'continuation_foundation',
          },
        );
    }
  }

  ContinuityFoundationBuildFlow buildFlowFor(ContinuityBuildSpec spec) {
    final resumable =
        spec.preferredRuntimeHost ==
        ContinuityBuildRuntimeHost.resumableWorkflowEngine;
    return ContinuityFoundationBuildFlow(
      id: 'continuation_foundation_build',
      displayName: '续写基座构建',
      summary: _flowSummary(spec.tier),
      runtimeHost: spec.preferredRuntimeHost,
      supportsStepRetry: resumable,
      supportsPartialArtifacts: resumable,
      stages: const <ContinuityFoundationBuildStage>[
        ContinuityFoundationBuildStage(
          kind: ContinuityFoundationBuildStageKind.preview,
          displayName: '预览',
          summary: '生成覆盖范围、计划输出与风险预览，先确认材料是否足够承接续写。',
        ),
        ContinuityFoundationBuildStage(
          kind: ContinuityFoundationBuildStageKind.confirm,
          displayName: '确认',
          summary: '确认构建规格、关注范围与默认后续导向。',
          requiresUserInput: true,
        ),
        ContinuityFoundationBuildStage(
          kind: ContinuityFoundationBuildStageKind.build,
          displayName: '构建',
          summary: '运行多层摘要、实体归一、状态收束与连续性约束生成。',
          buildsArtifacts: true,
        ),
        ContinuityFoundationBuildStage(
          kind: ContinuityFoundationBuildStageKind.publish,
          displayName: '发布',
          summary: '发布为可复用的续写基座，并写入运行时索引与读取映射。',
          publishesArtifacts: true,
        ),
      ],
      metadata: <String, Object?>{'spec_id': spec.id, 'tier': spec.tier.name},
    );
  }

  String _flowSummary(ContinuityBuildTier tier) {
    switch (tier) {
      case ContinuityBuildTier.quickBridge:
        return '轻量续写基座流程，偏重尾部承接与近期状态，不强制进入可恢复运行链。';
      case ContinuityBuildTier.standardFoundation:
        return '默认推荐的续写基座流程，按预览/确认/构建/发布四阶段稳定产出标准基座。';
      case ContinuityBuildTier.deepReconstruction:
        return '面向超长篇与复杂旧稿的重构流程，允许逐步重试并保留部分构建产物。';
    }
  }
}
