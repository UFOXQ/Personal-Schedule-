import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/tblock.dart';
import '../../domain/strip_image.dart';
import '../../domain/timeline_strip.dart';
import '../../features/settings/ui_prefs.dart';

/// 时间条在哪些端上开着
class StripState {
  const StripState({this.phone = false, this.desktop = false});

  final bool phone;
  final bool desktop;

  bool get any => phone || desktop;

  StripState copyWith({bool? phone, bool? desktop}) =>
      StripState(phone: phone ?? this.phone, desktop: desktop ?? this.desktop);
}

/// 把当天的时间条推给手机常驻通知 / 桌面悬浮条
///
/// 原生侧只负责画；数据由 Dart 每 30 秒（以及每次方块变动时）推一次。
class StripController extends Notifier<StripState> {
  static const MethodChannel _channel = MethodChannel('tnt/strip');
  static const String _kPhone = 'strip.phone';
  static const String _kDesktop = 'strip.desktop';

  Timer? _timer;
  List<TBlock> _blocks = const <TBlock>[];
  Set<Lane> _hidden = const <Lane>{};

  @override
  StripState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    unawaited(_restore());
    return const StripState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getBool(_kPhone) ?? false;
    final desktop = prefs.getBool(_kDesktop) ?? false;
    state = StripState(phone: phone, desktop: desktop);
    if (state.any) _startTicker();
  }

  /// 时间轴每次变化都调它，保持原生侧的数据是最新的
  void updateSource({
    required List<TBlock> blocks,
    required Set<Lane> hiddenLanes,
  }) {
    _blocks = blocks;
    _hidden = hiddenLanes;
    if (state.any) unawaited(_push());
  }

  Future<void> setPhoneEnabled(bool enabled) async {
    state = state.copyWith(phone: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPhone, enabled);
    await _syncChannels();
  }

  Future<void> setDesktopEnabled(bool enabled) async {
    state = state.copyWith(desktop: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDesktop, enabled);
    await _syncChannels();
  }

  StripPayload _payload() => buildStripPayload(
    blocks: _blocks,
    now: DateTime.now(),
    hiddenLanes: _hidden,
  );

  Future<void> _syncChannels() async {
    if (state.any) {
      _startTicker();
      await _push();
    } else {
      _timer?.cancel();
      _timer = null;
      await _call('stop');
    }
  }

  void _startTicker() {
    _timer?.cancel();
    // 5 秒一跳：时间条上的红线要跟着时间走，30 秒太钝
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!state.any) return;
      unawaited(_push());
    });
  }

  Future<void> _push() async {
    final payload = _payload();
    final json = jsonEncode(payload.toJson());
    final style = _style();

    if (Platform.isAndroid) {
      // Binder 单次事务有上限，传压缩后的 PNG（约 20KB）
      final png = await renderStripPng(payload, style: style);
      await _call('update', <String, Object?>{'payload': json, 'png': png});
      _pushCount++;
      // 小组件写盘比较重，5 分钟刷一次就够；通知靠上面的实时推送
      if (_pushCount % 10 == 1) {
        await _pushWidget(json, png);
      }
      return;
    }

    // 桌面悬浮条按窗口像素 1:1 出图，避免缩放糊
    final image = await renderStripImage(
      payload,
      width: 520,
      height: 112,
      pixelRatio: 1,
      style: style,
    );
    await _call('update', <String, Object?>{
      'payload': json,
      'width': image.width,
      'height': image.height,
      'rgba': image.rgba,
    });
  }

  StripStyle _style() {
    final prefs = ref.read(uiPrefsProvider);
    return StripStyle(
      textScale: prefs.stripTextScale,
      showLeft: prefs.stripShowLeft,
      showRight: prefs.stripShowRight,
      lineRatio: prefs.stripLineRatio,
    );
  }

  int _pushCount = 0;

  /// 手机桌面小组件：把同一份图和数据存进 HomeWidget，再让它重画
  Future<void> _pushWidget(String payload, Uint8List png) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<String>('tnt_strip_payload', payload);
      await HomeWidget.saveWidgetData<String>('tnt_strip_png', base64Encode(png));
      await HomeWidget.updateWidget(
        name: 'TntStripWidgetProvider',
        androidName: 'TntStripWidgetProvider',
        qualifiedAndroidName: 'com.tnt.tnt_app.TntStripWidgetProvider',
      );
    } catch (error) {
      debugPrint('TNT: 时间条小组件刷新失败 -> $error');
    }
  }

  Future<void> _call(String method, [Map<String, Object?>? args]) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (error) {
      debugPrint('TNT: 时间条同步失败 -> $error');
    } on MissingPluginException {
      // 桌面/手机以外，或原生侧还没接上：安静跳过
    }
  }
}

final stripProvider = NotifierProvider<StripController, StripState>(
  StripController.new,
);
