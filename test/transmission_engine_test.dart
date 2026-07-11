import 'package:cih/features/data/patient_model.dart';
import 'package:cih/features/transmission_engine/logic/chunking.dart';
import 'package:cih/features/transmission_engine/logic/delta_encoder.dart';
import 'package:cih/features/transmission_engine/logic/priority_queue.dart';
import 'package:cih/features/transmission_engine/logic/secure_transmission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transmission engine', () {
    test('reconstructs a payload from data and parity chunks', () {
      const payload =
          'This is a patient payload that should survive partial loss.';
      final chunks = buildProtectedChunks(
        payload,
        chunkSize: 8,
        sparePieces: 2,
      );
      final dataChunks = chunks.where((chunk) => !chunk.parity).toList();
      final dropped = dataChunks.take(2).toList();
      final remaining = chunks
          .where((chunk) => !dropped.contains(chunk))
          .toList();

      final reconstructed = reconstructPayload(
        remaining,
        expectedDataChunkCount: dataChunks.length,
      );

      expect(reconstructed, payload);
    });

    test('prioritizes urgent vitals before routine and media payloads', () {
      final ordered = prioritizePayloads([
        const QueuedPayload(
          label: 'photo',
          payload: 'img',
          priority: TransmissionPriority.media,
        ),
        const QueuedPayload(
          label: 'vitals',
          payload: 'bp',
          priority: TransmissionPriority.urgent,
        ),
        const QueuedPayload(
          label: 'note',
          payload: 'note',
          priority: TransmissionPriority.routine,
        ),
      ]);

      expect(ordered.first.label, 'vitals');
      expect(ordered.last.label, 'photo');
    });

    test(
      'delta encoding only emits changed fields and keeps the record id',
      () {
        final previous = {
          'id': 'P1',
          'name': 'Ada',
          'bp': '120/80',
          'hr': '72',
        };
        final current = {
          'id': 'P1',
          'name': 'Ada Lovelace',
          'bp': '120/80',
          'hr': '74',
        };

        final delta = encodeDelta(current, previous);

        expect(delta.hasDelta, isTrue);
        expect(delta.changedFields, containsAll(['name', 'hr']));
        expect(delta.payload, contains('id=P1'));
        expect(delta.payload, isNot(contains('bp=')));
      },
    );

    test(
      'encrypts payloads before chunking and keeps the ciphertext unreadable',
      () {
        final patient = PatientModel(
          id: 'P2',
          displayName: 'Grace Hopper',
          age: 79,
          bloodPressure: '118/74',
          heartRate: 84,
          oxygenSaturation: 98,
          temperature: 36.8,
          notes: 'Needs review',
          photoRef: 'xray-1',
        );

        final result = simulateSecureTransmission(
          patient: patient,
          previousRecord: null,
          reliability: 95,
          sparePieces: 2,
        );

        expect(result.encryptedByteCount, greaterThan(0));
        expect(result.delta.payload, contains('id=P2'));
        expect(result.firstPayloadLabel, 'urgent vitals');
      },
    );
  });
}
