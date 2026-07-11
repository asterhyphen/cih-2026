class DeltaResult {
  const DeltaResult({
    required this.payload,
    required this.changedFields,
    required this.hasDelta,
  });

  final String payload;
  final List<String> changedFields;
  final bool hasDelta;
}

DeltaResult encodeDelta(
  Map<String, String> current,
  Map<String, String>? previous,
) {
  if (previous == null || previous.isEmpty) {
    return DeltaResult(
      payload: current.entries.map(_encodeEntry).join('|'),
      changedFields: current.keys.toList(),
      hasDelta: true,
    );
  }

  final changed = <MapEntry<String, String>>[];
  for (final entry in current.entries) {
    if (previous[entry.key] != entry.value) {
      changed.add(entry);
    }
  }

  return DeltaResult(
    payload: changed.map(_encodeEntry).join('|'),
    changedFields: changed.map((entry) => entry.key).toList(),
    hasDelta: changed.isNotEmpty,
  );
}

String _encodeEntry(MapEntry<String, String> entry) {
  return '${entry.key}=${entry.value}';
}
