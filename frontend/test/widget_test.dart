import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';

void main() {
  testWidgets('landing shows the V3 pitch and both CTAs', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SplashPage()));
    await tester.pumpAndSettle();

    // Display text is uppercased for rendering, sentence case for screen readers.
    expect(find.text('LESS “WE SHOULD HANG.” MORE HANGING.'), findsOneWidget);
    expect(find.bySemanticsLabel('Less “we should hang.” More hanging.'), findsOneWidget);
    expect(find.text('Send a friend one plan. They get 10 minutes to say yes or no. No group chat, no “maybe”.'), findsOneWidget);
    expect(find.text('I’m in'), findsOneWidget);
    expect(find.text('I’ve got an account'), findsOneWidget);
  });
}
