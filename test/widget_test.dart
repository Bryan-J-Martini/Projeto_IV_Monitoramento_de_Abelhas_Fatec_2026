import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_abelhas/main.dart';
import 'package:flutter_abelhas/models/telemetry_model.dart';
import 'package:flutter_abelhas/views/hive/add_hive_view.dart';
import 'package:flutter_abelhas/views/auth/login_view.dart';

void main() {
  testWidgets('MeliponaApp smoke test - Login carrega e abre cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MeliponaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BeeVision'), findsOneWidget);
    expect(find.text('Email:'), findsOneWidget);
    expect(find.text('Senha:'), findsOneWidget);
    expect(find.textContaining('Cadastro'), findsOneWidget);

    await tester.tap(find.textContaining('Cadastro'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroView), findsOneWidget);
  });

  test(
    'TelemetryModel calculo biologico de temperatura ideal',
    () {
      final idealTelemetry = TelemetryModel(
        internalTemp: 28.5,
        trafficIn: 30,
        trafficOut: 25,
        externalTemp: 27.0,
        externalHumidity: 60.0,
        timestamp: DateTime.now(),
      );

      expect(idealTelemetry.isThermallyIdeal, isTrue);
      expect(idealTelemetry.isTooCold, isFalse);
      expect(idealTelemetry.isTooHot, isFalse);
      expect(idealTelemetry.beeMood, equals('happy'));

      final coldTelemetry = idealTelemetry.copyWith(internalTemp: 23.0);
      expect(coldTelemetry.isThermallyIdeal, isFalse);
      expect(coldTelemetry.isTooCold, isTrue);
      expect(coldTelemetry.beeMood, equals('cold'));

      final hotTelemetry = idealTelemetry.copyWith(internalTemp: 34.5);
      expect(hotTelemetry.isThermallyIdeal, isFalse);
      expect(hotTelemetry.isTooHot, isTrue);
      expect(hotTelemetry.beeMood, equals('hot'));
    },
  );

  testWidgets('Adicionar colmeia carrega a tela sem excecao', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddHiveView()),
    );
    await tester.pump();

    expect(find.textContaining('Adicionar'), findsWidgets);
    expect(find.textContaining('JATA'), findsOneWidget);
  });
}
