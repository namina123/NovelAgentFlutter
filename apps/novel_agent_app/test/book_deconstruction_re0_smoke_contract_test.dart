import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final resultFile = _resultFile();
  test(
    'RE0 smoke result exposes broad structured extraction buckets',
    () async {
    final payload =
        jsonDecode(await resultFile.readAsString()) as Map<String, dynamic>;
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
        '角色资产',
        '组织资产',
        '伏笔资产',
        '时间线资产',
        '关系资产',
      ]),
    );
    },
    skip: resultFile.existsSync()
        ? false
        : '需要先运行 tool/re0_book_deconstruction_smoke.dart 生成验收产物。',
  );
}

File _resultFile() {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}${Platform.pathSeparator}.git').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('无法定位仓库根目录。');
    }
    directory = parent;
  }
  return File(
    '${directory.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}re0_book_deconstruction_smoke${Platform.pathSeparator}workspace${Platform.pathSeparator}re0_smoke_result.json',
  );
}
