import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_model.dart';
import '../../network_simulator/providers/network_simulator_provider.dart';
import '../logic/secure_transmission.dart';

class TransmissionActivity {
  const TransmissionActivity({
    required this.status,
    required this.payload,
    required this.networkMode,
    required this.timestamp,
  });

  final String status;
  final String payload;
  final String networkMode;
  final DateTime timestamp;
}

class TransmissionReceipt {
  const TransmissionReceipt({
    required this.timestamp,
    required this.chunksSent,
    required this.chunksDropped,
    required this.chunksUsed,
    required this.checksumMatch,
    required this.medGateStatus,
    required this.naiveStatus,
    required this.rebuilt,
    required this.sourceChecksum,
    required this.rebuiltChecksum,
  });

  final DateTime timestamp;
  final int chunksSent;
  final int chunksDropped;
  final int chunksUsed;
  final bool checksumMatch;
  final String medGateStatus;
  final String naiveStatus;
  final bool rebuilt;
  final String sourceChecksum;
  final String rebuiltChecksum;
}

class TransmissionState {
  const TransmissionState({
    this.status = 'idle',
    this.progress = 0,
    this.message = 'Waiting to transmit',
    this.history = const <TransmissionActivity>[],
    this.logs = const <String>[],
    this.receipts = const <TransmissionReceipt>[],
    this.survivalPercent = 0,
    this.resilienceScore = 0,
    this.lostPieces = 0,
    this.rebuilt = false,
    this.normalAppStatus = 'Waiting',
    this.doctorPayload = 'No patient data received yet',
    this.changedFields = const <String>[],
    this.chunkCount = 0,
    this.parityCount = 0,
    this.deltaPayload = '',
    this.encryptedPreview = '',
    this.proofSummary = 'Waiting for a transmission run',
  });

  final String status;
  final int progress;
  final String message;
  final List<TransmissionActivity> history;
  final List<String> logs;
  final List<TransmissionReceipt> receipts;
  final int survivalPercent;
  final int resilienceScore;
  final int lostPieces;
  final bool rebuilt;
  final String normalAppStatus;
  final String doctorPayload;
  final List<String> changedFields;
  final int chunkCount;
  final int parityCount;
  final String deltaPayload;
  final String encryptedPreview;
  final String proofSummary;
}

class TransmissionController extends Notifier<TransmissionState> {
  Map<String, String>? _lastSentRecord;

  @override
  TransmissionState build() => const TransmissionState();

  Future<void> sendTransmission({
    String payload = 'Patient record',
    String networkMode = 'stable',
  }) async {
    for (var step = 10; step <= 100; step += 10) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state = TransmissionState(
        status: step < 100 ? 'transmitting' : 'delivered',
        progress: step,
        message: step < 100
            ? 'Uploading packet $step%'
            : 'Transmission delivered',
        history: step < 100
            ? state.history
            : [
                TransmissionActivity(
                  status: 'delivered',
                  payload: payload,
                  networkMode: networkMode,
                  timestamp: DateTime.now(),
                ),
                ...state.history,
              ],
        logs: state.logs,
        receipts: state.receipts,
        doctorPayload: state.doctorPayload,
      );
    }
  }

  Future<void> sendPatientRecord({
    required PatientModel patient,
    int sparePieces = 3,
  }) async {
    final initialNetwork = ref.read(networkSimulatorProvider);
    final initialResult = simulateSecureTransmission(
      patient: patient,
      previousRecord: _lastSentRecord,
      reliability: initialNetwork.reliability,
      sparePieces: sparePieces,
    );
    if (!initialResult.delta.hasDelta) {
      state = TransmissionState(
        status: 'buffered',
        progress: 100,
        message: 'No new changes detected; buffer held',
        history: state.history,
        logs: ['Duplicate record skipped.', ...state.logs],
        receipts: state.receipts,
        survivalPercent: state.survivalPercent,
        resilienceScore: state.resilienceScore,
        doctorPayload: state.doctorPayload,
        normalAppStatus: state.normalAppStatus,
        deltaPayload: state.deltaPayload,
        encryptedPreview: state.encryptedPreview,
        proofSummary: 'No changed fields; duplicate buffered',
      );
      return;
    }

    late SecureTransmissionResult result;
    var reliability = initialNetwork.reliability;
    var latencyMs = initialNetwork.latencyMs;
    for (var step = 20; step <= 100; step += 20) {
      final liveNetwork = ref.read(networkSimulatorProvider);
      reliability = liveNetwork.reliability;
      latencyMs = liveNetwork.latencyMs;
      result = simulateSecureTransmission(
        patient: patient,
        previousRecord: _lastSentRecord,
        reliability: reliability,
        sparePieces: sparePieces,
      );
      await Future<void>.delayed(Duration(milliseconds: latencyMs ~/ 12));
      state = _stateFromResult(
        result,
        status: step < 100
            ? 'transmitting'
            : result.rebuilt
            ? 'delivered'
            : 'partial',
        progress: step,
        message: step < 100
            ? 'Sending priority chunks'
            : result.rebuilt
            ? 'Doctor record rebuilt'
            : 'Rebuild threshold missed',
        history: state.history,
        logs: state.logs,
        receipts: state.receipts,
        doctorPayload: state.doctorPayload,
      );
    }

    if (result.rebuilt) {
      _lastSentRecord = patient.toWireMap();
    }

    final receipt = _receiptFromResult(result);
    final activity = TransmissionActivity(
      status: result.rebuilt ? 'rebuilt' : 'partial',
      payload: result.delta.changedFields.join(', '),
      networkMode: '$reliability% / ${latencyMs}ms',
      timestamp: DateTime.now(),
    );
    state = _stateFromResult(
      result,
      status: result.rebuilt ? 'delivered' : 'partial',
      progress: 100,
      message: result.rebuilt
          ? 'Transmission delivered to doctor screen'
          : 'Partial data held for retry',
      history: [activity, ...state.history],
      logs: [
        '${result.lostPieces} chunks dropped; ${result.chunksUsed} rebuilt.',
        'Checksum ${result.checksumMatch ? 'matched' : 'mismatched'}: '
            '${result.sourceChecksum}.',
        'Compare: MedGate ${receipt.medGateStatus}; naive ${receipt.naiveStatus}.',
        'Delta fields: ${result.delta.changedFields.join(', ')}.',
        ...state.logs,
      ],
      receipts: [receipt, ...state.receipts],
      doctorPayload: result.rebuilt ? patient.toPayload() : state.doctorPayload,
    );
  }

  TransmissionState _stateFromResult(
    SecureTransmissionResult result, {
    required String status,
    required int progress,
    required String message,
    required List<TransmissionActivity> history,
    required List<String> logs,
    required List<TransmissionReceipt> receipts,
    required String doctorPayload,
  }) {
    return TransmissionState(
      status: status,
      progress: progress,
      message: message,
      history: history,
      logs: logs,
      receipts: receipts,
      survivalPercent: result.survivalPercent,
      resilienceScore: result.survivalPercent,
      lostPieces: result.lostPieces,
      rebuilt: result.rebuilt,
      normalAppStatus: result.naiveStatus,
      doctorPayload: doctorPayload,
      changedFields: result.delta.changedFields,
      chunkCount: result.chunkCount,
      parityCount: result.parityCount,
      deltaPayload: result.delta.payload,
      encryptedPreview: result.payload,
      proofSummary: result.rebuilt
          ? 'Rebuilt from ${result.chunksUsed}/${result.chunksSent} chunks'
          : 'Partial delivery; ${result.lostPieces} chunks dropped',
    );
  }

  TransmissionReceipt _receiptFromResult(SecureTransmissionResult result) {
    return TransmissionReceipt(
      timestamp: DateTime.now(),
      chunksSent: result.chunksSent,
      chunksDropped: result.lostPieces,
      chunksUsed: result.chunksUsed,
      checksumMatch: result.checksumMatch,
      medGateStatus: result.rebuilt ? 'Rebuilt' : 'Partial',
      naiveStatus: result.naiveStatus,
      rebuilt: result.rebuilt,
      sourceChecksum: result.sourceChecksum,
      rebuiltChecksum: result.rebuiltChecksum,
    );
  }
}

final transmissionProvider =
    NotifierProvider<TransmissionController, TransmissionState>(
      TransmissionController.new,
    );
