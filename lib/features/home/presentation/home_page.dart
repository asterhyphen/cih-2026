import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/floating_nav_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../../network_simulator/providers/network_simulator_provider.dart';
import '../../nfc_capture/providers/nfc_provider.dart';
import '../../transmission_engine/logic/adaptive_transmission.dart';
import '../../transmission_engine/logic/chunking.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../../triage/logic/triage_assessment.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(nfcProvider);
    final transmissionState = ref.watch(transmissionProvider);
    final networkState = ref.watch(networkSimulatorProvider);
    final patient = captureState.patient;
    final chunks = chunkText(captureState.payload, 8);
    final assessment = evaluateTriage(
      payload: captureState.payload,
      reliability: networkState.reliability,
      latencyMs: networkState.latencyMs,
    );
    final adaptiveResult = simulateAdaptiveTransmission(
      captureState.payload,
      lossCount: 1,
      parityPieces: 2,
    );

    return Scaffold(
      body: AnimatedPageWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Care dashboard', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Track intake progress, transmission health, and specialist readiness in one place.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Patient overview',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              patient == null ? 'No patient' : 'Ready',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Captured payload: ${captureState.payload}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SummaryChip(label: 'Chunks', value: '${chunks.length}'),
                          _SummaryChip(label: 'Triage', value: assessment.severity.toUpperCase()),
                          _SummaryChip(label: 'Signal', value: networkState.qualityLabel),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Transmission: ${transmissionState.status}', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text('Triage score: ${assessment.score}/100 • ${assessment.recommendation}'),
                      const SizedBox(height: 8),
                      Text('Adaptive rebuild: ${adaptiveResult.summary} (${adaptiveResult.survivalPercent}%)'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: transmissionState.progress / 100),
                      const SizedBox(height: 8),
                      Text(transmissionState.message),
                      const SizedBox(height: 12),
                      if (transmissionState.history.isNotEmpty) ...[
                        Text('Recent activity', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        ...transmissionState.history.take(3).map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${entry.status} · ${entry.payload} · ${entry.networkMode}'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          FilledButton(
                            onPressed: patient == null || !patient.isValidForSend
                                ? null
                                : () => ref.read(transmissionProvider.notifier).sendPatientRecord(
                                      patient: patient,
                                      reliability: networkState.reliability,
                                      latencyMs: networkState.latencyMs,
                                    ),
                            child: const Text('Send'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => context.go('/specialist'),
                            child: const Text('Open specialist view'),
                          ),
                        ],
                      ),
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value', style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
