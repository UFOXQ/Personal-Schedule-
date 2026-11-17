import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tnt_app/features/widgets/number_slider.dart';

void main() {
  testWidgets('点数字能直接输入，按步长取整并夹在范围内', (tester) async {
    double? got;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: NumberSlider(
                label: '手柄大小',
                value: 1.0,
                min: 0.8,
                max: 1.6,
                step: 0.1,
                display: (v) => '${(v * 100).round()}%',
                onChanged: (v) => got = v,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('number-slider-value')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('number-slider-input')), '1.37');
    await tester.tap(find.byKey(const Key('number-slider-confirm')));
    await tester.pumpAndSettle();

    expect(got, closeTo(1.4, 1e-9), reason: '1.37 按 0.1 步长应取整到 1.4');

    await tester.tap(find.byKey(const Key('number-slider-value')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('number-slider-input')), '99');
    await tester.tap(find.byKey(const Key('number-slider-confirm')));
    await tester.pumpAndSettle();

    expect(got, closeTo(1.6, 1e-9), reason: '超出上限应夹到 max');
  });
}
