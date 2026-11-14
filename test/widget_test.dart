import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/app.dart';

void main() {
  testWidgets('时间轴首屏能渲染出顶栏', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TntApp()));
    await tester.pump();
    expect(find.text('今天'), findsOneWidget);
  });
}
