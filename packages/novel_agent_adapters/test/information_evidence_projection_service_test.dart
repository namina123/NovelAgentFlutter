import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('InformationEvidenceProjectionService', () {
    const service = InformationEvidenceProjectionService();

    test('projects need-information summary and projection paths', () {
      final projection = service.fromWorkflowInformationContract(
        <String, Object?>{
          'present': true,
          'knowledge_count': 1,
          'pending_research_count': 1,
          'projection_paths': <Object?>[
            'knowledge/项目知识摘要.md',
            'research/资料研究摘要.md',
          ],
        },
      );

      expect(projection.status, 'need_information');
      expect(projection.statusLabel, '需要资料');
      expect(projection.summary, '当前仍有资料缺口：待补资料 1 项。');
      expect(projection.userLines, contains('资料状态：需要资料'));
      expect(
        projection.userLines,
        contains('资料摘要：knowledge/项目知识摘要.md | research/资料研究摘要.md'),
      );
      expect(projection.diagnosticLines, contains('pending_research_count=1'));
    });

    test('projects waiting confirmation and keeps diagnostics separate', () {
      final projection = service.fromWorkflowInformationContract(
        const <String, Object?>{
          'knowledge_count': 1,
          'summary': '需要先确认是否联网继续研究。',
          'risk_category': 'checkpoint_user',
          'projection_paths': <Object?>['research/资料研究摘要.md'],
        },
        permissionRecords: <Map<String, Object?>>[
          <String, Object?>{
            'relative_path':
                '.novel_agent/information/research_requests/request-1.json',
            'record': <String, Object?>{
              'request_id': 'request-1',
              'request_state': 'awaiting_user_confirmation',
              'research_request': <String, Object?>{'query': '北境钟楼民俗'},
            },
          },
        ],
      );

      expect(projection.status, 'waiting_confirmation');
      expect(projection.statusLabel, '等待确认');
      expect(projection.summary, '需要先确认是否联网继续研究。');
      expect(projection.userActionItems, hasLength(1));
      expect(projection.userActionItems.first.title, '资料待确认');
      expect(
        projection.userLines.any((line) => line.contains('risk_category')),
        isFalse,
      );
      expect(
        projection.diagnosticLines,
        contains('risk_category=checkpoint_user'),
      );
      expect(
        projection.diagnosticLines,
        contains('awaiting_confirmation_count=1'),
      );
    });

    test('projects rejected and source-insufficient states', () {
      final rejectedProjection = service.fromWorkflowInformationContract(
        const <String, Object?>{
          'projection_paths': <Object?>['references/引用作品边界.md'],
        },
        permissionRecords: <Map<String, Object?>>[
          <String, Object?>{
            'relative_path':
                '.novel_agent/information/research_requests/request-2.json',
            'record': <String, Object?>{
              'request_id': 'request-2',
              'request_state': 'rejected',
              'resolution_note': '暂时不允许联网补资料。',
              'research_request': <String, Object?>{'query': '王城币制'},
            },
          },
        ],
      );

      final sourceProjection = service.fromWorkflowInformationContract(
        const <String, Object?>{
          'rigorous_source_insufficient_count': 2,
          'research_count': 1,
        },
      );

      expect(rejectedProjection.status, 'rejected');
      expect(rejectedProjection.summary, '有 1 项资料请求已拒绝，当前保留资料缺口。');
      expect(rejectedProjection.userActionItems.first.title, '资料已拒绝');

      expect(sourceProjection.status, 'source_insufficient');
      expect(sourceProjection.statusLabel, '来源不足');
      expect(sourceProjection.summary, '已补充资料，但有 2 项来源仍不足。');
    });

    test(
      'projects writing execution information with changed projection paths',
      () {
        final projection = service.fromWritingExecutionInformation(
          <String, Object?>{
            'present': true,
            'summary': '已补充资料摘要。',
            'risk_category': 'accept',
            'changed_paths': <Object?>[
              '.novel_agent/information/research_notes/research_note_1.json',
              'research/资料研究摘要.md',
            ],
            'evidence_gate': <String, Object?>{
              'rigorous_source_insufficient_count': 1,
            },
          },
        );

        expect(projection.status, 'source_insufficient');
        expect(projection.researchCount, 1);
        expect(projection.projectionPaths, <String>['research/资料研究摘要.md']);
        expect(
          projection.projectionItems.map((item) => item.relativePath),
          <String>['research/资料研究摘要.md'],
        );
      },
    );

    test(
      'does not fabricate default projection paths when only sqlite-first records changed',
      () {
        final projection = service
            .fromWorkflowInformationContract(<String, Object?>{
              'present': true,
              'knowledge_count': 1,
              'summary': '已补充 1 条知识记录。',
              'projection_paths': const <Object?>[],
            });

        expect(projection.projectionPaths, isEmpty);
        expect(projection.projectionItems, isEmpty);
        expect(
          projection.userLines.any((line) => line.contains('资料摘要：')),
          isFalse,
        );
      },
    );
  });
}
