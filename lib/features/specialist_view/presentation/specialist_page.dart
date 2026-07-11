import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/glass_container.dart';
import '../../data/patient_model.dart';
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
    final rebuiltPatient = _tryDecodePatient(transmission.doctorPayload);
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
                      onPressed: () => context.go(AppRoutes.home),
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
                      _DoctorPatientSummary(
                        patient: rebuiltPatient,
                        payload: transmission.doctorPayload,
                      ),
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
                      _PayloadEvidence(transmission: transmission),
                      const SizedBox(height: 12),
                      _DeliveredPayloadList(
                        records: transmission.doctorPayloads,
                      ),
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
                      _PacketQueueList(items: transmission.queueItems),
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
                            onPressed: () => context.go(AppRoutes.home),
                            child: const Text('Back to dashboard'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                context.go(AppRoutes.networkSimulator),
                            child: const Text('Review network'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) => _PacketQueueDialog(
                                items: transmission.queueItems,
                              ),
                            ),
                            child: const Text('Packet queue'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) => _AllPayloadsDialog(
                                records: transmission.doctorPayloads,
                              ),
                            ),
                            child: const Text('All payloads'),
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

PatientModel? _tryDecodePatient(String payload) {
  try {
    return PatientModel.fromPayload(payload);
  } catch (_) {
    return null;
  }
}

class _DoctorPatientSummary extends StatelessWidget {
  const _DoctorPatientSummary({required this.patient, required this.payload});

  final PatientModel? patient;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final patient = this.patient;
    if (patient == null) {
      return Text('Received: $payload');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DoctorImagePreview(reference: patient.photoRef),
        const SizedBox(height: 12),
        _PatientFieldGrid(patient: patient),
      ],
    );
  }
}

class _DoctorImagePreview extends StatelessWidget {
  const _DoctorImagePreview({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final trimmed = reference.trim();
    final isPlaceholder = trimmed.startsWith('placeholder://');
    final imageFile = trimmed.isNotEmpty && !isPlaceholder
        ? File(trimmed)
        : null;
    final hasFile = imageFile != null && imageFile.existsSync();
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasFile
            ? Image.file(imageFile, fit: BoxFit.cover)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaceholder
                          ? Icons.image_search_rounded
                          : Icons.image_not_supported_outlined,
                      size: 44,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trimmed.isEmpty ? 'No image received' : trimmed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PatientFieldGrid extends StatelessWidget {
  const _PatientFieldGrid({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{
      'Patient ID': patient.id,
      'Name': patient.displayName,
      'Age': patient.age == 0 ? '' : '${patient.age}',
      'Gender': patient.gender,
      'Blood group': patient.bloodGroup,
      'Blood pressure': patient.bloodPressure,
      'Heart rate': '${patient.heartRate}',
      'Oxygen saturation': '${patient.oxygenSaturation}',
      'Temperature': patient.temperature.toStringAsFixed(1),
      'Symptoms': patient.symptoms,
      'Diagnosis': patient.diagnosis,
      'Medical history': patient.medicalHistory,
      'Current medication': patient.currentMedication,
      'Allergies': patient.allergies,
      'Consciousness': patient.consciousness,
      'Emergency notes': patient.emergencyNotes,
      'Address': patient.address,
      'Contact details': patient.contactDetails,
      'Insurance': patient.insurance,
      'Clinical notes': patient.notes,
      'Photo payload ref': patient.photoRef,
      'Urgent': patient.urgent ? 'Yes' : 'No',
    };
    return Column(
      children: fields.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(entry.value.trim().isEmpty ? '-' : entry.value),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PayloadEvidence extends StatelessWidget {
  const _PayloadEvidence({required this.transmission});

  final TransmissionState transmission;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payload evidence', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Chunks: ${transmission.chunkCount} data + ${transmission.parityCount} parity',
        ),
        const SizedBox(height: 6),
        Text(
          'Compression: ${transmission.originalByteCount} B to ${transmission.compressedByteCount} B',
        ),
        const SizedBox(height: 6),
        SelectableText('MGP1: ${transmission.doctorPayload}'),
      ],
    );
  }
}

class _DeliveredPayloadList extends StatelessWidget {
  const _DeliveredPayloadList({required this.records});

  final List<DoctorPayloadRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyLine(
        icon: Icons.inbox_outlined,
        text: 'No specialist payloads received yet',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Received payloads',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...records.take(4).map((record) {
          final patient = _tryDecodePatient(record.payload);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                record.urgent
                    ? Icons.emergency_rounded
                    : Icons.assignment_turned_in_rounded,
              ),
              title: Text(patient?.displayName ?? record.summary),
              subtitle: Text(
                '${record.rebuilt ? 'Rebuilt' : 'Partial'} · ${record.payload}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AllPayloadsDialog extends StatelessWidget {
  const _AllPayloadsDialog({required this.records});

  final List<DoctorPayloadRecord> records;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All payloads'),
      content: SizedBox(
        width: 560,
        child: records.isEmpty
            ? const Text('No specialist payloads received yet')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: records.map((record) {
                    final patient = _tryDecodePatient(record.payload);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient?.displayName ?? record.summary,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${record.rebuilt ? 'Rebuilt' : 'Partial'} · '
                            '${record.urgent ? 'Urgent' : 'Routine'}',
                          ),
                          const SizedBox(height: 4),
                          SelectableText(record.payload),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
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

class _PacketQueueList extends StatelessWidget {
  const _PacketQueueList({required this.items});

  final List<TransmissionQueueItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyLine(
        icon: Icons.playlist_add_check_rounded,
        text: 'No packets queued',
      );
    }
    return Column(
      children: items
          .take(5)
          .map((item) => _PacketQueueTile(item: item))
          .toList(),
    );
  }
}

class _PacketQueueDialog extends StatelessWidget {
  const _PacketQueueDialog({required this.items});

  final List<TransmissionQueueItem> items;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Packet queue'),
      content: SizedBox(
        width: 560,
        child: items.isEmpty
            ? const Text('No packets queued')
            : SingleChildScrollView(
                child: Column(
                  children: items
                      .map((item) => _PacketQueueTile(item: item))
                      .toList(),
                ),
              ),
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

class _PacketQueueTile extends StatelessWidget {
  const _PacketQueueTile({required this.item});

  final TransmissionQueueItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paused = item.status == 'paused';
    final active = item.status == 'sending';
    final color = item.isUrgent
        ? colorScheme.error
        : paused
        ? colorScheme.tertiary
        : active
        ? colorScheme.primary
        : colorScheme.secondary;
    final icon = item.isUrgent
        ? Icons.emergency_rounded
        : paused
        ? Icons.pause_circle_filled_rounded
        : active
        ? Icons.send_rounded
        : Icons.schedule_rounded;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(item.summary),
      subtitle: Text(
        '${item.status.toUpperCase()} - ${item.packetCount} packets - '
        '${item.isUrgent ? 'priority lane' : 'routine lane'}',
      ),
      trailing: Chip(
        label: Text(item.isUrgent ? 'Urgent' : paused ? 'Paused' : 'Queue'),
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
