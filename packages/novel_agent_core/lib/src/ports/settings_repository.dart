import '../settings/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<AppSettings> save(AppSettings settings);
}
