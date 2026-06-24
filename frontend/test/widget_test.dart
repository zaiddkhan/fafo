import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fafu/src/app.dart';

void main() {
  testWidgets('renders landing screen CTAs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FafoApp()));

    await tester.pumpAndSettle();

    expect(
      find.text('Discover\nwhat\'s happening\naround you'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
