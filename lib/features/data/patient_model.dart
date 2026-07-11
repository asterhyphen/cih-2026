class PatientModel {
  const PatientModel({
    required this.id,
    required this.displayName,
    required this.age,
    required this.bloodPressure,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.temperature,
    required this.notes,
    required this.photoRef,
  });

  final String id;
  final String displayName;
  final int age;
  final String bloodPressure;
  final int heartRate;
  final int oxygenSaturation;
  final double temperature;
  final String notes;
  final String photoRef;

  static const empty = PatientModel(
    id: '',
    displayName: '',
    age: 0,
    bloodPressure: '',
    heartRate: 0,
    oxygenSaturation: 0,
    temperature: 0,
    notes: '',
    photoRef: '',
  );

  factory PatientModel.fromWireMap(Map<String, String> data) {
    return PatientModel(
      id: data['id']?.trim() ?? '',
      displayName: data['name']?.trim() ?? '',
      age: int.tryParse(data['age'] ?? '') ?? 0,
      bloodPressure: data['bp']?.trim() ?? '',
      heartRate: int.tryParse(data['hr'] ?? '') ?? 0,
      oxygenSaturation: int.tryParse(data['spo2'] ?? '') ?? 0,
      temperature: double.tryParse(data['temp'] ?? '') ?? 0,
      notes: data['notes']?.trim() ?? '',
      photoRef: data['photo']?.trim() ?? '',
    );
  }

  factory PatientModel.fromPayload(String payload) {
    final data = <String, String>{};
    for (final part in payload.split('|')) {
      final separator = part.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      data[part.substring(0, separator)] = part.substring(separator + 1);
    }
    return PatientModel.fromWireMap(data);
  }

  Map<String, String> toWireMap() => {
    'id': id,
    'name': displayName,
    'age': '$age',
    'bp': bloodPressure,
    'hr': '$heartRate',
    'spo2': '$oxygenSaturation',
    'temp': temperature.toStringAsFixed(1),
    'notes': notes,
    'photo': photoRef,
  };

  String toPayload() => toWireMap().entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('|');

  bool get isValidForSend {
    return id.trim().isNotEmpty &&
        displayName.trim().isNotEmpty &&
        bloodPressure.trim().isNotEmpty &&
        heartRate > 0 &&
        oxygenSaturation > 0 &&
        temperature > 0;
  }

  PatientModel copyWith({
    String? id,
    String? displayName,
    int? age,
    String? bloodPressure,
    int? heartRate,
    int? oxygenSaturation,
    double? temperature,
    String? notes,
    String? photoRef,
  }) {
    return PatientModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      notes: notes ?? this.notes,
      photoRef: photoRef ?? this.photoRef,
    );
  }
}
