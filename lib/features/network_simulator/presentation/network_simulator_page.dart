import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/floating_nav_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../providers/network_simulator_provider.dart';

class NetworkSimulatorPage extends ConsumerWidget {
  const NetworkSimulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkSimulatorProvider);
    final transmission = ref.watch(transmissionProvider);

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
                        'Transmission preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Mode: ${state.mode}'),
                      const SizedBox(height: 8),
                      Text('Reliability: ${state.reliability}%'),
                      Slider(
                        value: state.reliability.toDouble(),
                        min: 35,
                        max: 100,
                        divisions: 13,
                        label: '${state.reliability}%',
                        onChanged: (value) => ref
                            .read(networkSimulatorProvider.notifier)
                            .setReliability(value),
                      ),
                      const SizedBox(height: 8),
                      Text('Latency: ${state.latencyMs}ms'),
                      Slider(
                        value: state.latencyMs.toDouble(),
                        min: 60,
                        max: 650,
                        divisions: 59,
                        label: '${state.latencyMs}ms',
                        onChanged: (value) => ref
                            .read(networkSimulatorProvider.notifier)
                            .setLatency(value),
                      ),
                      const SizedBox(height: 8),
                      Text('Delivery impact: ${state.deliveryImpact}'),
                      const SizedBox(height: 8),
                      Text('Signal quality: ${state.qualityLabel}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => ref
                                .read(networkSimulatorProvider.notifier)
                                .setMode('stable'),
                            child: const Text('Stable'),
                          ),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(networkSimulatorProvider.notifier)
                                .setMode('degraded'),
                            child: const Text('Degraded'),
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
                      const SizedBox(height: 8),
                      Text(
                        'Our method: ${transmission.survivalPercent}% rebuilt',
                      ),
                      const SizedBox(height: 8),
                      Text('Normal app: ${transmission.normalAppStatus}'),
                      const SizedBox(height: 8),
                      Text(
                        'Lost pieces: ${transmission.lostPieces} / '
                        '${transmission.chunkCount + transmission.parityCount}',
                      ),
                      const SizedBox(height: 12),
                      ...transmission.logs
                          .take(5)
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $log'),
                            ),
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
