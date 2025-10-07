import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:tir_sportif/providers/home_screen_provider.dart';

void main() {
  group('HomeScreenProvider', () {
    test('initializes with isLoading=true', () {
      final provider = HomeScreenProvider();
      expect(provider.isLoading, true);
    });
  });

  testWidgets('HomeScreenProvider works with Consumer', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => HomeScreenProvider(),
          child: Consumer<HomeScreenProvider>(
            builder: (context, provider, _) {
              return Scaffold(
                body: provider.isLoading
                    ? const CircularProgressIndicator()
                    : Text('Data loaded'),
              );
            },
          ),
        ),
      ),
    );

    // Initially should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Data loaded'), findsNothing);
  });
}