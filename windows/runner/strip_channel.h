#ifndef RUNNER_STRIP_CHANNEL_H_
#define RUNNER_STRIP_CHANNEL_H_

#include <flutter/flutter_engine.h>

// 常驻时间条：在桌面右下角浮一个置顶小窗，用 GDI 画当天时间轴。
//
// Dart 侧每 30 秒（以及方块变动时）通过 tnt/strip 通道推一份 JSON，
// 这里只管画，不做任何业务计算。
void RegisterStripChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_STRIP_CHANNEL_H_
