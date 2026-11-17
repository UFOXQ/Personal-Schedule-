import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 空白处新建方块的触发方式
enum CreateMode {
  longPress('长按'),
  doubleTap('双击'),
  both('长按 + 双击');

  const CreateMode(this.label);

  final String label;
}

/// 长按小旗后选优先级的方式
enum PriorityPickerMode {
  menu('跳菜单'),
  wheel('滚轮');

  const PriorityPickerMode(this.label);

  final String label;
}

class InteractionModes {
  const InteractionModes({
    this.create = CreateMode.both,
    this.priorityPicker = PriorityPickerMode.menu,
  });

  final CreateMode create;
  final PriorityPickerMode priorityPicker;

  bool get allowLongPressCreate => create != CreateMode.doubleTap;

  bool get allowDoubleTapCreate => create != CreateMode.longPress;

  InteractionModes copyWith({
    CreateMode? create,
    PriorityPickerMode? priorityPicker,
  }) {
    return InteractionModes(
      create: create ?? this.create,
      priorityPicker: priorityPicker ?? this.priorityPicker,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InteractionModes &&
      other.create == create &&
      other.priorityPicker == priorityPicker;

  @override
  int get hashCode => Object.hash(create, priorityPicker);
}

class InteractionModesNotifier extends Notifier<InteractionModes> {
  static const String _kCreate = 'ui.createMode';
  static const String _kPriority = 'ui.priorityPicker';

  @override
  InteractionModes build() {
    unawaited(_restore());
    return const InteractionModes();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final createName = prefs.getString(_kCreate);
      final priorityName = prefs.getString(_kPriority);
      final create = CreateMode.values.firstWhere(
        (m) => m.name == createName,
        orElse: () => CreateMode.both,
      );
      final priority = PriorityPickerMode.values.firstWhere(
        (m) => m.name == priorityName,
        orElse: () => PriorityPickerMode.menu,
      );
      state = InteractionModes(create: create, priorityPicker: priority);
    } catch (error) {
      // 读不到就用默认值，不值得打扰用户
    }
  }

  Future<void> setCreate(CreateMode mode) async {
    state = state.copyWith(create: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCreate, mode.name);
    } catch (error) {
      // 忽略：下次启动回到默认
    }
  }

  Future<void> setPriorityPicker(PriorityPickerMode mode) async {
    state = state.copyWith(priorityPicker: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPriority, mode.name);
    } catch (error) {
      // 忽略：下次启动回到默认
    }
  }

  /// 依次切换（菜单里点一下轮换）
  Future<void> cycleCreate() {
    final next = switch (state.create) {
      CreateMode.both => CreateMode.longPress,
      CreateMode.longPress => CreateMode.doubleTap,
      CreateMode.doubleTap => CreateMode.both,
    };
    return setCreate(next);
  }

  Future<void> cyclePriorityPicker() {
    final next = state.priorityPicker == PriorityPickerMode.menu
        ? PriorityPickerMode.wheel
        : PriorityPickerMode.menu;
    return setPriorityPicker(next);
  }
}

final interactionModesProvider =
    NotifierProvider<InteractionModesNotifier, InteractionModes>(
      InteractionModesNotifier.new,
    );
