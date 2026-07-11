const String patientSchemaPrefix = 'MGP1';
const String patientSchemaDelimiter = '|';

class PatientSchema {
  static const String versionPrefix = patientSchemaPrefix;
  static const String delimiter = patientSchemaDelimiter;

  static const List<String> fieldOrder = <String>[
    'id',
    'name',
    'age',
    'bloodPressure',
    'heartRate',
    'oxygenSaturation',
    'temperature',
    'notes',
    'photoRef',
    'urgent',
    'symptoms',
    'diagnosis',
    'medicalHistory',
    'currentMedication',
    'allergies',
    'consciousness',
    'emergencyNotes',
    'address',
    'contactDetails',
    'insurance',
    'gender',
    'bloodGroup',
  ];

  static const Map<String, String> legacyAliases = <String, String>{
    'id': 'id',
    'name': 'name',
    'displayName': 'name',
    'age': 'age',
    'bloodPressure': 'bloodPressure',
    'bp': 'bloodPressure',
    'heartRate': 'heartRate',
    'hr': 'heartRate',
    'oxygenSaturation': 'oxygenSaturation',
    'spo2': 'oxygenSaturation',
    'temperature': 'temperature',
    'temp': 'temperature',
    'notes': 'notes',
    'photoRef': 'photoRef',
    'photo': 'photoRef',
    'urgent': 'urgent',
    'symptoms': 'symptoms',
    'diagnosis': 'diagnosis',
    'medicalHistory': 'medicalHistory',
    'currentMedication': 'currentMedication',
    'allergies': 'allergies',
    'consciousness': 'consciousness',
    'emergencyNotes': 'emergencyNotes',
    'address': 'address',
    'contactDetails': 'contactDetails',
    'insurance': 'insurance',
    'gender': 'gender',
    'bloodGroup': 'bloodGroup',
  };

  static String encodeValues(Map<String, String> values) {
    final normalized = <String, String>{};
    for (final field in fieldOrder) {
      final legacyKey = legacyAliases.entries.firstWhere(
        (entry) => entry.value == field,
        orElse: () => const MapEntry<String, String>('', ''),
      ).key;
      final rawValue = values[field] ?? values[legacyKey] ?? '';
      normalized[field] = rawValue;
    }
    final serialized = normalized.values.map(_escapeValue).join(delimiter);
    return '$versionPrefix$delimiter$serialized';
  }

  static Map<String, String> decodeValues(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty patient record');
    }
    if (!trimmed.startsWith(versionPrefix)) {
      throw const FormatException('Missing schema prefix');
    }
    final parts = trimmed.split(delimiter);
    if (parts.isEmpty || parts.first != versionPrefix) {
      throw const FormatException('Missing schema prefix');
    }
    final rawValues = parts.skip(1).toList();
    final normalized = <String, String>{};
    for (var index = 0; index < fieldOrder.length; index++) {
      final field = fieldOrder[index];
      if (index < rawValues.length) {
        normalized[field] = _unescapeValue(rawValues[index]);
      } else {
        normalized[field] = '';
      }
    }
    return normalized;
  }

  static String _escapeValue(String value) {
    return value.replaceAll(delimiter, '\\$delimiter').replaceAll('\n', ' ');
  }

  static String _unescapeValue(String value) {
    return value.replaceAll('\\$delimiter', delimiter);
  }
}
