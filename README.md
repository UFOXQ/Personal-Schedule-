# TNT · 一天时间轴

把每件事做成一个「方块」，吸附在一天的时间轴上；用颜色和位置表达轻重缓急。
Android + Windows 双端，Flutter 自绘。

> 当前进度：**S0 骨架 + S1 手感原型 + S2 数据层 + S3 时间轴核心 + S4 日历与长期计划 + S5 到点提醒**（双端可运行；数据落到本地 SQLite，重启不丢）。

## 现在能做什么

- 三条泳道：**日常琐事 / 长期打卡 / 临时事件**，方块独占一条泳道。
- 拖动方块改开始时间（5 分钟吸附），左右拖可跨泳道。
- 拖方块**底边**改时长（最小时长 10 分钟）；拖到屏幕上下边缘会自动滚动。
- 双指捏合缩放时间轴（桌面用右下角 `− 1.50x +`），桌面支持鼠标滚轮滚动。
- 点击空白处新增一个 30 分钟方块；长按方块删除。
- 优先级 A/B/C/D 循环切换，颜色随优先级变（A 红、B 橙、C 蓝、D 绿）。
- A 级 + 48 小时内到期的 B 级 → 视为「置顶」：浮到顶部置顶区，泳道里仍描红边
  （顶栏右上角开关可关掉泳道内的红边方块）。
- 同一时段重叠的方块自动并列分列，不遮挡。
- 底部选中条显示方块详情，可**完成 ✓** / 改优先级 / 删除 / 取消选中。
- **集合整包投入**：顶栏 `☰+` 选一个集合（如「早间流程」），它的方块按预设时段一次性落进今天；
  同一集合同一天只投一次，集合里后来加的条目可以再补投。
- **长期计划惰性物化**：日历区间内的计划（如「学英语」11/1–12/31 每天 9:00）在打开当天时自动落到时间轴，
  用 `plan:<id>@<日期>` 做幂等键，重启不会重复生成。
- **未完成顺延**：打开当天若发现以前没做完的方块，弹窗问「稍后 / 丢弃 / 顺延到今天」；
  顺延会照原时段复制到今天并累加「顺延 N 次」，原方块标成 carried，丢弃则标 dropped。
- **完成记录**：点 ✓ 会把方块写进 `completion_logs` 并从时间轴移除，顶栏 `🕘` 可以翻历史记录。
- 数据落在本地 SQLite（Drift），按天存 `day_blocks`；首次启动自动灌一份示例排班。
- **月历总览**：一屏看完哪几天忙（小色条 + 数量），单击预览、双击进那天的轴；顶栏可左右翻日期。
- **长期计划**：起止日期 + 每周几 + 时段，保存后自动铺到区间内每一天的时间轴。
- 删除是「软删除」（写 `deletedAt` 墓碑），为后面双端同步（S7）留出合并依据。
- **到点提醒**：顶栏 `🔔` 设置「开启提醒 + 提前 0/5/15 分钟」；Android 走系统精确闹钟，
  Windows 弹应用内横幅（系统 toast 见下）。

## 到点提醒

- 规则在 `domain/reminders.dart` 纯函数里：`reminderIdFor(blockId)` 用 FNV-1a 取 31 位（不能用 `hashCode`，
  重启会变就撤不掉了）；`planReminders(...)` 过滤已完成/已过去、按时间排序去重。
- 顶部 `🔔` 打开设置面板：开关、提前量（0/5/15 分钟）、权限状态、发一条测试通知。
- **Android**：`flutter_local_notifications` 的 `zonedSchedule` + `exactAllowWhileIdle`（没有精确闹钟权限时退化为
  `inexactAllowWhileIdle`），杀进程也会响；已排的通知按 blockId 记账，**只有方块被删/完成才撤**，
  到点响过之后不会被下一次 sync 清掉。需要的权限：`POST_NOTIFICATIONS`、`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`；
  清单里注册了 `ScheduledNotificationReceiver` 与开机重建的 `ScheduledNotificationBootReceiver`，
  通知小图标 = `android/app/src/main/res/drawable/ic_stat_tnt.xml`。
- **Windows**：`local_notifier` 的 toast 在「非 MSIX 打包」下拿不到 AUMID（它想去开始菜单建 `TNT.lnk`，
  实测建不出来，日志 `WinToast is not initialized`），所以桌面端主通道是**应用内横幅**：
  调度器用 `Timer` 精确到点，向 `fired` 流推一条，时间轴页在顶部浮出 10 秒的红框横幅（可点 ✕ 关）。
  关掉程序就不会响——桌面端常驻要等 S6 的托盘。
- 状态层在每次改块（拖拽防抖 300ms）、换日、改设置时重新排程；异常只打印，不影响主流程。

## 日历与长期计划

- 顶栏 `🗓` 打开月历：6×7 固定 42 格，周一开头；格子里的小色条 + 数字表示当天方块数（≥4 橙、≥8 红），今天描红框。
- 单击格子 = 选中，底部预览当天「N 件 · 总时长」+ 横向迷你方块；**双击格子直接进那天的轴**，或点「打开这天的轴」。
- 顶栏日期可左右翻（`‹ 11 月 13 日 · 周五 ›`），翻到非今天时出现「回到今天」；翻看历史日期不会弹顺延窗。
- 月历右上 `📝` 进「长期计划」：新建/编辑计划 = 名称 + 起止日期 + 每周几（周一为 bit0）+ 泳道 + 开始时刻 + 时长 + 优先级；
  保存后回到时间轴会重新物化当天（`reload()`），删除是软删除。
- 计划物化是幂等的：`plan:<id>@<yyyy-MM-dd>`，一天只生成一次；星期掩码 127=每天、31=工作日、96=周末。

## 目录

```
lib/
  core/            # 时间与配色常量、时间格式化
  domain/          # 纯 Dart：模型 / 优先级 / 布局算法 / 物化规则（不 import flutter）
    models/tblock.dart           # TBlock + Lane/Priority/BlockSource/BlockStatus
    models/carry_over.dart       # 待顺延方块
    priority.dart
    materialize.dart             # 幂等键 / 顺延规则（纯函数）
    layout/timeline_layout.dart  # 扫簇 + 贪心染色分列
    calendar/month_grid.dart     # 42 格月视图 + 标签
    calendar/day_overview.dart   # 当天总览：时长 / 泳道计数 / 空档
  data/
    db/tnt_database.dart          # Drift 六表 + 索引
    materialize.dart              # 计划 / 集合 → 当天方块
    repositories/                 # DayBlockRepository / LibraryRepository
    providers.dart                # databaseProvider 等
  features/timeline/
    timeline_page.dart      # 顶栏 + 置顶区 + 底部选中条 + 顺延弹窗
    timeline_view.dart      # 手势 + 滚动 + 缩放 + 惯性
    timeline_painter.dart   # 全部绘制（单 CustomPaint）
    timeline_state.dart     # Riverpod 状态，读库→物化→改内存→异步落库
  features/calendar/calendar_page.dart        # 月历 + 当天预览
  features/plans/plans_page.dart              # 长期计划列表
  features/plans/plan_editor_sheet.dart       # 计划编辑（起止/星期/时段）
  features/templates/collections_sheet.dart   # 集合选择面板
  features/logs/completion_logs_page.dart     # 完成记录页
  features/settings/reminder_settings.dart        # 提醒设置（SharedPreferences）
  features/settings/reminder_settings_sheet.dart  # 提醒设置面板（权限/提前量/测试）
  domain/reminders.dart                           # 提醒规则（纯函数）
  platform/notifications/reminder_scheduler.dart  # Android 闹钟 / 桌面 Timer + 横幅事件流
  platform/window/          # window_manager 桌面窗口
test/
  data_repositories_test.dart    # 仓库层单测（内存库）
  s3_materialize_test.dart       # 物化 / 顺延 / 状态流转
  s3_timeline_state_test.dart    # 状态层：完成、集合投入、幂等
  s3_carry_dialog_test.dart      # 顺延弹窗端到端（widget test）
  s4_calendar_test.dart          # 月视图 / 当天概览 / 区间统计 / 日期跳转
  s5_reminders_test.dart         # 提醒 id / 提前量 / 排程与防抖
  widget_test.dart               # 首屏冒烟
```

设计铁律：`domain/` 不依赖 Flutter；优先级、重叠分列、顺延都算派生量，不进数据库。
物化与完成都是「幂等」的：同一个 `instanceGroupId` / 计划键，一天只生成一次。

## 数据库

- 库文件名 `tnt.sqlite`，位置 `getApplicationSupportDirectory()`：
  - Windows：`%APPDATA%\com.tnt\tnt_app\tnt.sqlite`
  - Android：`/data/data/com.tnt.tnt_app/files/tnt.sqlite`
- 六张表：`block_templates`、`collections`、`collection_items`、`plans`、`day_blocks`、`completion_logs`。
- 日期统一用 `yyyy-MM-dd` 字符串存（本地时区），方便按区间比较与后面同步。
- 注意：不要用「文档目录」`getApplicationDocumentsDirectory()` 放库，本机文档目录被重定向到 D 盘后 sqlite 打不开（`SqliteException(14)`）。

## 运行

```powershell
$env:JAVA_HOME='C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot'
$env:ANDROID_HOME='E:\TNT\Android\Sdk'
$env:ANDROID_SDK_ROOT=$env:ANDROID_HOME
$env:GRADLE_USER_HOME='E:\TNT\gradle'
$env:PUB_CACHE='E:\TNT\pub-cache'
$env:PATH="E:\TNT\flutter\bin;E:\TNT\Android\Sdk\platform-tools;$env:PATH"

flutter build windows --debug   # 桌面端出包
flutter build apk --debug       # 安卓装包
adb install -r build\app\outputs\flutter-apk\app-debug.apk
flutter test                    # 53 项单测/组件测试
```

> 本机 `flutter run -d windows` 不可用（DSH 的 TEMP 指向一次性沙箱目录，DevFS 起不来），
> 调试请用 `flutter build windows --debug` 后直接跑 exe。

> 本机到 `dl.google.com` 经常握手超时：`android/settings.gradle.kts` 和
> `$FLUTTER_ROOT/packages/flutter_tools/gradle/settings.gradle.kts` 都加了阿里云镜像优先；
> `android/gradle.properties` 关掉了 Kotlin 增量编译（本机增量缓存偶尔写坏导致 `Could not close incremental caches`）。
> Windows 桌面通知插件需要 ATL（`Microsoft.VisualStudio.Component.VC.ATL`），已装在 `E:\TNT\VSBuildTools`。

## 下一步

1. **S6**：Android 桌面小组件 + Windows 托盘常驻（顺带把桌面 toast 打包成 MSIX 或注册 AUMID）。
2. **S7**：电脑 ↔ 手机局域网同步（HttpServer + 扫码配对 + LWW）。
3. **S8**：打磨与开源（README 双语、截图、许可证、CI）。
