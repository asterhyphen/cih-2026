import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkState {
  const NetworkState({
    this.mode = 'stable',
    this.latencyMs = 80,
    this.reliability = 98,
    this.deliveryImpact = 'Low risk',
    this.qualityLabel = 'Excellent',
    this.compareMode = true,
  });

  final String mode;
  final int latencyMs;
  final int reliability;
  final String deliveryImpact;
  final String qualityLabel;
  final bool compareMode;
}

class NetworkSimulatorController extends Notifier<NetworkState> {
  @override
  NetworkState build() => const NetworkState();

  void setReliability(double value) {
    final reliability = value.round();
    state = _fromValues(state.latencyMs, reliability);
  }

  void setLatency(double value) {
    final latency = value.round();
    state = _fromValues(latency, state.reliability);
  }

  void setCompareMode(bool value) {
    state = NetworkState(
      mode: state.mode,
      latencyMs: state.latencyMs,
      reliability: state.reliability,
      deliveryImpact: state.deliveryImpact,
      qualityLabel: state.qualityLabel,
      compareMode: value,
    );
  }

  void setMode(String mode) {
    if (mode == 'degraded') {
      state = NetworkState(
        mode: 'degraded',
        latencyMs: 320,
        reliability: 64,
        deliveryImpact: 'High risk',
        qualityLabel: 'Poor',
        compareMode: state.compareMode,
      );
    } else {
      state = NetworkState(
        mode: 'stable',
        latencyMs: 80,
        reliability: 98,
        deliveryImpact: 'Low risk',
        qualityLabel: 'Excellent',
        compareMode: state.compareMode,
      );
    }
  }

  NetworkState _fromValues(int latencyMs, int reliability) {
    final mode = reliability < 78 || latencyMs > 250 ? 'degraded' : 'stable';
    final risk = reliability < 65 || latencyMs > 420
        ? 'Critical risk'
        : mode == 'degraded'
        ? 'High risk'
        : 'Low risk';
    final quality = reliability < 65
        ? 'Failing'
        : reliability < 85
        ? 'Poor'
        : 'Excellent';
    return NetworkState(
      mode: mode,
      latencyMs: latencyMs,
      reliability: reliability,
      deliveryImpact: risk,
      qualityLabel: quality,
      compareMode: state.compareMode,
    );
  }
}

final networkSimulatorProvider =
    NotifierProvider<NetworkSimulatorController, NetworkState>(
      NetworkSimulatorController.new,
    );
