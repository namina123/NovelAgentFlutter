import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/probe_support.dart';
import '../../../tools/probe_config_support.dart';

void main() {
  group('probe support', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_probe_support_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'loadProbeApiConfig reads override file with explicit opt-in',
      () async {
        final overrideDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}custom',
        )..createSync(recursive: true);
        final overrideFile = File(
          '${overrideDirectory.path}${Platform.pathSeparator}probe_api.txt',
        );
        await overrideFile.writeAsString(
          ['https://example.invalid/v1', 'test-key', 'test-model'].join('\n'),
        );

        final config = await loadProbeApiConfig(
          probeName: 'probe_support_test',
          repoRootOverride: tempDirectory.path,
          allowLegacyTestApi: false,
          allowTempSettingsFallback: false,
          environment: <String, String>{
            'NOVEL_AGENT_ENABLE_REAL_PROBES': '1',
            'NOVEL_AGENT_PROBE_API_FILE': 'custom/probe_api.txt',
          },
        );

        expect(config.baseUrl, 'https://example.invalid/v1');
        expect(config.apiKey, 'test-key');
        expect(config.modelId, 'test-model');
      },
    );

    test('ensureLocalRealProbeOptInWithEnvironment rejects missing opt-in', () {
      expect(
        () => ensureLocalRealProbeOptInWithEnvironment(
          probeName: 'probe_support_test',
          environment: const <String, String>{},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'classifyDraftProbeReportCategory distinguishes waiting budget content and technical failures',
      () {
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'waiting_for_user_choice': true,
            },
          ),
          ProbeReportCategories.waitingUser,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            errorSummary: 'maximum context length exceeded',
          ),
          ProbeReportCategories.budgetFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'summary': 'missing delivery contract',
            },
          ),
          ProbeReportCategories.contentQualityFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            errorSummary: 'socket closed unexpectedly',
          ),
          ProbeReportCategories.technicalFailure,
        );
      },
    );
  });
}
