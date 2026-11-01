import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

void main() {
  testWidgets('welcome shows the pitch and both ways in', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SplashPage()));
    await tester.pumpAndSettle();

    // Display text is uppercased for rendering, sentence case for screen readers.
    expect(find.text('PLANS IN\nTEN MINUTES.'), findsOneWidget);
    expect(find.bySemanticsLabel('Plans in ten minutes.'), findsOneWidget);
    expect(find.text('Send one clear plan. Get one clear answer. No group chat.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('log in: Send code lights up at 10 digits', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.light, home: const LoginPage())));
    FafoPill send() => tester.widget<FafoPill>(find.widgetWithText(FafoPill, 'Send code'));

    expect(send().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '98765 4321');
    await tester.pump();
    expect(send().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '98765 43210');
    await tester.pump();
    expect(send().onPressed, isNotNull);
  });

  testWidgets('sign up: Send code needs 10 digits and the 18+ consent', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.light, home: const SignupPage())));
    FafoPill send() => tester.widget<FafoPill>(find.widgetWithText(FafoPill, 'Send code'));

    await tester.enterText(find.byType(TextField), '98765 43210');
    await tester.pump();
    expect(send().onPressed, isNull);
    await tester.tap(find.byType(FafoConsentCheck));
    await tester.pump();
    expect(send().onPressed, isNotNull);
  });

  testWidgets('a real sheet and modal open without errors', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showFafoSheet<void>(
                context,
                title: 'Plan',
                builder: (_) => const FafoSheetBody(children: [Text('Body')]),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    final handle = tester.ensureSemantics();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Plan'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);

    final context = tester.element(find.text('open'));
    final result = showFafoConfirm(context, title: 'Leave Flatmates?', message: 'Gone.', confirmLabel: 'Leave group');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    handle.dispose();
  });
}
