/// 一条泳道。
///
/// 以前这是 `enum Lane { daily, habit, temp }`，后来用户要自己加、改名、排序，
/// 就改成一个简单的值对象：`id` 落库（`day_blocks.lane` 存的是这个 id），
/// `name` 是显示名，可改。默认那三条仍然用 `Lane.daily/habit/temp` 这个常量，
/// 数据库里它们的 id 就是 `daily` / `habit` / `temp`，升级时老数据按 index 映射过来。
class Lane {
  const Lane({required this.id, required this.name, this.sortOrder = 0});

  final String id;
  final String name;
  final int sortOrder;

  static const Lane daily = Lane(id: 'daily', name: '日常', sortOrder: 0);
  static const Lane habit = Lane(id: 'habit', name: '打卡', sortOrder: 1);
  static const Lane temp = Lane(id: 'temp', name: '临时', sortOrder: 2);

  static const List<Lane> defaults = [daily, habit, temp];

  Lane copyWith({String? name, int? sortOrder}) => Lane(
    id: id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  @override
  bool operator ==(Object other) => other is Lane && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Lane($id, $name)';
}
