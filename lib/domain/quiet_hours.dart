/// 免打扰时段判断（纯函数，domain 层不依赖任何插件/框架）。
///
/// 支持跨零点：22:00 → 08:00 时，22:00 之后和 08:00 之前都算免打扰。
/// 起含止不含；起止相同视为「没有免打扰」。
bool inQuietWindow(int minute, int startMin, int endMin) {
  if (startMin == endMin) return false;
  final m = minute % (24 * 60);
  if (startMin < endMin) return m >= startMin && m < endMin;
  return m >= startMin || m < endMin;
}
