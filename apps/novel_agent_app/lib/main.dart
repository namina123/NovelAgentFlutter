import 'app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  // 中文注释: GUI 应用入口只负责把控制权交给 bootstrap，避免入口文件承接组装细节。
  await AppBootstrap().run();
}
