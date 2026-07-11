import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart';

import '../../data/patient_model.dart';
import 'chunking.dart';
import 'delta_encoder.dart';
import 'priority_queue.dart';
import 'protocol_engine.dart';

class SecureTransmissionResult {
  const SecureTransmissionResult({
    required this.delta,
    required this.lostPieces,
    required this.rebuilt,
    required this.survivalPercent,
    required this.chunkCount,
    required this.parityCount,
    required this.chunksSent,
    required this.chunksUsed,
    required this.checksumMatch,
    required this.sourceChecksum,
    required this.rebuiltChecksum,
    required this.naiveStatus,
    required this.naiveSucceeded,
    required this.firstPayloadLabel,
    required this.encryptedByteCount,
    required this.payload,
    required this.compressedByteCount,
    required this.originalByteCount,
    required this.compressionRatio,
    required this.fallbackTriggered,
    required this.fallbackTriggerAttempt,
    required this.fallbackImageTier,
  });

  final DeltaResult delta;
  final int lostPieces;
  final bool rebuilt;
  final int survivalPercent;
  final int chunkCount;
  final int parityCount;
  final int chunksSent;
  final int chunksUsed;
  final bool checksumMatch;
  final String sourceChecksum;
  final String rebuiltChecksum;
  final String naiveStatus;
  final bool naiveSucceeded;
  final String firstPayloadLabel;
  final int encryptedByteCount;
  final String payload;
  final int compressedByteCount;
  final int originalByteCount;
  final double compressionRatio;
  final bool fallbackTriggered;
  final int fallbackTriggerAttempt;
  final String fallbackImageTier;
}

SecureTransmissionResult simulateSecureTransmission({
  required PatientModel patient,
  required Map<String, String>? previousRecord,
  required int reliability,
  int sparePieces = 3,
  int chunkSize = 18,
  bool urgent = false,
  int retryAttempt = 0,
}) {
  final delta = encodeDelta(patient.toWireMap(), previousRecord);
  final plan = buildClinicalTransmissionPlan(patient);
  final clinicalPayloads = plan.priorityFields
      .map(
        (field) => QueuedPayload(
          label: field.label,
          payload: _encrypted('${field.priority.name}:${field.value}'),
          priority: switch (field.priority) {
            ClinicalPriority.critical => TransmissionPriority.urgent,
            ClinicalPriority.high => TransmissionPriority.urgent,
            ClinicalPriority.medium => TransmissionPriority.routine,
            ClinicalPriority.low => TransmissionPriority.media,
          },
        ),
      )
      .toList();
  final queue = prioritizePayloads([
    if (urgent || patient.urgent)
      QueuedPayload(
        label: 'manual urgent flag',
        payload: _encrypted(buildEmergencySnapshot(patient)),
        priority: TransmissionPriority.emergency,
      ),
    QueuedPayload(
      label: 'urgent vitals',
      payload: _encrypted(delta.payload),
      priority: TransmissionPriority.urgent,
    ),
    ...clinicalPayloads,
    if (patient.notes.trim().isNotEmpty)
      QueuedPayload(
        label: 'clinical note',
        payload: _encrypted(patient.notes),
        priority: TransmissionPriority.routine,
      ),
    if (patient.photoRef.trim().isNotEmpty)
      QueuedPayload(
        label: 'photo reference',
        payload: _encrypted(patient.photoRef),
        priority: TransmissionPriority.media,
      ),
  ]);
  final basePayload = queue
      .map((item) => '${item.label}:${item.payload}')
      .join(';');
  // Compress before encrypt so the payload is reduced with DEFLATE/gzip and the
  // ciphertext does not remain as raw, incompressible noise.
  final compressedPayload = _compressPayload(basePayload);
  final encryptedPayload = _encrypted(compressedPayload);
  final chunks = buildProtectedChunks(
    encryptedPayload,
    chunkSize: chunkSize,
    sparePieces: sparePieces,
  );
  final lossRate = ((100 - reliability) / 100).clamp(0.0, 0.9);
  final lostPieces = (chunks.length * lossRate).ceil();
  final dataChunks = chunks.where((chunk) => !chunk.parity).length;
  final rebuilt = lostPieces <= sparePieces;
  final chunksUsed = (chunks.length - lostPieces)
      .clamp(0, chunks.length)
      .toInt();
  final sourceChecksum = _checksum(delta.payload);
  final fallbackTriggered = urgent || (retryAttempt >= 3 && reliability < 60);
  final fallbackTriggerAttempt = urgent ? 0 : (retryAttempt + 1).clamp(0, 4);
  final fallbackImageTier = urgent && fallbackTriggered
      ? 'tiny-blurred-thumbnail'
      : '';
  final rebuiltChecksum = rebuilt
      ? sourceChecksum
      : _checksum('partial:$basePayload');
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
    chunksSent: chunks.length,
    chunksUsed: chunksUsed,
    checksumMatch: rebuilt && sourceChecksum == rebuiltChecksum,
    sourceChecksum: sourceChecksum,
    rebuiltChecksum: rebuiltChecksum,
    naiveStatus: lostPieces == 0
        ? 'Delivered'
        : reliability < 65
        ? 'Failed after full resend'
        : 'Stalled on full resend',
    naiveSucceeded: lostPieces == 0,
    firstPayloadLabel: queue.first.label,
    encryptedByteCount: utf8.encode(encryptedPayload).length,
    payload: encryptedPayload,
    compressedByteCount: utf8.encode(compressedPayload).length,
    originalByteCount: utf8.encode(basePayload).length,
    compressionRatio: _compressionRatio(basePayload, compressedPayload),
    fallbackTriggered: fallbackTriggered,
    fallbackTriggerAttempt: fallbackTriggerAttempt,
    fallbackImageTier: fallbackImageTier,
  );
}

String _compressPayload(String value) {
  final input = utf8.encode(value);
  final gzip = GZipEncoder();
  final output = gzip.encode(input);
  return base64.encode(output);
}

String _decryptPayload(String value) {
  final decoded = base64.decode(value);
  final gzip = GZipDecoder();
  final output = gzip.decodeBytes(decoded);
  return utf8.decode(output);
}

String _checksum(String value) {
  final hash = value.codeUnits.fold<int>(
    0x811c9dc5,
    (current, unit) => (current ^ unit) * 0x01000193,
  );
  return hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
}

double _compressionRatio(String original, String compressed) {
  final originalBytes = utf8.encode(original).length;
  final compressedBytes = utf8.encode(compressed).length;
  if (originalBytes <= 0) {
    return 1.0;
  }
  return (originalBytes / compressedBytes).clamp(0.0, 10.0);
}

String _encrypted(String value) {
  final key = Key.fromUtf8('0123456789abcdef0123456789abcdef');
  final iv = IV.fromSecureRandom(16);
  final encrypted = Encrypter(AES(key)).encrypt(value, iv: iv);
  return '${iv.base64}:${encrypted.base64}';
}

String compressAndEncryptPayload(String payload) {
  final compressedPayload = _compressPayload(payload);
  return _encrypted(compressedPayload);
}

String decryptAndDecompressPayload(String payload) {
  final parts = payload.split(':');
  if (parts.length < 2) {
    return payload;
  }
  final iv = IV.fromBase64(parts.first);
  final ciphertext = parts.sublist(1).join(':');
  final decrypted = Encrypter(
    AES(Key.fromUtf8('0123456789abcdef0123456789abcdef')),
  ).decrypt(Encrypted.fromBase64(ciphertext), iv: iv);
  return _decryptPayload(decrypted);
}
