import '../common/json_types.dart';

final class ContextSectionCatalog {
  static const JsonMap kindRoots = <String, Object?>{
    'styles': <String, Object?>{
      'title': '风格文件',
      'priority': 86,
      'prefixes': <Object?>['assets/styles/', 'styles/'],
    },
    'summaries': <String, Object?>{'title': '摘要记忆', 'priority': 82},
    'world': <String, Object?>{
      'title': '世界书',
      'priority': 78,
      'prefixes': <Object?>['assets/world/', 'world/'],
    },
    'characters': <String, Object?>{
      'title': '角色状态',
      'priority': 76,
      'prefixes': <Object?>['assets/characters/', 'characters/'],
    },
    'tasks': <String, Object?>{'title': '任务状态', 'priority': 74},
    'tracking': <String, Object?>{'title': '追踪记录', 'priority': 70},
  };
}
