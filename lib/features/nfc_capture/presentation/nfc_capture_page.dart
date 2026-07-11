import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_page_wrapper.dart';
import '../../../core/widgets/floating_nav_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../../patient_storage/providers/patient_storage_provider.dart';
import '../../transmission_engine/logic/chunking.dart';
import '../../transmission_engine/providers/transmission_provider.dart';
import '../providers/nfc_provider.dart';
import 'nfc_scan_dialog.dart';

class NfcCapturePage extends ConsumerStatefulWidget {
  const NfcCapturePage({super.key});

  @override
  ConsumerState<NfcCapturePage> createState() => _NfcCapturePageState();
}

class _NfcCapturePageState extends ConsumerState<NfcCapturePage> {
  bool _scanDialogVisible = false;

  void _presentScanDialog() {
    if (!mounted || _scanDialogVisible) {
      return;
    }

    _scanDialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scanDialogVisible) {
        return;
      }

      showNfcScanDialog(context).then((_) {
        if (mounted) {
          setState(() => _scanDialogVisible = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NfcState>(nfcProvider, (previous, next) {
      final guideActive =
          next.showGuide &&
          (next.status == 'scanning' || next.status == 'writing');
      if (guideActive && !_scanDialogVisible) {
        _presentScanDialog();
      } else if (_scanDialogVisible && !guideActive) {
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (mounted) {
          setState(() => _scanDialogVisible = false);
        }
      }

      if (previous?.message != next.message && !guideActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(next.message),
            action: next.requiresPermission
                ? SnackBarAction(
                    label: 'Manual entry',
                    onPressed: () =>
                        ref.read(nfcProvider.notifier).loadFallback(),
                  )
                : null,
          ),
        );
      }
    });
    final captureState = ref.watch(nfcProvider);
    final transmission = ref.watch(transmissionProvider);
    final storage = ref.watch(patientStorageProvider);
    final patient = captureState.patient;
    final storedRecord = patient == null ? null : storage.recordFor(patient.id);
    final diffLines = patient == null || storage.latestPatient?.id != patient.id
        ? const <String>[]
        : storage.latestDiff.summaries(patient, storedRecord?.confirmedPatient);
    final chunks = buildProtectedChunks(captureState.payload);
    final canSend =
        patient != null && captureState.valid && patient.isValidForSend;

    return Scaffold(
      body: AnimatedPageWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contactless intake',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture, edit, write, and send a patient record.',
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
                              'Capture session',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: captureState.requiresPermission
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              captureState.status.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(captureState.message),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoPill(
                            label: 'Validation',
                            value: captureState.valid ? 'Ready' : 'Pending',
                          ),
                          const SizedBox(width: 8),
                          _InfoPill(
                            label: 'Confidence',
                            value: '${captureState.confidence}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                ref.read(nfcProvider.notifier).scanTag(),
                            icon: const Icon(Icons.nfc_outlined),
                            label: const Text('Scan NFC'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(nfcProvider.notifier).loadFallback(),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Type instead'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canSend
                                ? () => ref
                                      .read(nfcProvider.notifier)
                                      .writePatientCard()
                                : null,
                            icon: const Icon(Icons.tap_and_play_outlined),
                            label: const Text('Write card'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(nfcProvider.notifier).clear(),
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (patient != null) ...[
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _SourceBadge(source: captureState.captureSource),
                        const SizedBox(height: 8),
                        if (patient.urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emergency_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Urgent case',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        if (diffLines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DiffSummary(lines: diffLines),
                        ],
                        const SizedBox(height: 12),
                        _VitalField(
                          label: 'Patient ID',
                          value: patient.id,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(id: value),
                        ),
                        _VitalField(
                          label: 'Full name',
                          value: patient.displayName,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(displayName: value),
                        ),
                        _VitalField(
                          label: 'Age',
                          value: patient.age == 0 ? '' : '${patient.age}',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(age: int.tryParse(value)),
                        ),
                        _VitalField(
                          label: 'Blood pressure',
                          value: patient.bloodPressure,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(bloodPressure: value),
                        ),
                        _VitalField(
                          label: 'Heart rate',
                          value: '${patient.heartRate}',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(heartRate: int.tryParse(value)),
                        ),
                        _VitalField(
                          label: 'Oxygen saturation',
                          value: '${patient.oxygenSaturation}',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(
                                oxygenSaturation: int.tryParse(value),
                              ),
                        ),
                        _VitalField(
                          label: 'Temperature',
                          value: patient.temperature.toStringAsFixed(1),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(
                                temperature: double.tryParse(value),
                              ),
                        ),
                        _VitalField(
                          label: 'Clinical notes',
                          value: patient.notes,
                          maxLines: 2,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(notes: value),
                        ),
                        _VitalField(
                          label: 'Photo reference',
                          value: patient.photoRef,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(photoRef: value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mark as urgent'),
                          subtitle: const Text(
                            'Expedites fallback and preserves a tiny thumbnail in fallback mode.',
                          ),
                          value: patient.urgent,
                          onChanged: (value) => ref
                              .read(nfcProvider.notifier)
                              .updateVitals(urgent: value),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: canSend
                              ? () => ref
                                    .read(transmissionProvider.notifier)
                                    .sendPatientRecord(patient: patient)
                              : null,
                          child: const Text('Send protected update'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transmission preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Protected chunks: ${chunks.where((c) => !c.parity).length}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Spare retrieval pieces: ${chunks.where((c) => c.parity).length}',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chunks
                            .take(8)
                            .map(
                              (chunk) => Chip(
                                label: Text(
                                  '${chunk.index}:${chunk.retrievalBit}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(transmission.message),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final isNfc = source == 'nfc';
    final label = isNfc ? 'Captured by NFC' : 'Manual fallback';
    final icon = isNfc ? Icons.nfc_rounded : Icons.edit_note_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DiffSummary extends StatelessWidget {
  const _DiffSummary({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delta preview', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          ...lines.take(5).map((line) => Text(line)),
        ],
      ),
    );
  }
}

class _VitalField extends StatefulWidget {
  const _VitalField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<_VitalField> createState() => _VitalFieldState();
}

class _VitalFieldState extends State<_VitalField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _VitalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        textInputAction: widget.maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: widget.onChanged,
      ),
    );
  }
}
