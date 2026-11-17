import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/palette.dart';
import '../../domain/now_marker.dart';

/// 选时间的两种方式
enum TimePickerMode { dial, wheel }

/// 手感/外观相关的偏好：手柄大小、泳道间距、现在时刻标识、缩放滑块显隐
class UiPrefs {
  const UiPrefs({
    this.handleScale = 1.0,
    this.laneGapScale = 1.0,
    this.nowMarkerStyle = NowMarkerStyle.pill,
    this.nowMarkerIcon = 0,
    this.showZoomSlider = true,
    this.themeMode = AppThemeMode.system,
    this.zoomSliderExpanded = true,
    this.stripTextScale = 1.0,
    this.stripShowLeft = true,
    this.stripShowRight = true,
    this.stripLineRatio = 1.0,
    this.timePickerMode = TimePickerMode.dial,
    this.nowMarkerSize = 1.0,
    this.nowMarkerRight = false,
    this.nowMarkerColorIndex = 0,
    this.nowLineColorIndex = 0,
    this.nowLineWidth = 1.6,
    this.nowMarkerDoodle = '',
    this.onboarded = false,
  });

  /// 上下把手的大小倍率（0.8 ~ 1.6）
  final double handleScale;

  /// 泳道之间的间距倍率（0 ~ 1.5，0 表示贴在一起）
  final double laneGapScale;

  /// 「现在时刻」那根线的标识款式
  final NowMarkerStyle nowMarkerStyle;

  /// 「自定义图案」款式下选中的图标下标
  final int nowMarkerIcon;

  /// 右侧竖着的缩放滑块显不显示（嫌碍事就关掉，双指缩放还在）
  final bool showZoomSlider;
  final AppThemeMode themeMode;

  /// 右侧滑块当前是展开还是收成小箭头
  final bool zoomSliderExpanded;

  /// 时间条：文字大小 / 左右两栏是否显示 / 中间线路占多宽
  final double stripTextScale;
  final bool stripShowLeft;
  final bool stripShowRight;
  final double stripLineRatio;

  /// 现在时刻标识 / 现在线：大小、位置（靠左还是靠右）、颜色、线宽、手绘图案
  final TimePickerMode timePickerMode;
  final double nowMarkerSize;
  final bool nowMarkerRight;
  final int nowMarkerColorIndex;
  final int nowLineColorIndex;
  final double nowLineWidth;
  final String nowMarkerDoodle;

  /// 首次启动引导有没有看过
  final bool onboarded;

  static const double minHandle = 0.8;
  static const double maxHandle = 1.6;
  static const double minLaneGap = 0;
  static const double maxLaneGap = 1.5;

  UiPrefs copyWith({
    double? handleScale,
    double? laneGapScale,
    NowMarkerStyle? nowMarkerStyle,
    int? nowMarkerIcon,
    bool? showZoomSlider,
    AppThemeMode? themeMode,
    bool? zoomSliderExpanded,
    double? stripTextScale,
    bool? stripShowLeft,
    bool? stripShowRight,
    double? stripLineRatio,
    TimePickerMode? timePickerMode,
    double? nowMarkerSize,
    bool? nowMarkerRight,
    int? nowMarkerColorIndex,
    int? nowLineColorIndex,
    double? nowLineWidth,
    String? nowMarkerDoodle,
    bool? onboarded,
  }) =>
      UiPrefs(
        handleScale: handleScale ?? this.handleScale,
        laneGapScale: laneGapScale ?? this.laneGapScale,
        nowMarkerStyle: nowMarkerStyle ?? this.nowMarkerStyle,
        nowMarkerIcon: nowMarkerIcon ?? this.nowMarkerIcon,
        showZoomSlider: showZoomSlider ?? this.showZoomSlider,
      themeMode: themeMode ?? this.themeMode,
        zoomSliderExpanded: zoomSliderExpanded ?? this.zoomSliderExpanded,
        stripTextScale: stripTextScale ?? this.stripTextScale,
        stripShowLeft: stripShowLeft ?? this.stripShowLeft,
        stripShowRight: stripShowRight ?? this.stripShowRight,
        stripLineRatio: stripLineRatio ?? this.stripLineRatio,
        timePickerMode: timePickerMode ?? this.timePickerMode,
        nowMarkerSize: nowMarkerSize ?? this.nowMarkerSize,
        nowMarkerRight: nowMarkerRight ?? this.nowMarkerRight,
        nowMarkerColorIndex: nowMarkerColorIndex ?? this.nowMarkerColorIndex,
        nowLineColorIndex: nowLineColorIndex ?? this.nowLineColorIndex,
        nowLineWidth: nowLineWidth ?? this.nowLineWidth,
        nowMarkerDoodle: nowMarkerDoodle ?? this.nowMarkerDoodle,
        onboarded: onboarded ?? this.onboarded,
      );

  @override
  bool operator ==(Object other) =>
      other is UiPrefs &&
      other.handleScale == handleScale &&
      other.laneGapScale == laneGapScale &&
      other.nowMarkerStyle == nowMarkerStyle &&
      other.nowMarkerIcon == nowMarkerIcon &&
      other.showZoomSlider == showZoomSlider &&
      other.zoomSliderExpanded == zoomSliderExpanded &&
      other.stripTextScale == stripTextScale &&
      other.stripShowLeft == stripShowLeft &&
      other.stripShowRight == stripShowRight &&
      other.stripLineRatio == stripLineRatio &&
      other.timePickerMode == timePickerMode &&
      other.nowMarkerSize == nowMarkerSize &&
      other.nowMarkerRight == nowMarkerRight &&
      other.nowMarkerColorIndex == nowMarkerColorIndex &&
      other.nowLineColorIndex == nowLineColorIndex &&
      other.nowLineWidth == nowLineWidth &&
      other.nowMarkerDoodle == nowMarkerDoodle &&
      other.onboarded == onboarded &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(
        handleScale,
        laneGapScale,
        nowMarkerStyle,
        nowMarkerIcon,
        showZoomSlider,
        zoomSliderExpanded,
        stripTextScale,
        stripShowLeft,
        stripShowRight,
        stripLineRatio,
        timePickerMode,
        nowMarkerSize,
        nowMarkerRight,
        nowMarkerColorIndex,
        nowLineColorIndex,
        nowLineWidth,
        nowMarkerDoodle,
        onboarded,
      );
}

class UiPrefsNotifier extends Notifier<UiPrefs> {
  static const String _kHandle = 'ui.handleScale';
  static const String _kLaneGap = 'ui.laneGapScale';
  static const String _kMarker = 'ui.nowMarker';
  static const String _kMarkerIcon = 'ui.nowMarkerIcon';
  static const String _kZoomSlider = 'ui.zoomSlider';
  static const String _kThemeMode = 'ui.themeMode';
  static const String _kZoomExpanded = 'ui.zoomSliderExpanded';
  static const String _kStripText = 'strip.textScale';
  static const String _kStripLeft = 'strip.showLeft';
  static const String _kStripRight = 'strip.showRight';
  static const String _kStripRatio = 'strip.lineRatio';
  static const String _kTimePicker = 'ui.timePickerMode';
  static const String _kMarkerSize = 'ui.nowMarkerSize';
  static const String _kMarkerRight = 'ui.nowMarkerRight';
  static const String _kMarkerColor = 'ui.nowMarkerColor';
  static const String _kLineColor = 'ui.nowLineColor';
  static const String _kLineWidth = 'ui.nowLineWidth';
  static const String _kMarkerDoodle = 'ui.nowMarkerDoodle';
  static const String _kOnboarded = 'ui.onboarded';

  /// 直接读盘判断有没有看过引导，避免 provider 还在异步恢复时误判成「没看过」
  static Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  @override
  UiPrefs build() {
    unawaited(_restore());
    return const UiPrefs();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getDouble(_kHandle);
    final gap = prefs.getDouble(_kLaneGap);
    final marker = prefs.getInt(_kMarker);
    final markerIcon = prefs.getInt(_kMarkerIcon);
    final zoomSlider = prefs.getBool(_kZoomSlider);
    final zoomExpanded = prefs.getBool(_kZoomExpanded);
    final stripText = prefs.getDouble(_kStripText);
    final stripLeft = prefs.getBool(_kStripLeft);
    final stripRight = prefs.getBool(_kStripRight);
    final stripRatio = prefs.getDouble(_kStripRatio);
    final pickerIndex = prefs.getInt(_kTimePicker);
    final markerSize = prefs.getDouble(_kMarkerSize);
    final markerRight = prefs.getBool(_kMarkerRight);
    final markerColor = prefs.getInt(_kMarkerColor);
    final lineColor = prefs.getInt(_kLineColor);
    final lineWidth = prefs.getDouble(_kLineWidth);
    final doodle = prefs.getString(_kMarkerDoodle);
    final themeIndex = prefs.getInt(_kThemeMode);
    final onboarded = prefs.getBool(_kOnboarded);
    state = state.copyWith(
      handleScale: handle?.clamp(UiPrefs.minHandle, UiPrefs.maxHandle),
      laneGapScale: gap?.clamp(UiPrefs.minLaneGap, UiPrefs.maxLaneGap),
      nowMarkerStyle: marker == null
          ? null
          : NowMarkerStyle.values[marker.clamp(0, NowMarkerStyle.values.length - 1)],
      nowMarkerIcon: markerIcon,
      showZoomSlider: zoomSlider,
      zoomSliderExpanded: zoomExpanded,
      stripTextScale: stripText,
      stripShowLeft: stripLeft,
      stripShowRight: stripRight,
      stripLineRatio: stripRatio,
      timePickerMode: pickerIndex == null
          ? null
          : TimePickerMode.values[pickerIndex.clamp(0, TimePickerMode.values.length - 1)],
      nowMarkerSize: markerSize,
      nowMarkerRight: markerRight,
      nowMarkerColorIndex: markerColor,
      nowLineColorIndex: lineColor,
      nowLineWidth: lineWidth,
      nowMarkerDoodle: doodle,
      onboarded: onboarded,
      themeMode: themeIndex == null
          ? null
          : AppThemeMode.values[themeIndex.clamp(0, AppThemeMode.values.length - 1)],
    );
  }

  Future<void> setHandleScale(double value) async {
    final next = value.clamp(UiPrefs.minHandle, UiPrefs.maxHandle);
    state = state.copyWith(handleScale: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kHandle, next);
  }

  Future<void> setLaneGapScale(double value) async {
    final next = value.clamp(UiPrefs.minLaneGap, UiPrefs.maxLaneGap);
    state = state.copyWith(laneGapScale: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLaneGap, next);
  }

  Future<void> setNowMarkerStyle(NowMarkerStyle style) async {
    state = state.copyWith(nowMarkerStyle: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMarker, style.index);
  }

  Future<void> cycleNowMarkerStyle() async {
    final next = NowMarkerStyle
        .values[(state.nowMarkerStyle.index + 1) % NowMarkerStyle.values.length];
    await setNowMarkerStyle(next);
  }

  Future<void> setNowMarkerIcon(int index) async {
    final next = index.clamp(0, nowMarkerIcons.length - 1);
    state = state.copyWith(nowMarkerIcon: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMarkerIcon, next);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setShowZoomSlider(bool value) async {
    state = state.copyWith(showZoomSlider: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kZoomSlider, value);
  }

  Future<void> setZoomSliderExpanded(bool value) async {
    state = state.copyWith(zoomSliderExpanded: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kZoomExpanded, value);
  }

  Future<void> setStripTextScale(double value) async {
    state = state.copyWith(stripTextScale: value.clamp(0.8, 1.4));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kStripText, value.clamp(0.8, 1.4));
  }

  Future<void> setStripShowLeft(bool value) async {
    state = state.copyWith(stripShowLeft: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStripLeft, value);
  }

  Future<void> setStripShowRight(bool value) async {
    state = state.copyWith(stripShowRight: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStripRight, value);
  }

  Future<void> setTimePickerMode(TimePickerMode value) async {
    state = state.copyWith(timePickerMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimePicker, value.index);
  }

  Future<void> setNowMarkerSize(double value) async {
    state = state.copyWith(nowMarkerSize: value.clamp(0.7, 1.6));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMarkerSize, value.clamp(0.7, 1.6));
  }

  Future<void> setNowMarkerRight(bool value) async {
    state = state.copyWith(nowMarkerRight: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMarkerRight, value);
  }

  Future<void> setNowMarkerColorIndex(int index) async {
    state = state.copyWith(nowMarkerColorIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMarkerColor, index);
  }

  Future<void> setNowLineColorIndex(int index) async {
    state = state.copyWith(nowLineColorIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLineColor, index);
  }

  Future<void> setNowLineWidth(double value) async {
    state = state.copyWith(nowLineWidth: value.clamp(1.0, 4.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLineWidth, value.clamp(1.0, 4.0));
  }

  Future<void> setNowMarkerDoodle(String value) async {
    state = state.copyWith(nowMarkerDoodle: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMarkerDoodle, value);
  }

  Future<void> setStripLineRatio(double value) async {
    state = state.copyWith(stripLineRatio: value.clamp(0.5, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kStripRatio, value.clamp(0.5, 1.0));
  }

  Future<void> setOnboarded(bool value) async {
    state = state.copyWith(onboarded: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarded, value);
  }
}

final uiPrefsProvider = NotifierProvider<UiPrefsNotifier, UiPrefs>(
  UiPrefsNotifier.new,
);
