import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordinary gui viewmodel probe stays on generic opening follow-up', () {
    final source = File(
      'tool/real_gui_viewmodel_information_long_task_probe.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("const String _ordinaryWorkbenchTitle = '普通会话：开篇筹备与资料核查';"),
    );
    expect(source, contains('不要把普通开篇输入直接短路成“产出第一章正文交付”'));
    expect(source, isNot(contains("title: '第01章《醒在败家子床上》'")));
  });
}
