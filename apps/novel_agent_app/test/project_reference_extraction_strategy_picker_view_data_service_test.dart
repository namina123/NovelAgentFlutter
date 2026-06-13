import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_strategy_picker_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('picker service exposes builtin options and normalizes selection', () {
    const service = ProjectReferenceExtractionStrategyPickerViewDataService();

    final picker = service.build(
      selectedProfileId: 'reference_extraction.unknown_profile',
    );

    expect(
      picker.selectedProfileId,
      ReferenceExtractionBuiltinStrategyProfileIds.standard,
    );
    expect(
      picker.options.map((item) => item.displayName),
      containsAll(<String>['标准提取', '长上下文整书', '事实优先', '探索扩展']),
    );
    expect(picker.summary, contains('标准提取'));
  });
}
