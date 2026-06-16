import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'workflow_output_narrative_runtime_summary_renderer.dart';
import 'workflow_output_expression_constraint_summary_renderer.dart';
import 'workflow_output_reference_extraction_summary_renderer.dart';
import 'workflow_output_run_center_summary_renderer.dart';
import 'workflow_output_stop_diagnosis_text_service.dart';

class WorkflowOutputSummaryService {
  WorkflowOutputSummaryService({
    InformationEvidenceProjectionService? informationEvidenceProjectionService,
    ExpressionConstraintStatusProjectionService?
    expressionConstraintStatusProjectionService,
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
    ReferenceExtractionSupervisorSignalService?
    referenceExtractionSupervisorSignalService,
    StopDiagnosisTextService? stopDiagnosisTextService,
  }) : _runCenterSummaryRenderer = RunCenterSummaryRenderer(
         stopDiagnosisTextService: _stopDiagnosisTextServiceOrDefault(
           stopDiagnosisTextService,
         ),
       ),
       _narrativeRuntimeSummaryRenderer = NarrativeRuntimeSummaryRenderer(
         informationEvidenceProjectionService:
             informationEvidenceProjectionService ??
             const InformationEvidenceProjectionService(),
         expressionConstraintSummaryRenderer:
             ExpressionConstraintSummaryRenderer(
               expressionConstraintStatusProjectionService:
                   expressionConstraintStatusProjectionService ??
                   const ExpressionConstraintStatusProjectionService(),
             ),
         stopDiagnosisProjectionService:
             stopDiagnosisProjectionService ??
             const LongTaskStopDiagnosisProjectionService(),
         runCenterSummaryRenderer: RunCenterSummaryRenderer(
           stopDiagnosisTextService: _stopDiagnosisTextServiceOrDefault(
             stopDiagnosisTextService,
           ),
         ),
         stopDiagnosisTextService: _stopDiagnosisTextServiceOrDefault(
           stopDiagnosisTextService,
         ),
       ),
       _referenceExtractionSummaryRenderer = ReferenceExtractionSummaryRenderer(
         referenceExtractionSupervisorSignalService:
             referenceExtractionSupervisorSignalService ??
             const ReferenceExtractionSupervisorSignalService(),
         stopDiagnosisTextService: _stopDiagnosisTextServiceOrDefault(
           stopDiagnosisTextService,
         ),
       );

  final RunCenterSummaryRenderer _runCenterSummaryRenderer;
  final NarrativeRuntimeSummaryRenderer _narrativeRuntimeSummaryRenderer;
  final ReferenceExtractionSummaryRenderer _referenceExtractionSummaryRenderer;

  JsonMap extractRunCenterContract(JsonMap result) {
    // 中文注释: run center 合同直接委托给专用 renderer，CLI 只保留稳定 facade。
    return _runCenterSummaryRenderer.extractContract(result);
  }

  List<String> runCenterBriefLines(JsonMap contract) {
    // 中文注释: run center 摘要完全交给专用 renderer，避免壳层继续积累文本映射细节。
    return _runCenterSummaryRenderer.renderLines(contract);
  }

  JsonMap extractNarrativeRuntimeContract(JsonMap result) {
    // 中文注释: narrative 合同由专用 renderer 生成，facade 不再重复保存一份实现。
    return _narrativeRuntimeSummaryRenderer.extractContract(result);
  }

  List<String> narrativeBriefLines(JsonMap contract) {
    // 中文注释: narrative 摘要沿用专用 renderer 的生产侧投影，不在 facade 里二次加工。
    return _narrativeRuntimeSummaryRenderer.renderLines(contract);
  }

  List<String> referenceExtractionBriefLines(
    ProjectReferenceExtractionResult result, {
    String strategyLabel = '',
  }) {
    // 中文注释: reference extraction 摘要直接复用专用 renderer，保持 CLI 只消费生产同源合同。
    return _referenceExtractionSummaryRenderer.renderLines(
      result,
      strategyLabel: strategyLabel,
    );
  }

  static StopDiagnosisTextService _stopDiagnosisTextServiceOrDefault(
    StopDiagnosisTextService? stopDiagnosisTextService,
  ) {
    // 中文注释: stop diagnosis 文案服务统一复用同一个默认实例，避免不同 renderer 走出不一致的壳层映射。
    return stopDiagnosisTextService ?? const StopDiagnosisTextService();
  }
}
