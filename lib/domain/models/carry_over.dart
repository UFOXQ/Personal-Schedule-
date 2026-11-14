/// 顺延候选：某天没做完的一条方块
library;

import 'tblock.dart';

class CarryOver {
  const CarryOver({required this.date, required this.block});

  /// 原方块所在日期，yyyy-MM-dd
  final String date;

  final TBlock block;
}
