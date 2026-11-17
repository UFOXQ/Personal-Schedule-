import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/quiet_hours.dart';

/// 到点提醒的设置。
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.leadMinutes = 0,
    this.quietEnabled = false,
    this.quietStartMin = 22 * 60,
    this.quietEndMin = 8 * 60,
    this.workdaysOnly = false,
  });

  final bool enabled;

  /// 提前多少分钟提醒（0 = 准点）。
  final int leadMinutes;

  /// 免打扰时段（跨零点也可以，比如 22:00 → 08:00）。
  final bool quietEnabled;
  final int quietStartMin;
  final int quietEndMin;

  /// 只在周一到周五提醒。
  final bool workdaysOnly;

  /// 面板里可选的提前量。
  static const List<int> leadOptions = <int>[0, 5, 15];

  String get leadLabel => leadLabelOf(leadMinutes);

  static String leadLabelOf(int minutes) =>
      minutes <= 0 ? '准点' : '提前 $minutes 分钟';

  /// 这个时刻是否落在免打扰里（起含止不含；起止相同＝没有免打扰）。
  bool isQuietAt(int minute) {
    if (!quietEnabled) return false;
    return inQuietWindow(minute, quietStartMin, quietEndMin);
  }

  ReminderSettings copyWith({
    bool? enabled,
    int? leadMinutes,
    bool? quietEnabled,
    int? quietStartMin,
    int? quietEndMin,
    bool? workdaysOnly,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      quietEnabled: quietEnabled ?? this.quietEnabled,
      quietStartMin: quietStartMin ?? this.quietStartMin,
      quietEndMin: quietEndMin ?? this.quietEndMin,
      workdaysOnly: workdaysOnly ?? this.workdaysOnly,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.leadMinutes == leadMinutes &&
      other.quietEnabled == quietEnabled &&
      other.quietStartMin == quietStartMin &&
      other.quietEndMin == quietEndMin &&
      other.workdaysOnly == workdaysOnly;

  @override
  int get hashCode => Object.hash(
    enabled,
    leadMinutes,
    quietEnabled,
    quietStartMin,
    quietEndMin,
    workdaysOnly,
  );
}


/// 读写设置（shared_preferences），启动时异步恢复。
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _kEnabled = 'reminders.enabled';
  static const _kLead = 'reminders.leadMinutes';
  static const _kQuiet = 'reminders.quietEnabled';
  static const _kQuietStart = 'reminders.quietStart';
  static const _kQuietEnd = 'reminders.quietEnd';
  static const _kWorkdays = 'reminders.workdaysOnly';

  SharedPreferences? _prefs;

  @override
  ReminderSettings build() {
    unawaited(_restore());
    return const ReminderSettings();
  }

  Future<SharedPreferences> _prefsInstance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restore() async {
    try {
      final prefs = await _prefsInstance();
      state = ReminderSettings(
        enabled: prefs.getBool(_kEnabled) ?? true,
        leadMinutes: prefs.getInt(_kLead) ?? 0,
        quietEnabled: prefs.getBool(_kQuiet) ?? false,
        quietStartMin: prefs.getInt(_kQuietStart) ?? 22 * 60,
        quietEndMin: prefs.getInt(_kQuietEnd) ?? 8 * 60,
        workdaysOnly: prefs.getBool(_kWorkdays) ?? false,
      );
    } catch (_) {
      // 读不到就用默认值，不影响主流程
    }
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    try {
      final prefs = await _prefsInstance();
      await prefs.setBool(_kEnabled, value);
    } catch (_) {}
  }

  Future<void> setLeadMinutes(int value) async {
    state = state.copyWith(leadMinutes: value);
    try {
      final prefs = await _prefsInstance();
      await prefs.setInt(_kLead, value);
    } catch (_) {}
  }

  Future<void> setQuietEnabled(bool value) async {
    state = state.copyWith(quietEnabled: value);
    try {
      final prefs = await _prefsInstance();
      await prefs.setBool(_kQuiet, value);
    } catch (_) {}
  }

  Future<void> setQuietRange({required int startMin, required int endMin}) async {
    state = state.copyWith(quietStartMin: startMin, quietEndMin: endMin);
    try {
      final prefs = await _prefsInstance();
      await prefs.setInt(_kQuietStart, startMin);
      await prefs.setInt(_kQuietEnd, endMin);
    } catch (_) {}
  }

  Future<void> setWorkdaysOnly(bool value) async {
    state = state.copyWith(workdaysOnly: value);
    try {
      final prefs = await _prefsInstance();
      await prefs.setBool(_kWorkdays, value);
    } catch (_) {}
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );
