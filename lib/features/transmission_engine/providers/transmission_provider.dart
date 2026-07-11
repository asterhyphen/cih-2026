import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_model.dart';
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

class TransmissionState {
  const TransmissionState({
    this.status = 'idle',
    this.progress = 0,
    this.message = 'Waiting to transmit',
    this.history = const <TransmissionActivity>[],
    this.logs = const <String>[],
    this.survivalPercent = 0,
    this.lostPieces = 0,
    this.rebuilt = false,
    this.normalAppStatus = 'Waiting',
    this.doctorPayload = 'No patient data received yet',
    this.changedFields = const <String>[],
    this.chunkCount = 0,
    this.parityCount = 0,
  });

  final String status;
  final int progress;
  final String message;
  final List<TransmissionActivity> history;
  final List<String> logs;
  final int survivalPercent;
  final int lostPieces;
  final bool rebuilt;
  final String normalAppStatus;
  final String doctorPayload;
  final List<String> changedFields;
  final int chunkCount;
  final int parityCount;
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
      );
    }
  }

  Future<void> sendPatientRecord({
    required PatientModel patient,
    required int reliability,
    required int latencyMs,
    int sparePieces = 3,
  }) async {
    final result = simulateSecureTransmission(
      patient: patient,
      previousRecord: _lastSentRecord,
      reliability: reliability,
      sparePieces: sparePieces,
    );
    if (!result.delta.hasDelta) {
      state = TransmissionState(
        status: 'buffered',
        progress: 100,
        message: 'No new changes detected; buffer held and nothing sent',
        history: state.history,
        logs: [
          'Record matched last delivery; skipped duplicate send.',
          ...state.logs,
        ],
        survivalPercent: state.survivalPercent,
        doctorPayload: state.doctorPayload,
        normalAppStatus: state.normalAppStatus,
      );
      return;
    }

    for (var step = 20; step <= 100; step += 20) {
      await Future<void>.delayed(Duration(milliseconds: latencyMs ~/ 12));
      state = TransmissionState(
        status: step < 100
            ? 'transmitting'
            : result.rebuilt
            ? 'delivered'
            : 'partial',
        progress: step,
        message: step < 100
            ? 'Sending urgent vitals before photo data'
            : result.rebuilt
            ? 'Doctor record rebuilt from protected chunks'
            : 'Not enough chunks survived for full rebuild',
        history: state.history,
        logs: state.logs,
        survivalPercent: result.survivalPercent,
        lostPieces: result.lostPieces,
        rebuilt: result.rebuilt,
        normalAppStatus: result.lostPieces > 0
            ? 'Frozen waiting for resend'
            : 'Delivered',
        doctorPayload: state.doctorPayload,
        changedFields: result.delta.changedFields,
        chunkCount: result.chunkCount,
        parityCount: result.parityCount,
      );
    }

    if (result.rebuilt) {
      _lastSentRecord = patient.toWireMap();
    }

    final activity = TransmissionActivity(
      status: result.rebuilt ? 'rebuilt' : 'partial',
      payload: result.delta.changedFields.join(', '),
      networkMode: '$reliability% / ${latencyMs}ms',
      timestamp: DateTime.now(),
    );
    state = TransmissionState(
      status: result.rebuilt ? 'delivered' : 'partial',
      progress: 100,
      message: result.rebuilt
          ? 'Transmission delivered to doctor screen'
          : 'Partial data held for retry',
      history: [activity, ...state.history],
      logs: [
        '${result.lostPieces} pieces were lost; ${result.rebuilt ? 'message rebuilt anyway' : 'waiting for retry'}.',
        'Delta sent: ${result.delta.changedFields.join(', ')}.',
        'Encrypted payload: ${result.encryptedByteCount} bytes.',
        'Priority queue sent ${result.firstPayloadLabel} first.',
        ...state.logs,
      ],
      survivalPercent: result.survivalPercent,
      lostPieces: result.lostPieces,
      rebuilt: result.rebuilt,
      normalAppStatus: result.lostPieces > 0
          ? 'Frozen waiting for resend'
          : 'Delivered',
      doctorPayload: result.rebuilt ? patient.toPayload() : state.doctorPayload,
      changedFields: result.delta.changedFields,
      chunkCount: result.chunkCount,
      parityCount: result.parityCount,
    );
  }
}

final transmissionProvider =
    NotifierProvider<TransmissionController, TransmissionState>(
      TransmissionController.new,
    );
