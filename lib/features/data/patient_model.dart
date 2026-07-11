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
    this.symptoms = '',
    this.diagnosis = '',
    this.medicalHistory = '',
    this.currentMedication = '',
    this.allergies = '',
    this.consciousness = '',
    this.emergencyNotes = '',
    this.address = '',
    this.contactDetails = '',
    this.insurance = '',
    this.gender = '',
    this.bloodGroup = '',
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
  final String symptoms;
  final String diagnosis;
  final String medicalHistory;
  final String currentMedication;
  final String allergies;
  final String consciousness;
  final String emergencyNotes;
  final String address;
  final String contactDetails;
  final String insurance;
  final String gender;
  final String bloodGroup;

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
      symptoms: data['symptoms']?.trim() ?? '',
      diagnosis: data['diagnosis']?.trim() ?? '',
      medicalHistory: data['medicalHistory']?.trim() ?? '',
      currentMedication: data['currentMedication']?.trim() ?? '',
      allergies: data['allergies']?.trim() ?? '',
      consciousness: data['consciousness']?.trim() ?? '',
      emergencyNotes: data['emergencyNotes']?.trim() ?? '',
      address: data['address']?.trim() ?? '',
      contactDetails: data['contactDetails']?.trim() ?? '',
      insurance: data['insurance']?.trim() ?? '',
      gender: data['gender']?.trim() ?? '',
      bloodGroup: data['bloodGroup']?.trim() ?? '',
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
    'symptoms': symptoms,
    'diagnosis': diagnosis,
    'medicalHistory': medicalHistory,
    'currentMedication': currentMedication,
    'allergies': allergies,
    'consciousness': consciousness,
    'emergencyNotes': emergencyNotes,
    'address': address,
    'contactDetails': contactDetails,
    'insurance': insurance,
    'gender': gender,
    'bloodGroup': bloodGroup,
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
    String? symptoms,
    String? diagnosis,
    String? medicalHistory,
    String? currentMedication,
    String? allergies,
    String? consciousness,
    String? emergencyNotes,
    String? address,
    String? contactDetails,
    String? insurance,
    String? gender,
    String? bloodGroup,
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
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedication: currentMedication ?? this.currentMedication,
      allergies: allergies ?? this.allergies,
      consciousness: consciousness ?? this.consciousness,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      address: address ?? this.address,
      contactDetails: contactDetails ?? this.contactDetails,
      insurance: insurance ?? this.insurance,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
