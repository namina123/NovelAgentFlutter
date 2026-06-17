import 'package:flutter_test/flutter_test.dart';

import '../tool/probe_support.dart';

void main() {
  test(
    'real GUI viewmodel information long task probe reports contract conflict when file evidence and viewmodel projection disagree',
    () {
      final validation = <String, Object?>{
        'ordinary_workbench_step': <String, Object?>{
          'ok': true,
          'expression_constraint_report': <String, Object?>{},
        },
        'long_task_batches': <String, Object?>{
          'ok': true,
          'batches': const <Object?>[],
        },
        'gui_viewmodel': <String, Object?>{
          'workbench_information_viewmodel': <String, Object?>{
            'has_content': false,
          },
          'long_task_station_viewmodel': <String, Object?>{'total_count': 1},
          'project_file_counts': <String, Object?>{
            'chapter_files': 1,
            'research_notes': 0,
            'research_requests': 1,
          },
        },
      };

      final reportCategory = classifyDraftProbeReportCategory(
        ok: false,
        validation: validation,
      );

      expect(reportCategory, ProbeReportCategories.contractConflict);
    },
  );
}
