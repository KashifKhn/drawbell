import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawbell/main.dart';

void main() {
  testWidgets('DrawBell app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DrawBellApp()));
    await tester.pumpAndSettle();

    expect(find.text('DrawBell'), findsOneWidget);
  });
}
