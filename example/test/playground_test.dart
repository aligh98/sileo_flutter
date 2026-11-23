import 'package:flutter_test/flutter_test.dart';
import 'package:sileo_glass/sileo_glass.dart';
import 'package:sileo_glass_example/main.dart';

void main() {
  testWidgets('Playground app launches and fires toasts cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(const SileoPlaygroundApp());
    expect(find.textContaining('Sileo'), findsWidgets);

    await tester.tap(find.text('Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Changes Saved'), findsOneWidget);

    await tester.tap(find.text('فارسی RTL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('تغییرات ذخیره شد'), findsOneWidget);

    await tester.tap(find.text('Surface: Solid'));
    await tester.pump();
    expect(find.text('Surface: Liquid Glass'), findsOneWidget);
    await tester.tap(find.text('Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Changes Saved'), findsOneWidget);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();
    expect(Sileo.instance.toasts, isEmpty);
  });
}
