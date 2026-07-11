import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/glass_container.dart';
import '../../network_simulator/providers/network_simulator_provider.dart';
import '../../nfc_capture/providers/nfc_provider.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../../triage/logic/triage_assessment.dart';

class SpecialistPage extends ConsumerWidget {
  const SpecialistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(nfcProvider);
    final networkState = ref.watch(networkSimulatorProvider);
    final transmission = ref.watch(transmissionProvider);
    final assessment = evaluateTriage(
      payload: captureState.payload,
      reliability: networkState.reliability,
      latencyMs: networkState.latencyMs,
    );

    return Scaffold(
      body: AnimatedPageWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Doctor Console',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Received patient data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Received: ${transmission.doctorPayload}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: 'Integrity',
                            value: transmission.rebuilt ? 'Rebuilt' : 'Pending',
                          ),
                          _InfoChip(label: 'Network', value: networkState.mode),
                          _InfoChip(
                            label: 'Survival',
                            value: '${transmission.survivalPercent}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Changed fields: ${transmission.changedFields.join(', ')}',
                      ),
                      const SizedBox(height: 8),
                      Text('Receipt proof: ${transmission.proofSummary}'),
                      const SizedBox(height: 8),
                      Text(
                        'Delta payload: ${transmission.deltaPayload.isEmpty ? '—' : transmission.deltaPayload}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reconstructed record: ${transmission.doctorPayload}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Triage severity: ${assessment.severity.toUpperCase()}',
                      ),
                      const SizedBox(height: 8),
                      Text('Triage score: ${assessment.score}/100'),
                      const SizedBox(height: 8),
                      Text('Recommendation: ${assessment.recommendation}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Back to dashboard'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/network-simulator'),
                            child: const Text('Review network'),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

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
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
