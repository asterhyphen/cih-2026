import 'dart:convert';

import 'package:encrypt/encrypt.dart';

import '../../data/patient_model.dart';
import 'chunking.dart';
import 'delta_encoder.dart';
import 'priority_queue.dart';

class SecureTransmissionResult {
  const SecureTransmissionResult({
    required this.delta,
    required this.lostPieces,
    required this.rebuilt,
    required this.survivalPercent,
    required this.chunkCount,
    required this.parityCount,
    required this.firstPayloadLabel,
    required this.encryptedByteCount,
    required this.payload,
  });

  final DeltaResult delta;
  final int lostPieces;
  final bool rebuilt;
  final int survivalPercent;
  final int chunkCount;
  final int parityCount;
  final String firstPayloadLabel;
  final int encryptedByteCount;
  final String payload;
}

SecureTransmissionResult simulateSecureTransmission({
  required PatientModel patient,
  required Map<String, String>? previousRecord,
  required int reliability,
  int sparePieces = 3,
}) {
  final delta = encodeDelta(patient.toWireMap(), previousRecord);
  final queue = prioritizePayloads([
    QueuedPayload(
      label: 'urgent vitals',
      payload: _encrypted(delta.payload),
      priority: TransmissionPriority.urgent,
    ),
    QueuedPayload(
      label: 'clinical note',
      payload: _encrypted(patient.notes),
      priority: TransmissionPriority.routine,
    ),
    QueuedPayload(
      label: 'photo reference',
      payload: _encrypted(patient.photoRef),
      priority: TransmissionPriority.media,
    ),
  ]);
  final payload = queue
      .map((item) => '${item.label}:${item.payload}')
      .join(';');
  final chunks = buildProtectedChunks(payload, sparePieces: sparePieces);
  final lossRate = ((100 - reliability) / 100).clamp(0.0, 0.9);
  final lostPieces = (chunks.length * lossRate).ceil();
  final dataChunks = chunks.where((chunk) => !chunk.parity).length;
  final rebuilt = lostPieces <= sparePieces;
  final survival = rebuilt
      ? 100
      : (((chunks.length - lostPieces) / dataChunks) * 100)
            .clamp(0, 100)
            .round();

  return SecureTransmissionResult(
    delta: delta,
    lostPieces: lostPieces,
    rebuilt: rebuilt,
    survivalPercent: survival,
    chunkCount: dataChunks,
    parityCount: sparePieces,
    firstPayloadLabel: queue.first.label,
    encryptedByteCount: utf8.encode(payload).length,
    payload: payload,
  );
}

String _encrypted(String value) {
  final key = Key.fromUtf8('0123456789abcdef0123456789abcdef');
  final iv = IV.fromSecureRandom(16);
  final encrypted = Encrypter(AES(key)).encrypt(value, iv: iv);
  return '${iv.base64}:${encrypted.base64}';
}
