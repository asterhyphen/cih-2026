import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/glass_container.dart';
import '../../network_simulator/providers/network_simulator_provider.dart';
import '../../nfc_capture/providers/nfc_provider.dart';
import '../../transmission_engine/logic/protocol_engine.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../../triage/logic/triage_assessment.dart';

class SpecialistPage extends ConsumerWidget {
  const SpecialistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(nfcProvider);
    final networkState = ref.watch(networkSimulatorProvider);
    final transmission = ref.watch(transmissionProvider);
    final receipt = transmission.receipts.isEmpty
        ? null
        : transmission.receipts.first;
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
                      const SizedBox(height: 12),
                      _IntegrityBanner(
                        receipt: receipt,
                        rebuilt: transmission.rebuilt,
                        urgent: transmission.urgentCase,
                      ),
                      const SizedBox(height: 12),
                      if (transmission.priorityFields.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: transmission.priorityFields.take(8).map((
                            field,
                          ) {
                            final color =
                                field.priority == ClinicalPriority.critical
                                ? Theme.of(context).colorScheme.error
                                : field.priority == ClinicalPriority.high
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary;
                            return Chip(
                              avatar: Icon(
                                Icons.local_hospital_rounded,
                                color: color,
                                size: 18,
                              ),
                              label: Text(
                                '${field.label} · ${field.priority.name}',
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text('Received: ${transmission.doctorPayload}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: captureState.captureSource == 'nfc'
                                ? Icons.nfc_rounded
                                : Icons.edit_note_rounded,
                            label: 'Source',
                            value: captureState.captureSource == 'nfc'
                                ? 'NFC'
                                : 'Manual',
                          ),
                          _InfoChip(
                            icon: Icons.network_check_rounded,
                            label: 'Network',
                            value: networkState.mode,
                          ),
                          _InfoChip(
                            icon: Icons.health_and_safety_rounded,
                            label: 'Survival',
                            value: '${transmission.survivalPercent}%',
                          ),
                          _InfoChip(
                            icon: transmission.urgentCase
                                ? Icons.emergency_rounded
                                : Icons.assignment_turned_in_rounded,
                            label: 'Urgency',
                            value: transmission.urgentCase
                                ? 'Urgent'
                                : 'Routine',
                          ),
                          _InfoChip(
                            icon: Icons.replay_circle_filled_rounded,
                            label: 'Recovery',
                            value: '${transmission.recoveryConfidencePercent}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ChangedFields(fields: transmission.changedFields),
                      const SizedBox(height: 12),
                      Text(
                        'Triage severity: ${assessment.severity.toUpperCase()}',
                      ),
                      const SizedBox(height: 8),
                      Text('Triage score: ${assessment.score}/100'),
                      const SizedBox(height: 8),
                      Text('Recommendation: ${assessment.recommendation}'),
                      const SizedBox(height: 16),
                      Text(
                        'Progressive sections',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: transmission.sections.map((section) {
                          final title = section.name.replaceAll('_', ' ');
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(title.toUpperCase()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Queue status',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      ...transmission.queueItems
                          .take(3)
                          .map(
                            (item) => Text(
                              '• ${item.status.toUpperCase()}: ${item.summary}',
                            ),
                          ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Back to dashboard'),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/network-simulator'),
                            child: const Text('Review network'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) => _ProtocolOverviewDialog(
                                transmission: transmission,
                              ),
                            ),
                            child: const Text('Protocol overview'),
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

class _ProtocolOverviewDialog extends StatelessWidget {
  const _ProtocolOverviewDialog({required this.transmission});

  final TransmissionState transmission;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Protocol overview'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${transmission.status}'),
          Text(
            'Chunks: ${transmission.chunkCount} data + ${transmission.parityCount} parity',
          ),
          Text(
            'Changed fields: ${transmission.changedFields.isEmpty ? 'None' : transmission.changedFields.join(', ')}',
          ),
          Text(
            'Recovery: ${transmission.recoveryConfidencePercent}% confidence',
          ),
          Text('Proof: ${transmission.proofSummary}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _IntegrityBanner extends StatelessWidget {
  const _IntegrityBanner({
    required this.receipt,
    required this.rebuilt,
    required this.urgent,
  });

  final TransmissionReceipt? receipt;
  final bool rebuilt;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final matched = receipt?.checksumMatch ?? false;
    final color = urgent
        ? Theme.of(context).colorScheme.error
        : matched
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            urgent
                ? Icons.emergency_rounded
                : matched
                ? Icons.verified_rounded
                : Icons.pending_actions_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              urgent
                  ? 'URGENT — expedited fallback active'
                  : matched
                  ? 'Checksum match confirmed'
                  : rebuilt
                  ? 'Awaiting checksum receipt'
                  : 'No verified rebuild yet',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangedFields extends StatelessWidget {
  const _ChangedFields({required this.fields});

  final List<String> fields;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const _EmptyLine(
        icon: Icons.difference_outlined,
        text: 'No delta received yet',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fields
          .map(
            (field) => Chip(
              avatar: const Icon(Icons.change_circle_outlined, size: 18),
              label: Text(field),
            ),
          )
          .toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
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
