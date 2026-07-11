import 'dart:math' as math;

class RecoveryResult {
  const RecoveryResult({
    required this.state,
    required this.confidencePercent,
    required this.expectedChunks,
    required this.receivedChunks,
    required this.usedForRecovery,
    required this.recoveredFields,
    required this.message,
  });

  final RecoveryState state;
  final int confidencePercent;
  final int expectedChunks;
  final int receivedChunks;
  final int usedForRecovery;
  final List<String> recoveredFields;
  final String message;
}

enum RecoveryState { fullRecovery, recovered, degraded, failed }

abstract class RecoveryStrategy {
  const RecoveryStrategy();

  RecoveryResult evaluate({
    required int expectedChunks,
    required int receivedChunks,
    required int recoveryChunks,
    required List<String> recoveredFields,
    required bool checksumMatched,
  });
}

class XorParityRecoveryStrategy extends RecoveryStrategy {
  const XorParityRecoveryStrategy();

  @override
  RecoveryResult evaluate({
    required int expectedChunks,
    required int receivedChunks,
    required int recoveryChunks,
    required List<String> recoveredFields,
    required bool checksumMatched,
  }) {
    final missingChunks = expectedChunks - receivedChunks;
    final canRecover = missingChunks <= recoveryChunks && missingChunks > 0;
    final state = checksumMatched
        ? RecoveryState.fullRecovery
        : missingChunks == 0
            ? RecoveryState.fullRecovery
            : canRecover
                ? RecoveryState.recovered
                : missingChunks > recoveryChunks
                    ? RecoveryState.degraded
                    : RecoveryState.failed;
    final confidence = switch (state) {
      RecoveryState.fullRecovery => 100,
      RecoveryState.recovered => 86,
      RecoveryState.degraded => 45,
      RecoveryState.failed => 0,
    };
    return RecoveryResult(
      state: state,
      confidencePercent: confidence,
      expectedChunks: expectedChunks,
      receivedChunks: receivedChunks,
      usedForRecovery: canRecover ? missingChunks : 0,
      recoveredFields: recoveredFields,
      message: switch (state) {
        RecoveryState.fullRecovery => 'Full recovery',
        RecoveryState.recovered => 'Recovered with parity correction',
        RecoveryState.degraded => 'Partial recovery; loss exceeded parity capacity',
        RecoveryState.failed => 'Failed to recover record',
      },
    );
  }
}

class ReedSolomonRecoveryStrategy extends RecoveryStrategy {
  const ReedSolomonRecoveryStrategy();

  @override
  RecoveryResult evaluate({
    required int expectedChunks,
    required int receivedChunks,
    required int recoveryChunks,
    required List<String> recoveredFields,
    required bool checksumMatched,
  }) {
    final missingChunks = expectedChunks - receivedChunks;
    final canRecover = missingChunks <= recoveryChunks;
    final state = checksumMatched
        ? RecoveryState.fullRecovery
        : missingChunks == 0
            ? RecoveryState.fullRecovery
            : canRecover
                ? RecoveryState.recovered
                : missingChunks > recoveryChunks
                    ? RecoveryState.degraded
                    : RecoveryState.failed;
    final confidence = switch (state) {
      RecoveryState.fullRecovery => 100,
      RecoveryState.recovered => 94 + math.min(3, recoveryChunks),
      RecoveryState.degraded => 35,
      RecoveryState.failed => 0,
    };
    return RecoveryResult(
      state: state,
      confidencePercent: confidence.clamp(0, 100).toInt(),
      expectedChunks: expectedChunks,
      receivedChunks: receivedChunks,
      usedForRecovery: canRecover ? missingChunks : 0,
      recoveredFields: recoveredFields,
      message: switch (state) {
        RecoveryState.fullRecovery => 'Full recovery',
        RecoveryState.recovered => 'Recovered using Reed-Solomon correction',
        RecoveryState.degraded => 'Partial recovery; loss exceeded correction capacity',
        RecoveryState.failed => 'Failed to recover record',
      },
    );
  }
}
