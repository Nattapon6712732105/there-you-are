// Basic Flutter widget test for There You Are app.

import 'package:flutter_test/flutter_test.dart';
import 'package:there_you_are/main.dart';

void main() {
  testWidgets('App smoke test - renders MyApp', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify MyApp renders
    expect(find.byType(MyApp), findsOneWidget);
  });
}

