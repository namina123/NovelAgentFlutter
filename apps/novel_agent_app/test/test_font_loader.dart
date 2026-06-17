import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoldenTestFontLoader {
  GoldenTestFontLoader._();

  static const String fontFamily = 'GoldenTestFont';
  static const String monospaceFontFamily = 'Consolas';
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    // 中文注释: 测试字体只服务金丝雀和截图稳定性，任何本机字体缺失都不应阻断普通 widget 测试。
    try {
      await _loadGoldenTextFont();
      await _loadManifestFonts();
    } catch (_) {
      // 中文注释: 字体加载失败时直接降级，避免测试启动阶段因为本机字体环境异常而整套退出。
    }
    _loaded = true;
  }

  static Future<void> _loadGoldenTextFont() async {
    final textLoader = FontLoader(fontFamily);
    var loadedAnyTextFont = false;
    for (final path in const <String>[
      r'C:\Windows\Fonts\msyh.ttc',
      r'C:\Windows\Fonts\msyhbd.ttc',
      r'C:\Windows\Fonts\msyhl.ttc',
      r'C:\Windows\Fonts\simhei.ttf',
      r'C:\Windows\Fonts\simsun.ttc',
    ]) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final bytes = await file.readAsBytes();
      textLoader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      loadedAnyTextFont = true;
    }
    if (loadedAnyTextFont) {
      await textLoader.load();
    }

    final monospaceLoader = FontLoader(monospaceFontFamily);
    var loadedAnyMonospaceFont = false;
    for (final path in const <String>[
      r'C:\Windows\Fonts\consola.ttf',
      r'C:\Windows\Fonts\consolab.ttf',
      r'C:\Windows\Fonts\CascadiaMono.ttf',
      r'C:\Windows\Fonts\CascadiaCode.ttf',
    ]) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final bytes = await file.readAsBytes();
      monospaceLoader.addFont(
        Future<ByteData>.value(ByteData.sublistView(bytes)),
      );
      loadedAnyMonospaceFont = true;
    }
    if (loadedAnyMonospaceFont) {
      await monospaceLoader.load();
    }
  }

  static ThemeData applyToTheme(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  static Future<void> _loadManifestFonts() async {
    final assetRoot = _resolveAssetRoot();
    if (assetRoot == null) {
      return;
    }
    final manifestFile = File(
      '${assetRoot.path}${Platform.pathSeparator}FontManifest.json',
    );
    if (!manifestFile.existsSync()) {
      return;
    }

    final rawManifest =
        jsonDecode(await manifestFile.readAsString()) as List<dynamic>;
    for (final entry in rawManifest) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final family = entry['family'];
      final fonts = entry['fonts'];
      if (family is! String || fonts is! List<dynamic>) {
        continue;
      }

      final loader = FontLoader(family);
      var loadedAny = false;
      for (final fontEntry in fonts) {
        if (fontEntry is! Map<String, dynamic>) {
          continue;
        }
        final asset = fontEntry['asset'];
        if (asset is! String) {
          continue;
        }
        final file = File(
          '${assetRoot.path}${Platform.pathSeparator}${asset.replaceAll('/', Platform.pathSeparator)}',
        );
        if (!file.existsSync()) {
          continue;
        }
        final bytes = await file.readAsBytes();
        loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
        loadedAny = true;
      }
      if (loadedAny) {
        await loader.load();
      }
    }
  }

  static Directory? _resolveAssetRoot() {
    final repoRoot = _resolveRepoRoot();
    for (final path in <String>[
      '${repoRoot.path}${Platform.pathSeparator}apps${Platform.pathSeparator}novel_agent_app${Platform.pathSeparator}build${Platform.pathSeparator}unit_test_assets',
      '${repoRoot.path}${Platform.pathSeparator}apps${Platform.pathSeparator}novel_agent_app${Platform.pathSeparator}build${Platform.pathSeparator}flutter_assets',
    ]) {
      final directory = Directory(path);
      if (directory.existsSync()) {
        return directory;
      }
    }
    return null;
  }

  static Directory _resolveRepoRoot() {
    var current = Directory.current.absolute;
    for (var depth = 0; depth < 8; depth += 1) {
      final pubspecFile = File(
        '${current.path}${Platform.pathSeparator}apps${Platform.pathSeparator}novel_agent_app${Platform.pathSeparator}pubspec.yaml',
      );
      if (pubspecFile.existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
    return Directory.current.absolute;
  }
}
