import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RE0 smoke result exposes broad structured extraction buckets', () async {
    final resultFile = File(
      'D:/FlutterProjects/NovelAgentFlutter/artifacts/re0_book_deconstruction_smoke/workspace/re0_smoke_result.json',
    );
    expect(await resultFile.exists(), isTrue);
    final payload = jsonDecode(await resultFile.readAsString()) as Map<String, dynamic>;
    final previewTitles = (payload['preview_section_titles'] as List<dynamic>)
        .map((item) => item.toString())
        .toList(growable: false);

    expect(payload['source_length'], greaterThanOrEqualTo(300000));
    expect(payload['plan_group_count'], greaterThanOrEqualTo(8));
    expect(payload['total_item_count'], greaterThanOrEqualTo(40));
    expect(payload['has_continuity'], isTrue);
    expect(
      previewTitles,
      containsAll(<String>[
        '前提提取',
        '故事总纲',
        '章节骨架',
        '角色资产',
        '组织资产',
        '伏笔资产',
        '时间线资产',
        '关系资产',
      ]),
    );
  });
}
