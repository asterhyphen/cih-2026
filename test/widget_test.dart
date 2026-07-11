import 'package:cih/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MedGateApp()));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
