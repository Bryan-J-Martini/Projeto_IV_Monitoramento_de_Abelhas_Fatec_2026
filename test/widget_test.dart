import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_abelhas/main.dart';
import 'package:flutter_abelhas/models/telemetry_model.dart';

void main() {
  testWidgets('MeliponaApp smoke test - Dashboard carrega colmeias', (
    WidgetTester tester,
  ) async {
    // Carrega a aplicação completa
    await tester.pumpWidget(const MeliponaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica elementos fundamentais do Dashboard
    expect(find.text('Colmeias Conectadas'), findsOneWidget);
    expect(find.text('Jataí 01'), findsOneWidget);
    expect(find.text('Mandaçaia A'), findsOneWidget);
  });

  test(
    'TelemetryModel cálculo biológico de temperatura ideal (26°C a 32°C)',
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
}
