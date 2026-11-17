/// 从日历/周视图跳回时间轴时带的落脚点。
///
/// [minute] 为空表示只要到那一天；有值时时间轴会滚到那个时刻附近。
typedef DayJump = ({String date, int? minute});
