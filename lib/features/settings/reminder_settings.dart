import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 到点提醒的设置。
class ReminderSettings {
  const ReminderSettings({this.enabled = true, this.leadMinutes = 0});

  final bool enabled;

  /// 提前多少分钟提醒（0 = 准点）。
  final int leadMinutes;

  /// 面板里可选的提前量。
  static const List<int> leadOptions = <int>[0, 5, 15];

  String get leadLabel => leadLabelOf(leadMinutes);

  static String leadLabelOf(int minutes) =>
      minutes <= 0 ? '准点' : '提前 $minutes 分钟';

  ReminderSettings copyWith({bool? enabled, int? leadMinutes}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.leadMinutes == leadMinutes;

  @override
  int get hashCode => Object.hash(enabled, leadMinutes);
}

/// 读写设置（shared_preferences），启动时异步恢复。
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _kEnabled = 'reminders.enabled';
  static const _kLead = 'reminders.leadMinutes';

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
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );
