import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tnt_app/features/onboarding/onboarding_page.dart';

void main() {
  testWidgets('引导四页，翻到最后开始用会回调', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onDone: () async => done++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('一天三层，纵向是时间'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('按住才能改，轻点只是选中'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('整块搬：合集与长期计划'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('不改也能用：提醒 + 时间条'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('不确定就先锁上'), findsOneWidget);
    expect(find.text('开始用'), findsOneWidget);

    await tester.tap(find.text('开始用'));
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('跳过直接结束', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onDone: () async => done++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(done, 1);
  });
}
