import 'package:campustoday_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('CampusTodayApp smoke test pumps without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusTodayApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
