// Test widget de base pour l'application E-Santé

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hopital/main.dart';

void main() {
  testWidgets('Application démarre correctement', (WidgetTester tester) async {
    // Build l'application et déclenche un frame.
    await tester.pumpWidget(const ESanteApp());

    // Vérifie que l'écran splash s'affiche
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
