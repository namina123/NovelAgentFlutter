import 'package:flutter/material.dart';

class AppChrome {
  // 中文注释: 圆角统一到 8，与 novelPanelChrome.radius（工作台主面板）一致——
  // 消除原先 8/10 两套并存导致的边角不齐（设置页 10 vs 工作台 8）。
  static const double surfaceRadius = 8;
  static const double controlRadius = 8;
  static const double borderWidth = 1;
  static const BorderRadius surfaceBorderRadius = BorderRadius.all(
    Radius.circular(surfaceRadius),
  );
  static const BorderRadius controlBorderRadius = BorderRadius.all(
    Radius.circular(controlRadius),
  );
  static const List<BoxShadow> noShadow = <BoxShadow>[];

  const AppChrome._();

  static RoundedRectangleBorder controlShape({
    required Color sideColor,
    double borderRadius = controlRadius,
    double borderWidth = AppChrome.borderWidth,
  }) {
    // 中文注释: 统一控件外形，避免不同页面各自维护圆角风格而让工作区显得松散。
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: sideColor, width: borderWidth),
    );
  }

  static OutlineInputBorder inputBorder({
    required Color sideColor,
    double borderRadius = controlRadius,
    double borderWidth = AppChrome.borderWidth,
  }) {
    // 中文注释: 输入框边框同样走一套直角规范，便于后续整体调整界面语言。
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: sideColor, width: borderWidth),
    );
  }
}
