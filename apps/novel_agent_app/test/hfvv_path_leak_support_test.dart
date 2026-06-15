import 'package:flutter_test/flutter_test.dart';

import '../tool/hfvv_path_leak_support.dart';

void main() {
  group('HFVV path leak support', () {
    test('detects Windows absolute paths', () {
      expect(
        containsProbableAbsolutePathLeak('source=D:/repo/artifacts/report.md'),
        isTrue,
      );
      expect(
        containsProbableAbsolutePathLeak(
          'source="C:\\\\workspace\\\\project\\\\notes.txt"',
        ),
        isTrue,
      );
    });

    test('does not flag internal locator schemes as absolute paths', () {
      expect(
        containsProbableAbsolutePathLeak(
          'project-information://knowledge_cards/card-1',
        ),
        isFalse,
      );
      expect(
        containsProbableAbsolutePathLeak(
          'workspace-file://salt_city_setting_notes.md',
        ),
        isFalse,
      );
      expect(
        containsProbableAbsolutePathLeak('reference-entry://pkg/v1/entry-1'),
        isFalse,
      );
    });
  });
}
