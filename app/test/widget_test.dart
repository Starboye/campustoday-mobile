import 'package:campustoday_app/core/offline/offline_banner.dart';
import 'package:campustoday_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('ProviderScope + MaterialApp smoke test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(child: Text('CampusToday')),
          ),
        ),
      ),
    );

    expect(find.text('CampusToday'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('OfflineBanner Phase 5 stub renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OfflineBanner(
          child: Text('CampusToday content'),
        ),
      ),
    );

    expect(find.text('CampusToday content'), findsOneWidget);
  });
}
