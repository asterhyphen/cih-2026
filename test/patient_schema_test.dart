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
    test('does not smooth confidence upward beyond recovery bounds', () {
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

      expect(xorResult.confidencePercent, 100);
      expect(rsResult.state, RecoveryState.recovered);
      final failed = rs.evaluate(
        expectedChunks: 8,
        receivedChunks: 3,
        recoveryChunks: 2,
        recoveredFields: ['bloodPressure'],
        checksumMatched: false,
      );
      expect(failed.confidencePercent, 38);
      expect(failed.state, RecoveryState.degraded);
    });
  });
}
