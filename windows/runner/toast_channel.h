#ifndef RUNNER_TOAST_CHANNEL_H_
#define RUNNER_TOAST_CHANNEL_H_

#include <flutter/flutter_engine.h>

// 注册 "tnt/toast" 方法通道：桌面端发系统 toast（非 MSIX 也能用）。
void RegisterToastChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_TOAST_CHANNEL_H_
