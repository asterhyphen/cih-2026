import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_model.dart';
import '../../network_simulator/providers/network_simulator_provider.dart';
import '../logic/protocol_engine.dart';
import '../logic/recovery_strategy.dart';
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

class TransmissionQueueItem {
  const TransmissionQueueItem({
    required this.id,
    required this.status,
    required this.summary,
    required this.packetCount,
    required this.retryCount,
    required this.createdAt,
    required this.payload,
    this.isUrgent = false,
  });

  final String id;
  final String status;
  final String summary;
  final int packetCount;
  final int retryCount;
  final DateTime createdAt;
  final String payload;
  final bool isUrgent;

  TransmissionQueueItem copyWith({
    String? id,
    String? status,
    String? summary,
    int? packetCount,
    int? retryCount,
    DateTime? createdAt,
    String? payload,
    bool? isUrgent,
  }) {
    return TransmissionQueueItem(
      id: id ?? this.id,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      packetCount: packetCount ?? this.packetCount,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

class TransmissionTimelineEvent {
  const TransmissionTimelineEvent({
    required this.label,
    required this.status,
    required this.timestamp,
  });

  final String label;
  final String status;
  final DateTime timestamp;
}

class TransmissionState {
  const TransmissionState({
    this.status = 'idle',
    this.progress = 0,
    this.message = 'Waiting to transmit',
    this.history = const <TransmissionActivity>[],
    this.logs = const <String>[],
    this.receipts = const <TransmissionReceipt>[],
    this.queueItems = const <TransmissionQueueItem>[],
    this.timeline = const <TransmissionTimelineEvent>[],
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
    this.priorityFields = const <ClinicalField>[],
    this.sections = const <TransmissionSection>[],
    this.validationIssues = const <ValidationIssue>[],
    this.emergencySnapshot = '',
    this.bandwidthBudget = 512,
    this.currentUsage = 0,
    this.urgentCase = false,
    this.compressedByteCount = 0,
    this.originalByteCount = 0,
    this.fallbackTriggered = false,
    this.fallbackTriggerAttempt = 0,
    this.fallbackImageTier = '',
    this.remainingBudget = 512,
    this.compressionRatio = 1.0,
    this.packetLoss = 0,
    this.latency = 0,
    this.recoveryPercent = 0,
    this.recoveryConfidencePercent = 0,
    this.recoveryMessage = 'Waiting for a recovery run',
    this.recoveryState = 'idle',
    this.estimatedDeliveryTime = 0,
    this.missingChunkIds = const <String>[],
    this.retransmittedChunkIds = const <String>[],
    this.activeStrategy = 'Balanced',
    this.chunkSize = 18,
    this.compressionLevel = 1,
    this.redundancy = 2,
    this.parityPackets = 2,
    this.networkProfile = 'Medium',
  });

  final String status;
  final int progress;
  final String message;
  final List<TransmissionActivity> history;
  final List<String> logs;
  final List<TransmissionReceipt> receipts;
  final List<TransmissionQueueItem> queueItems;
  final List<TransmissionTimelineEvent> timeline;
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
  final List<ClinicalField> priorityFields;
  final List<TransmissionSection> sections;
  final List<ValidationIssue> validationIssues;
  final String emergencySnapshot;
  final int bandwidthBudget;
  final int currentUsage;
  final bool urgentCase;
  final int compressedByteCount;
  final int originalByteCount;
  final bool fallbackTriggered;
  final int fallbackTriggerAttempt;
  final String fallbackImageTier;
  final int remainingBudget;
  final double compressionRatio;
  final int packetLoss;
  final int latency;
  final int recoveryPercent;
  final int recoveryConfidencePercent;
  final String recoveryMessage;
  final String recoveryState;
  final int estimatedDeliveryTime;
  final List<String> missingChunkIds;
  final List<String> retransmittedChunkIds;
  final String activeStrategy;
  final int chunkSize;
  final int compressionLevel;
  final int redundancy;
  final int parityPackets;
  final String networkProfile;

  TransmissionState copyWith({
    String? status,
    int? progress,
    String? message,
    List<TransmissionActivity>? history,
    List<String>? logs,
    List<TransmissionReceipt>? receipts,
    List<TransmissionQueueItem>? queueItems,
    List<TransmissionTimelineEvent>? timeline,
    int? survivalPercent,
    int? resilienceScore,
    int? lostPieces,
    bool? rebuilt,
    String? normalAppStatus,
    String? doctorPayload,
    List<String>? changedFields,
    int? chunkCount,
    int? parityCount,
    String? deltaPayload,
    String? encryptedPreview,
    String? proofSummary,
    List<ClinicalField>? priorityFields,
    List<TransmissionSection>? sections,
    List<ValidationIssue>? validationIssues,
    String? emergencySnapshot,
    int? bandwidthBudget,
    int? currentUsage,
    bool? urgentCase,
    int? compressedByteCount,
    int? originalByteCount,
    bool? fallbackTriggered,
    int? fallbackTriggerAttempt,
    String? fallbackImageTier,
    int? remainingBudget,
    double? compressionRatio,
    int? packetLoss,
    int? latency,
    int? recoveryPercent,
    int? recoveryConfidencePercent,
    String? recoveryMessage,
    String? recoveryState,
    int? estimatedDeliveryTime,
    List<String>? missingChunkIds,
    List<String>? retransmittedChunkIds,
    String? activeStrategy,
    int? chunkSize,
    int? compressionLevel,
    int? redundancy,
    int? parityPackets,
    String? networkProfile,
  }) {
    return TransmissionState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      history: history ?? this.history,
      logs: logs ?? this.logs,
      receipts: receipts ?? this.receipts,
      queueItems: queueItems ?? this.queueItems,
      timeline: timeline ?? this.timeline,
      survivalPercent: survivalPercent ?? this.survivalPercent,
      resilienceScore: resilienceScore ?? this.resilienceScore,
      lostPieces: lostPieces ?? this.lostPieces,
      rebuilt: rebuilt ?? this.rebuilt,
      normalAppStatus: normalAppStatus ?? this.normalAppStatus,
      doctorPayload: doctorPayload ?? this.doctorPayload,
      changedFields: changedFields ?? this.changedFields,
      chunkCount: chunkCount ?? this.chunkCount,
      parityCount: parityCount ?? this.parityCount,
      deltaPayload: deltaPayload ?? this.deltaPayload,
      encryptedPreview: encryptedPreview ?? this.encryptedPreview,
      proofSummary: proofSummary ?? this.proofSummary,
      priorityFields: priorityFields ?? this.priorityFields,
      sections: sections ?? this.sections,
      validationIssues: validationIssues ?? this.validationIssues,
      emergencySnapshot: emergencySnapshot ?? this.emergencySnapshot,
      bandwidthBudget: bandwidthBudget ?? this.bandwidthBudget,
      currentUsage: currentUsage ?? this.currentUsage,
      urgentCase: urgentCase ?? this.urgentCase,
      compressedByteCount: compressedByteCount ?? this.compressedByteCount,
      originalByteCount: originalByteCount ?? this.originalByteCount,
      fallbackTriggered: fallbackTriggered ?? this.fallbackTriggered,
      fallbackTriggerAttempt: fallbackTriggerAttempt ?? this.fallbackTriggerAttempt,
      fallbackImageTier: fallbackImageTier ?? this.fallbackImageTier,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      packetLoss: packetLoss ?? this.packetLoss,
      latency: latency ?? this.latency,
      recoveryPercent: recoveryPercent ?? this.recoveryPercent,
      recoveryConfidencePercent: recoveryConfidencePercent ?? this.recoveryConfidencePercent,
      recoveryMessage: recoveryMessage ?? this.recoveryMessage,
      recoveryState: recoveryState ?? this.recoveryState,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      missingChunkIds: missingChunkIds ?? this.missingChunkIds,
      retransmittedChunkIds: retransmittedChunkIds ?? this.retransmittedChunkIds,
      activeStrategy: activeStrategy ?? this.activeStrategy,
      chunkSize: chunkSize ?? this.chunkSize,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      redundancy: redundancy ?? this.redundancy,
      parityPackets: parityPackets ?? this.parityPackets,
      networkProfile: networkProfile ?? this.networkProfile,
    );
  }
}

class TransmissionController extends Notifier<TransmissionState> {
  Map<String, String>? _lastSentRecord;
  int _queueCounter = 0;

  @override
  TransmissionState build() => const TransmissionState();

  Future<void> sendTransmission({
    String payload = 'Patient record',
    String networkMode = 'stable',
  }) async {
    for (var step = 10; step <= 100; step += 10) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state = state.copyWith(
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
    int sparePieces = 3,
  }) async {
    final initialNetwork = ref.read(networkSimulatorProvider);
    final initialResult = simulateSecureTransmission(
      patient: patient,
      previousRecord: _lastSentRecord,
      reliability: initialNetwork.reliability,
      sparePieces: sparePieces + initialNetwork.redundancy,
      chunkSize: initialNetwork.chunkSize,
    );
    if (!initialResult.delta.hasDelta) {
      state = state.copyWith(
        status: 'buffered',
        progress: 100,
        message: 'No new changes detected; buffer held',
        logs: ['Duplicate record skipped.', ...state.logs],
        proofSummary: 'No changed fields; duplicate buffered',
      );
      return;
    }

    final plan = buildClinicalTransmissionPlan(patient);
    final validationIssues = validateClinicalValues(patient);
    final emergencySnapshot = buildEmergencySnapshot(patient);
    final queueEntry = TransmissionQueueItem(
      id: 'queue-${_queueCounter++}',
      status: 'sending',
      summary: patient.urgent
          ? 'URGENT MedGate Protocol transmitting ${patient.displayName}'
          : 'MedGate Protocol transmitting ${patient.displayName}',
      packetCount: initialResult.chunksSent,
      retryCount: 0,
      createdAt: DateTime.now(),
      payload: patient.toPayload(),
      isUrgent: patient.urgent,
    );

    state = state.copyWith(
      status: 'transmitting',
      progress: 10,
      message: 'Preparing adaptive priority stream',
      priorityFields: plan.priorityFields,
      sections: plan.sections,
      validationIssues: validationIssues,
      emergencySnapshot: emergencySnapshot,
      queueItems: [queueEntry, ...state.queueItems],
      activeStrategy: initialNetwork.activeStrategy,
      chunkSize: initialNetwork.chunkSize,
      compressionLevel: initialNetwork.compressionLevel,
      redundancy: initialNetwork.redundancy,
      parityPackets: initialNetwork.parityPackets,
      networkProfile: initialNetwork.profileLabel,
      urgentCase: patient.urgent,
      compressedByteCount: initialResult.compressedByteCount,
      originalByteCount: initialResult.originalByteCount,
      fallbackTriggered: initialResult.fallbackTriggered,
      fallbackTriggerAttempt: initialResult.fallbackTriggerAttempt,
      fallbackImageTier: initialResult.fallbackImageTier,
    );

    late SecureTransmissionResult result;
    var reliability = initialNetwork.reliability;
    var latencyMs = initialNetwork.latencyMs;
    var packetLoss = 0;
    var recoveryPercent = 0;
    var recoveryConfidencePercent = 0;
    var recoveryMessage = 'Waiting for a recovery run';
    var recoveryState = 'idle';
    var deliveryTime = plan.estimatedDeliveryMs;
    var compressionRatio = 1.0 + (initialNetwork.compressionLevel / 10);
    final missingChunkIds = <String>[];
    final retransmittedChunkIds = <String>[];

    for (var step = 20; step <= 100; step += 20) {
      final liveNetwork = ref.read(networkSimulatorProvider);
      reliability = liveNetwork.reliability;
      latencyMs = liveNetwork.latencyMs;
      packetLoss = ((100 - reliability) ~/ 4).clamp(0, 60);
      recoveryPercent = ((reliability - packetLoss).clamp(0, 100));
      deliveryTime = (plan.estimatedDeliveryMs + latencyMs + packetLoss * 8).clamp(180, 1800);
      compressionRatio = (1.0 + (liveNetwork.compressionLevel / 10)).clamp(1.0, 2.6);
      result = simulateSecureTransmission(
        patient: patient,
        previousRecord: _lastSentRecord,
        reliability: reliability,
        sparePieces: sparePieces + liveNetwork.redundancy,
        chunkSize: liveNetwork.chunkSize,
        urgent: patient.urgent,
        retryAttempt: step ~/ 20,
      );
      final recoveryStrategy = liveNetwork.activeStrategy == 'RS'
          ? const ReedSolomonRecoveryStrategy()
          : const XorParityRecoveryStrategy();
      final recoveryResult = recoveryStrategy.evaluate(
        expectedChunks: result.chunkCount + result.parityCount,
        receivedChunks: result.chunksSent - result.lostPieces,
        recoveryChunks: result.parityCount,
        recoveredFields: result.delta.changedFields,
        checksumMatched: result.checksumMatch,
      );
      recoveryConfidencePercent = recoveryResult.confidencePercent;
      recoveryMessage = recoveryResult.message;
      recoveryState = recoveryResult.state.name;
      if (packetLoss > 0) {
        for (var index = 0; index < packetLoss; index++) {
          missingChunkIds.add('chunk-${index + 1}');
        }
      }
      if (step == 100 && !result.rebuilt) {
        retransmittedChunkIds.addAll(missingChunkIds.take(2));
      }
      await Future<void>.delayed(Duration(milliseconds: latencyMs ~/ 12));
      state = _stateFromResult(
        result,
        status: step < 100 ? 'transmitting' : result.rebuilt ? 'delivered' : 'partial',
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
        plan: plan,
        validationIssues: validationIssues,
        emergencySnapshot: emergencySnapshot,
        queueItems: [
          queueEntry.copyWith(
            status: step < 100 ? 'sending' : result.rebuilt ? 'delivered' : 'failed',
            isUrgent: patient.urgent,
          ),
          ...state.queueItems.where((item) => item.id != queueEntry.id),
        ],
        timeline: _timelineFromStep(step, result),
        bandwidthBudget: initialNetwork.bandwidthKbps,
        currentUsage: ((step / 100) * initialNetwork.bandwidthKbps).round(),
        remainingBudget: (initialNetwork.bandwidthKbps - ((step / 100) * initialNetwork.bandwidthKbps)).round(),
        compressionRatio: compressionRatio,
        packetLoss: packetLoss,
        latency: latencyMs,
        recoveryPercent: recoveryPercent,
        recoveryConfidencePercent: recoveryConfidencePercent,
        recoveryMessage: recoveryMessage,
        recoveryState: recoveryState,
        estimatedDeliveryTime: deliveryTime,
        missingChunkIds: missingChunkIds.toSet().toList(),
        retransmittedChunkIds: retransmittedChunkIds.toSet().toList(),
        activeStrategy: liveNetwork.activeStrategy,
        chunkSize: liveNetwork.chunkSize,
        compressionLevel: liveNetwork.compressionLevel,
        redundancy: liveNetwork.redundancy,
        parityPackets: liveNetwork.parityPackets,
        networkProfile: liveNetwork.profileLabel,
        urgentCase: patient.urgent,
        compressedByteCount: result.compressedByteCount,
        originalByteCount: result.originalByteCount,
        fallbackTriggered: result.fallbackTriggered,
        fallbackTriggerAttempt: result.fallbackTriggerAttempt,
        fallbackImageTier: result.fallbackImageTier,
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
        if (patient.urgent)
          'URGENT — expedited fallback triggered'.toUpperCase(),
        '${result.lostPieces} chunks dropped; ${result.chunksUsed} rebuilt.',
        'Checksum ${result.checksumMatch ? 'matched' : 'mismatched'}: '
            '${result.sourceChecksum}.',
        'Compare: MedGate ${receipt.medGateStatus}; naive ${receipt.naiveStatus}.',
        'Delta fields: ${result.delta.changedFields.join(', ')}.',
        ...state.logs,
      ],
      receipts: [receipt, ...state.receipts],
      doctorPayload: result.rebuilt ? patient.toPayload() : state.doctorPayload,
      plan: plan,
      validationIssues: validationIssues,
      emergencySnapshot: emergencySnapshot,
      queueItems: [
        queueEntry.copyWith(
          status: result.rebuilt ? 'delivered' : 'failed',
          summary: result.rebuilt ? 'Delivered' : 'Queued for retry',
          isUrgent: patient.urgent,
        ),
        ...state.queueItems.where((item) => item.id != queueEntry.id),
      ],
      timeline: [
        ...state.timeline,
        TransmissionTimelineEvent(
          label: result.rebuilt ? 'Doctor viewed' : 'Retry queued',
          status: result.rebuilt ? 'verified' : 'pending',
          timestamp: DateTime.now(),
        ),
      ],
      bandwidthBudget: initialNetwork.bandwidthKbps,
      currentUsage: initialNetwork.bandwidthKbps,
      remainingBudget: 0,
      compressionRatio: compressionRatio,
      packetLoss: packetLoss,
      latency: latencyMs,
      recoveryPercent: recoveryPercent,
      recoveryConfidencePercent: recoveryConfidencePercent,
      recoveryMessage: recoveryMessage,
      recoveryState: recoveryState,
      estimatedDeliveryTime: deliveryTime,
      missingChunkIds: missingChunkIds.toSet().toList(),
      retransmittedChunkIds: retransmittedChunkIds.toSet().toList(),
      activeStrategy: initialNetwork.activeStrategy,
      chunkSize: initialNetwork.chunkSize,
      compressionLevel: initialNetwork.compressionLevel,
      redundancy: initialNetwork.redundancy,
      parityPackets: initialNetwork.parityPackets,
      networkProfile: initialNetwork.profileLabel,
      urgentCase: patient.urgent,
      compressedByteCount: result.compressedByteCount,
      originalByteCount: result.originalByteCount,
      fallbackTriggered: result.fallbackTriggered,
      fallbackTriggerAttempt: result.fallbackTriggerAttempt,
      fallbackImageTier: result.fallbackImageTier,
    );
  }

  Future<void> retryQueueItem({
    required String id,
    required PatientModel patient,
  }) async {
    final network = ref.read(networkSimulatorProvider);
    final itemIndex = state.queueItems.indexWhere((item) => item.id == id);
    if (itemIndex < 0) {
      return;
    }

    final updatedItems = [...state.queueItems];
    updatedItems[itemIndex] = TransmissionQueueItem(
      id: id,
      status: network.reliability >= 80 && network.latencyMs <= 300 ? 'sending' : 'retrying',
      summary: 'Retry queued',
      packetCount: updatedItems[itemIndex].packetCount,
      retryCount: updatedItems[itemIndex].retryCount + 1,
      createdAt: updatedItems[itemIndex].createdAt,
      payload: updatedItems[itemIndex].payload,
    );
    state = state.copyWith(queueItems: updatedItems);

    if (network.reliability >= 80 && network.latencyMs <= 300) {
      await sendPatientRecord(patient: patient);
    }
  }

  void deleteQueueItem(String id) {
    state = state.copyWith(
      queueItems: state.queueItems.where((item) => item.id != id).toList(),
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
    required ClinicalTransmissionPlan plan,
    required List<ValidationIssue> validationIssues,
    required String emergencySnapshot,
    required List<TransmissionQueueItem> queueItems,
    required List<TransmissionTimelineEvent> timeline,
    required int bandwidthBudget,
    required int currentUsage,
    required int remainingBudget,
    required double compressionRatio,
    required int packetLoss,
    required int latency,
    required int recoveryPercent,
    required int recoveryConfidencePercent,
    required String recoveryMessage,
    required String recoveryState,
    required int estimatedDeliveryTime,
    required List<String> missingChunkIds,
    required List<String> retransmittedChunkIds,
    required String activeStrategy,
    required int chunkSize,
    required int compressionLevel,
    required int redundancy,
    required int parityPackets,
    required String networkProfile,
    required bool urgentCase,
    required int compressedByteCount,
    required int originalByteCount,
    required bool fallbackTriggered,
    required int fallbackTriggerAttempt,
    required String fallbackImageTier,
  }) {
    return TransmissionState(
      status: status,
      progress: progress,
      message: message,
      history: history,
      logs: logs,
      receipts: receipts,
      queueItems: queueItems,
      timeline: timeline,
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
      priorityFields: plan.priorityFields,
      sections: plan.sections,
      validationIssues: validationIssues,
      emergencySnapshot: emergencySnapshot,
      bandwidthBudget: bandwidthBudget,
      currentUsage: currentUsage,
      remainingBudget: remainingBudget,
      compressionRatio: compressionRatio,
      packetLoss: packetLoss,
      latency: latency,
      recoveryPercent: recoveryPercent,
      recoveryConfidencePercent: recoveryConfidencePercent,
      recoveryMessage: recoveryMessage,
      recoveryState: recoveryState,
      estimatedDeliveryTime: estimatedDeliveryTime,
      missingChunkIds: missingChunkIds,
      retransmittedChunkIds: retransmittedChunkIds,
      activeStrategy: activeStrategy,
      chunkSize: chunkSize,
      compressionLevel: compressionLevel,
      redundancy: redundancy,
      parityPackets: parityPackets,
      networkProfile: networkProfile,
      urgentCase: urgentCase,
      compressedByteCount: compressedByteCount,
      originalByteCount: originalByteCount,
      fallbackTriggered: fallbackTriggered,
      fallbackTriggerAttempt: fallbackTriggerAttempt,
      fallbackImageTier: fallbackImageTier,
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

  List<TransmissionTimelineEvent> _timelineFromStep(int step, SecureTransmissionResult result) {
    final labels = <String>['Patient registered', 'NFC captured', 'Validated', 'Encrypted', 'Compressed', 'Chunked', 'Sent', 'Recovered', 'Verified'];
    final status = step < 40 ? 'pending' : step < 80 ? 'active' : result.rebuilt ? 'verified' : 'recovered';
    return [
      ...state.timeline,
      TransmissionTimelineEvent(
        label: labels[step ~/ 20],
        status: status,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final transmissionProvider =
    NotifierProvider<TransmissionController, TransmissionState>(
      TransmissionController.new,
    );
