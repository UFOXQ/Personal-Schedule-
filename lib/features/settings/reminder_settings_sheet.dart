import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../platform/notifications/reminder_scheduler.dart';
import 'reminder_settings.dart';

/// 打开「到点提醒」设置面板。
Future<void> showReminderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ReminderSettingsSheet(),
  );
}

class _ReminderSettingsSheet extends ConsumerStatefulWidget {
  const _ReminderSettingsSheet();

  @override
  ConsumerState<_ReminderSettingsSheet> createState() =>
      _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState
    extends ConsumerState<_ReminderSettingsSheet> {
  NotificationPermissionState? _permission;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPermission();
  }

  Future<void> _loadPermission() async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final state = await scheduler.permissionState();
    if (!mounted) return;
    setState(() => _permission = state);
  }

  Future<void> _requestPermissions() async {
    setState(() => _busy = true);
    final scheduler = ref.read(reminderSchedulerProvider);
    final state = await scheduler.requestPermissions();
    if (!mounted) return;
    setState(() {
      _permission = state;
      _busy = false;
    });
  }

  Future<void> _sendTest() async {
    setState(() => _busy = true);
    await ref.read(reminderSchedulerProvider).showTest();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已发一条测试通知；没看到就看 %APPDATA%\\com.tnt\\tnt_app\\tnt.log'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);
    final permission = _permission;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
              '到点提醒',
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '方块开始的时间点弹一条通知；到点前也能提前喊你',
              style: TextStyle(color: Palette.textDim, fontSize: 11),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: settings.enabled,
              activeThumbColor: Palette.accent,
              title: Text(
                '开启提醒',
                style: TextStyle(color: Palette.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                '关掉后待发的提醒会全部撤掉',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
              onChanged: (value) => notifier.setEnabled(value),
            ),
            const SizedBox(height: 4),
            Text(
              '提前量',
              style: TextStyle(color: Palette.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final minutes in ReminderSettings.leadOptions)
                  ChoiceChip(
                    label: Text(
                      ReminderSettings.leadLabelOf(minutes),
                      style: TextStyle(
                        fontSize: 12,
                        color: settings.leadMinutes == minutes
                            ? Palette.textPrimary
                            : Palette.textSecondary,
                      ),
                    ),
                    selected: settings.leadMinutes == minutes,
                    onSelected: settings.enabled
                        ? (_) => notifier.setLeadMinutes(minutes)
                        : null,
                    selectedColor: Palette.accent.withValues(alpha: 0.28),
                    backgroundColor: Palette.surfaceHigh,
                    side: BorderSide(color: Palette.line),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: settings.quietEnabled,
              activeThumbColor: Palette.accent,
              title: Text(
                '免打扰时段',
                style: TextStyle(color: Palette.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                '这段时间里到点的提醒不响，也不补发',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
              onChanged: (value) => notifier.setQuietEnabled(value),
            ),
            if (settings.quietEnabled)
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: '从',
                      minute: settings.quietStartMin,
                      onChanged: (minute) => notifier.setQuietRange(
                        startMin: minute,
                        endMin: settings.quietEndMin,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeField(
                      label: '到',
                      minute: settings.quietEndMin,
                      onChanged: (minute) => notifier.setQuietRange(
                        startMin: settings.quietStartMin,
                        endMin: minute,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: settings.workdaysOnly,
              activeThumbColor: Palette.accent,
              title: Text(
                '只在工作日提醒',
                style: TextStyle(color: Palette.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                '周六、周日整天不提醒（周末的方块照样留在时间轴上）',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
              onChanged: (value) => notifier.setWorkdaysOnly(value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  permission?.granted == false
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                  size: 16,
                  color: permission?.granted == false
                      ? Palette.top
                      : Palette.textDim,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    permission == null ? '正在检查通知权限…' : permission.detail,
                    style: TextStyle(
                      color: Palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (permission != null && !permission.granted)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _busy ? null : _requestPermissions,
                      child: const Text('去授权'),
                    ),
                  ),
                if (permission != null && !permission.granted)
                  const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _sendTest,
                    child: const Text('发一条测试通知'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Android 12+ 想准点响需要「精确闹钟」权限；Windows 走系统 Toast，卸载重装后第一条可能延迟。',
              style: TextStyle(
                color: Palette.textDim,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minute,
    required this.onChanged,
  });

  final String label;
  final int minute;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
          helpText: '免打扰$label',
        );
        if (picked == null) return;
        onChanged(picked.hour * 60 + picked.minute);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: Palette.textDim, fontSize: 11),
            ),
            const SizedBox(width: 8),
            Text(
              formatMinute(minute),
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}