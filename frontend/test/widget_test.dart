import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';

void main() {
  testWidgets('landing shows the V3 pitch and both CTAs', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SplashPage()));
    await tester.pumpAndSettle();

    // Display text is uppercased for rendering, sentence case for screen readers.
    expect(find.text('SKIP THE GROUP CHAT.'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip the group chat.'), findsOneWidget);
    expect(find.text('Send one clear plan. Get one clear answer.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
