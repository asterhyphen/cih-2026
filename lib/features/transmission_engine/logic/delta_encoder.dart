class DeltaResult {
  const DeltaResult({
    required this.payload,
    required this.changedFields,
    required this.hasDelta,
    required this.fullPayloadSize,
    required this.deltaPayloadSize,
  });

  final String payload;
  final List<String> changedFields;
  final bool hasDelta;
  final int fullPayloadSize;
  final int deltaPayloadSize;
}

DeltaResult encodeDelta(
  Map<String, String> current,
  Map<String, String>? previous,
) {
  final fullPayload = current.entries.map(_encodeEntry).join('|');
  if (previous == null || previous.isEmpty) {
    return DeltaResult(
      payload: fullPayload,
      changedFields: current.keys.toList(),
      hasDelta: true,
      fullPayloadSize: fullPayload.length,
      deltaPayloadSize: fullPayload.length,
    );
  }

  final changed = <MapEntry<String, String>>[];
  final preserved = <MapEntry<String, String>>[];
  for (final entry in current.entries) {
    if (entry.key == 'id') {
      preserved.add(entry);
      continue;
    }
    if (previous[entry.key] != entry.value) {
      changed.add(entry);
    }
  }

  final deltaPayload = [...preserved, ...changed].map(_encodeEntry).join('|');
  return DeltaResult(
    payload: deltaPayload,
    changedFields: changed.map((entry) => entry.key).toList(),
    hasDelta: changed.isNotEmpty,
    fullPayloadSize: fullPayload.length,
    deltaPayloadSize: deltaPayload.length,
  );
}

String _encodeEntry(MapEntry<String, String> entry) {
  return '${entry.key}=${entry.value}';
}
