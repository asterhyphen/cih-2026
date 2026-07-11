import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/floating_nav_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../../nfc_capture/providers/nfc_provider.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../providers/network_simulator_provider.dart';

class NetworkSimulatorPage extends ConsumerWidget {
  const NetworkSimulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkSimulatorProvider);
    final captureState = ref.watch(nfcProvider);
    final transmission = ref.watch(transmissionProvider);
    final patient = captureState.patient;

    Future<void> runTransmission() async {
      if (patient == null || !patient.isValidForSend) {
        return;
      }
      await ref
          .read(transmissionProvider.notifier)
          .sendPatientRecord(patient: patient, sparePieces: 2);
    }

    return Scaffold(
      body: AnimatedPageWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Simulator',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transport',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Reliability: ${state.reliability}%'),
                      Slider(
                        value: state.reliability.toDouble(),
                        min: 35,
                        max: 100,
                        divisions: 13,
                        label: '${state.reliability}%',
                        onChanged: (value) {
                          ref
                              .read(networkSimulatorProvider.notifier)
                              .setReliability(value);
                          runTransmission();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Latency: ${state.latencyMs}ms'),
                      Slider(
                        value: state.latencyMs.toDouble(),
                        min: 60,
                        max: 650,
                        divisions: 59,
                        label: '${state.latencyMs}ms',
                        onChanged: (value) {
                          ref
                              .read(networkSimulatorProvider.notifier)
                              .setLatency(value);
                          runTransmission();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Redundancy: ${state.redundancy} parity pieces'),
                      Slider(
                        value: state.redundancy.toDouble(),
                        min: 0,
                        max: 6,
                        divisions: 6,
                        label: '${state.redundancy}',
                        onChanged: (value) {
                          ref
                              .read(networkSimulatorProvider.notifier)
                              .setRedundancy(value);
                          runTransmission();
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(label: 'Mode', value: state.mode),
                          _InfoPill(label: 'Risk', value: state.deliveryImpact),
                          _InfoPill(label: 'Signal', value: state.qualityLabel),
                          _InfoPill(
                            label: 'Strategy',
                            value: state.activeStrategy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProfileChip(label: 'Ultra Low', value: 'Ultra Low'),
                          _ProfileChip(label: 'Low', value: 'Low'),
                          _ProfileChip(label: 'Medium', value: 'Medium'),
                          _ProfileChip(label: 'High', value: 'High'),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: state.compareMode,
                        onChanged: (value) => ref
                            .read(networkSimulatorProvider.notifier)
                            .setCompareMode(value),
                        title: const Text('Compare mode'),
                        secondary: const Icon(Icons.compare_arrows_rounded),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(networkSimulatorProvider.notifier)
                                  .setMode('stable');
                              runTransmission();
                            },
                            child: const Text('Stable'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(networkSimulatorProvider.notifier)
                                  .setMode('degraded');
                              runTransmission();
                            },
                            child: const Text('Degraded'),
                          ),
                          FilledButton.tonal(
                            onPressed: runTransmission,
                            child: const Text('Run'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live proof',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _ResilienceGauge(score: transmission.resilienceScore),
                      const SizedBox(height: 12),
                      if (state.compareMode)
                        _CompareStrip(
                          medGate: '${transmission.survivalPercent}% rebuilt',
                          naive: transmission.normalAppStatus,
                          medGateOk: transmission.rebuilt,
                          naiveOk: transmission.normalAppStatus == 'Delivered',
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Bandwidth Budget: ${transmission.bandwidthBudget} kbps',
                      ),
                      Text('Current Usage: ${transmission.currentUsage} kbps'),
                      Text(
                        'Remaining Budget: ${transmission.remainingBudget} kbps',
                      ),
                      Text(
                        'Compression Ratio: ${transmission.compressionRatio.toStringAsFixed(2)}x',
                      ),
                      Text('Packet Loss: ${transmission.packetLoss}%'),
                      Text('Latency: ${transmission.latency} ms'),
                      Text('Recovery %: ${transmission.recoveryPercent}%'),
                      Text(
                        'Estimated Delivery Time: ${transmission.estimatedDeliveryTime} ms',
                      ),
                      const SizedBox(height: 12),
                      Text(transmission.proofSummary),
                      const SizedBox(height: 12),
                      Text(
                        'Integrity log',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (transmission.receipts.isEmpty)
                        const _EmptyLine(
                          icon: Icons.receipt_long_outlined,
                          text: 'No transmissions yet',
                        )
                      else
                        ...transmission.receipts.take(5).map(_ReceiptRow.new),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const FloatingNavBar(),
    );
  }
}

class _ResilienceGauge extends StatelessWidget {
  const _ResilienceGauge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final danger = score < 70;
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: danger ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, _) => SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resilience Score',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, _) => Text(
                    '${value.round()}%',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareStrip extends StatelessWidget {
  const _CompareStrip({
    required this.medGate,
    required this.naive,
    required this.medGateOk,
    required this.naiveOk,
  });

  final String medGate;
  final String naive;
  final bool medGateOk;
  final bool naiveOk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompareTile(label: 'MedGate', value: medGate, ok: medGateOk),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompareTile(label: 'Naive', value: naive, ok: naiveOk),
        ),
      ],
    );
  }
}

class _CompareTile extends StatelessWidget {
  const _CompareTile({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.receipt);

  final TransmissionReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final color = receipt.checksumMatch
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            receipt.checksumMatch
                ? Icons.verified_rounded
                : Icons.warning_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${receipt.chunksSent} sent, ${receipt.chunksDropped} dropped, '
              '${receipt.chunksUsed} rebuilt. Hash '
              '${receipt.checksumMatch ? 'matched' : 'mismatched'}.',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.network_check_rounded, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class _ProfileChip extends ConsumerWidget {
  const _ProfileChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(networkSimulatorProvider).profileLabel == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        ref.read(networkSimulatorProvider.notifier).setProfile(value);
      },
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text)],
    );
  }
}
