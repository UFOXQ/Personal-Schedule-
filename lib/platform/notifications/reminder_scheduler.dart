import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// 通知插件里也有一个 Priority（min/low/default/high/max），这里用它的；
// 所以把业务模型的 Priority 隐藏掉，避免同名冲突。
import '../../core/app_log.dart';
import '../../domain/models/tblock.dart' hide Priority;
import '../../domain/reminders.dart';
import '../../features/settings/reminder_settings.dart';
import 'desktop_toast.dart';

/// 通知权限 / 精确闹钟的当前状态（给设置面板展示）。
class NotificationPermissionState {
  const NotificationPermissionState({
    required this.granted,
    required this.exact,
    required this.detail,
  });

  final bool granted;
  final bool exact;
  final String detail;

  static const unknown = NotificationPermissionState(
    granted: false,
    exact: false,
    detail: '未知（桌面端不需要申请）',
  );
}

/// 提醒调度器：只暴露「排提醒」这一件事，便于测试替换成假的。
abstract class ReminderScheduler {
  /// 初始化插件与时区；桌面/移动端都调一次。
  Future<void> init();

  /// 读当前权限状态。
  Future<NotificationPermissionState> permissionState();

  /// 申请通知权限（Android 13+）与精确闹钟权限（Android 12+）。
  Future<NotificationPermissionState> requestPermissions();

  /// 立刻发一条测试通知。
  Future<void> showTest();

  /// 用当天最新的方块覆盖排程：已取消的方块撤掉，新方块排上。
  Future<void> sync({
    required DateTime day,
    required List<TBlock> blocks,
    required ReminderSettings settings,
  });

  /// 应用内到点事件（桌面端靠它弹横幅；系统通知照发）。
  Stream<Reminder> get fired;
}

/// 真实现：
/// - Android：flutter_local_notifications 的 `zonedSchedule`，系统闹钟，杀进程也响；
/// - Windows / Linux：local_notifier 现弹，靠 app 内的 Timer 计时（关掉程序就不响）。
///
/// 之所以桌面端不用 flutter_local_notifications：它的 Windows 实现按「打包应用」
/// 设计，非 MSIX 运行时初始化会把进程直接带走（实测 exit 0、无日志）。
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler();

  static const _channelId = 'tnt_block_reminders';
  static const _channelName = '方块提醒';
  static const _channelDescription = '方块到点提醒';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Android 已排上的通知：blockId -> 通知 id
  final Map<String, int> _scheduled = <String, int>{};

  /// 桌面端待弹的计时器：blockId -> Timer
  final Map<String, Timer> _timers = <String, Timer>{};

  final StreamController<Reminder> _fires =
      StreamController<Reminder>.broadcast();

  @override
  Stream<Reminder> get fired => _fires.stream;

  bool _ready = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isWindows => !kIsWeb && Platform.isWindows;
  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  Future<void> init() async {
    if (_ready) return;
    if (_isAndroid) {
      await _initAndroid();
    } else if (_isDesktop) {
      await _initDesktop();
    }
  }

  Future<void> _initAndroid() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(await _resolveLocation());

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_tnt'),
        ),
      );
      _ready = true;
    } catch (error) {
      await appLog('通知插件初始化失败 -> $error');
    }
  }

  /// 取本机时区。真实手机一般能拿到 `Asia/Shanghai` 这种名字，
  /// 但模拟器/部分 ROM 会返回 `GMT`、`CST` 这类 timezone 包里没有的名字，
  /// 这时按当前 UTC 偏移退回 `Etc/GMT±N`，再不行才用 UTC ——
  /// 免得写死北京时间把外地的时间算错几个小时。
  Future<tz.Location> _resolveLocation() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } catch (error) {
      await appLog('取本地时区失败，按 UTC 偏移兜底 -> $error');
    }
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inMinutes ~/ 60;
    final sign = hours >= 0 ? '-' : '+'; // Etc/GMT 的符号与常见写法相反
    for (final name in ['Etc/GMT$sign${hours.abs()}', 'UTC']) {
      try {
        return tz.getLocation(name);
      } catch (_) {
        continue;
      }
    }
    return tz.UTC;
  }

  Future<void> _initDesktop() async {
    try {
      // 会在开始菜单建一个带 AUMID 的快捷方式，Windows 才认这条通知的出处
      await localNotifier.setup(appName: 'TNT');
      _ready = true;
    } catch (error) {
      debugPrint('TNT: 桌面通知初始化失败 -> $error');
    }
  }

  @override
  Future<NotificationPermissionState> permissionState() async {
    if (!_ready) return NotificationPermissionState.unknown;
    if (_isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.areNotificationsEnabled() ?? false;
      final exact = await android?.canScheduleExactNotifications() ?? false;
      return NotificationPermissionState(
        granted: granted,
        exact: exact,
        detail: granted
            ? (exact ? '通知已开启，可精确到分钟' : '通知已开启，但没有精确闹钟权限')
            : '通知权限未开启',
      );
    }
    if (_isDesktop) {
      return const NotificationPermissionState(
        granted: true,
        exact: false,
        detail: '桌面通知直接弹；关掉程序就不会响',
      );
    }
    return NotificationPermissionState.unknown;
  }

  @override
  Future<NotificationPermissionState> requestPermissions() async {
    if (!_ready) await init();
    if (!_ready) return NotificationPermissionState.unknown;
    if (_isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
    return permissionState();
  }

  @override
  Future<void> showTest() async {
    if (!_ready) await init();
    if (!_ready) return;
    if (_isDesktop) {
      await _notifyDesktop(title: 'TNT 测试提醒', body: '能看到这条，说明到点提醒是通的。');
      return;
    }
    await _plugin.show(
      id: 1,
      title: 'TNT 测试提醒',
      body: '能看到这条，说明到点提醒是通的。',
      notificationDetails: _details('TNT 测试提醒'),
    );
  }

  @override
  Future<void> sync({
    required DateTime day,
    required List<TBlock> blocks,
    required ReminderSettings settings,
  }) async {
    if (!_ready) return;
    try {
      if (_isDesktop) {
        _syncDesktop(day: day, blocks: blocks, settings: settings);
        return;
      }
      if (!settings.enabled) {
        await _cancelAllScheduled();
        return;
      }
      final reminders = planReminders(
        blocks: blocks,
        day: day,
        leadMinutes: settings.leadMinutes,
        now: DateTime.now(),
        workdaysOnly: settings.workdaysOnly,
        quietStartMin: settings.quietEnabled ? settings.quietStartMin : null,
        quietEndMin: settings.quietEnabled ? settings.quietEndMin : null,
      );
      // 已经弹过的（时间在过去）也算「还活着」，不能撤 —— 否则到点响完，
      // 下一次 sync 会把它从通知栏里一起清掉。只有方块被删/完成才撤。
      final alive = <String>{
        for (final block in blocks)
          if (!block.done && block.status == BlockStatus.planned) block.id,
      };

      for (final entry in _scheduled.entries.toList()) {
        if (alive.contains(entry.key)) continue;
        await _cancel(entry.value);
        _scheduled.remove(entry.key);
      }

      for (final reminder in reminders) {
        final payload = '${reminder.blockId}|${day.toIso8601String()}';
        await _schedule(
          id: reminder.id,
          at: reminder.at,
          title: reminder.title,
          body: reminder.body,
          payload: payload,
        );
        _scheduled[reminder.blockId] = reminder.id;
      }
    } catch (error) {
      debugPrint('TNT: 排提醒失败 -> $error');
    }
  }

  /// 桌面端：清掉旧计时器，按最新方块重排。
  void _syncDesktop({
    required DateTime day,
    required List<TBlock> blocks,
    required ReminderSettings settings,
  }) {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    if (!settings.enabled) return;

    final now = DateTime.now();
    final reminders = planReminders(
      blocks: blocks,
      day: day,
      leadMinutes: settings.leadMinutes,
      now: now,
      workdaysOnly: settings.workdaysOnly,
      quietStartMin: settings.quietEnabled ? settings.quietStartMin : null,
      quietEndMin: settings.quietEnabled ? settings.quietEndMin : null,
    );
    for (final reminder in reminders) {
      final delay = reminder.at.difference(now);
      // Timer 支持长延时，但过远的没必要占着（超过 24 小时等下次 sync 再说）
      if (delay > const Duration(hours: 24)) continue;
      _timers[reminder.blockId] = Timer(delay, () {
        _timers.remove(reminder.blockId);
        debugPrint('TNT: 到点提醒 -> ${reminder.title}');
        _fires.add(reminder);
        unawaited(_notifyDesktop(title: reminder.title, body: reminder.body));
      });
    }
  }

  /// 桌面端提醒：优先走 runner 里的原生 toast（Windows 通知中心里能看到），
  /// 失败再退回 local_notifier（Linux 上还能用），最后至少还有应用内横幅。
  Future<void> _notifyDesktop({
    required String title,
    required String body,
  }) async {
    if (_isWindows) {
      final ok = await desktopToast.show(title: title, body: body);
      if (ok) return;
      await appLog('系统通知没发出去，退回落地方案（检查是否以低权限/沙箱运行）');
    }
    try {
      await localNotifier.notify(LocalNotification(title: title, body: body));
    } catch (error) {
      await appLog('桌面通知发送失败 -> $error');
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    final details = _details(body);
    final when = tz.TZDateTime.from(at, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } on PlatformException catch (error) {
      // 没有精确闹钟权限时退到不精确排程，至少不会丢提醒
      debugPrint('TNT: 精确排程失败，退回不精确 -> $error');
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('TNT: 取消提醒失败 -> $error');
    }
  }

  Future<void> _cancelAllScheduled() async {
    for (final id in _scheduled.values) {
      await _cancel(id);
    }
    _scheduled.clear();
  }

  NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: 'ic_stat_tnt',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
  }
}

/// 全局调度器；测试里可以 override 成假实现。
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalReminderScheduler(),
);
