import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import 'sync_controller.dart';

/// 打开「局域网同步」面板：一半是开主机（给对面地址和配对码），
/// 一半是连对面（填地址 + 码）。
Future<void> showSyncSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _SyncSheet(),
  );
}

class _SyncSheet extends ConsumerStatefulWidget {
  const _SyncSheet();

  @override
  ConsumerState<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends ConsumerState<_SyncSheet> {
  final _address = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sync, size: 20, color: Palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    '电脑 ↔ 手机同步',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '关闭',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '两台设备连着同一个 Wi-Fi 就行，直连不过服务器。'
                '同步是双向的：各自把本机数据推给对方，按修改时间取新的。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('这台设备当主机'),
              const SizedBox(height: 6),
              if (!state.hosting)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.busy ? null : controller.startHost,
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('开启同步服务'),
                  ),
                )
              else ...[
                _AddressCard(address: state.address ?? '-', code: state.code ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.stopHost,
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text('停止'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final text = '${state.address} 配对码 ${state.code}';
                          await Clipboard.setData(ClipboardData(text: text));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('地址和配对码已复制')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _SectionTitle('连到另一台设备'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _address,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: '对面地址',
                        hintText: '192.168.1.5:47821',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: '配对码',
                        hintText: '4 位',
                        isDense: true,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => controller.syncWith(
                          address: _address.text,
                          code: _code.text,
                        ),
                  icon: state.busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_alt, size: 18),
                  label: Text(state.busy ? '同步中…' : '连接并同步'),
                ),
              ),
              if (state.message != null) ...[
                const SizedBox(height: 12),
                _Note(state.message!, color: Palette.accent),
              ],
              if (state.lastError != null) ...[
                const SizedBox(height: 12),
                _Note(state.lastError!, color: Palette.top),
              ],
              const SizedBox(height: 14),
              Text(
                '提示：Android 模拟器连本机要用 10.0.2.2:47821；真机就用电脑的局域网 IP。'
                '头一次连 Windows 可能弹防火墙，记得允许专用网络。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: Palette.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Palette.textPrimary,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.code});

  final String address;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '在另一台设备上填',
                  style: TextStyle(fontSize: 11, color: Palette.textDim),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '配对码',
                style: TextStyle(fontSize: 11, color: Palette.textDim),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                  color: Palette.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, height: 1.4, color: color),
      ),
    );
  }
}
