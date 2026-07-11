import 'package:cih/features/data/patient_model.dart';
import 'package:cih/features/transmission_engine/logic/recovery_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patient schema', () {
    test('round-trips positional payloads through the shared schema', () {
      final patient = PatientModel(
        id: 'P7',
        displayName: 'Ada Lovelace',
        age: 36,
        bloodPressure: '120/80',
        heartRate: 72,
        oxygenSaturation: 98,
        temperature: 36.7,
        notes: 'Stable',
        photoRef: 'img-7',
        urgent: true,
        symptoms: 'Fatigue',
      );

      final payload = patient.toPayload();
      final decoded = PatientModel.fromPayload(payload);

      expect(payload, startsWith('MGP1|'));
      expect(decoded.displayName, 'Ada Lovelace');
      expect(decoded.bloodPressure, '120/80');
      expect(decoded.urgent, isTrue);
      expect(decoded.symptoms, 'Fatigue');
    });
  });

  group('recovery strategy', () {
    test('reports a higher confidence score for RS-style recovery', () {
      const xor = XorParityRecoveryStrategy();
      const rs = ReedSolomonRecoveryStrategy();

      final xorResult = xor.evaluate(
        expectedChunks: 8,
        receivedChunks: 6,
        recoveryChunks: 2,
        recoveredFields: ['bloodPressure', 'heartRate'],
        checksumMatched: false,
      );
      final rsResult = rs.evaluate(
        expectedChunks: 8,
        receivedChunks: 6,
        recoveryChunks: 2,
        recoveredFields: ['bloodPressure', 'heartRate'],
        checksumMatched: false,
      );

      expect(xorResult.confidencePercent, lessThan(rsResult.confidencePercent));
      expect(rsResult.state, RecoveryState.recovered);
    });
  });
}
