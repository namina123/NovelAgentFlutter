import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/shared/services/user_facing_error_humanizer.dart';

void main() {
  group('UserFacingErrorHumanizer', () {
    test('maps typed exceptions to human sentences', () {
      expect(
        UserFacingErrorHumanizer.humanize(TimeoutException('x')),
        contains('超时'),
      );
      expect(
        UserFacingErrorHumanizer.humanize(const SocketException('x')),
        contains('网络'),
      );
      expect(
        UserFacingErrorHumanizer.humanize(const FileSystemException('x')),
        contains('文件'),
      );
      expect(
        UserFacingErrorHumanizer.humanize(const FormatException('x')),
        contains('格式'),
      );
    });

    test('maps HTTP status hints embedded in plain strings', () {
      expect(
        UserFacingErrorHumanizer.humanize(Exception('HTTP 401 Unauthorized')),
        contains('鉴权'),
      );
      expect(
        UserFacingErrorHumanizer.humanize(Exception('HTTP 429 Too Many Requests')),
        contains('429'),
      );
      expect(
        UserFacingErrorHumanizer.humanize(Exception('context length exceeded')),
        contains('上下文'),
      );
    });

    test('never leaks raw Dart type names for unknown errors', () {
      final raw = Exception('SomeInternalTypeError: boom at stack_frame.dart:42');
      final humanized = UserFacingErrorHumanizer.humanize(raw, action: '生成');
      expect(humanized, contains('生成'));
      // 关键：绝不把原始 error.toString() 抛给用户。
      expect(humanized, isNot(contains('SomeInternalTypeError')));
      expect(humanized, isNot(contains('stack_frame.dart')));
    });

    test('falls back to action-named message when nothing matches', () {
      expect(
        UserFacingErrorHumanizer.humanize(Exception('mystery'), action: '保存'),
        contains('保存失败'),
      );
    });

    test('handles null without throwing', () {
      expect(
        UserFacingErrorHumanizer.humanize(null, action: '操作'),
        contains('操作失败'),
      );
    });
  });
}
