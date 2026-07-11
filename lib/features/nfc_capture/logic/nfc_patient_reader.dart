import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../../data/patient_model.dart';

abstract class NfcPatientReaderInterface {
  Future<PatientModel> readPatient();
}

class NfcPermissionException implements Exception {
  const NfcPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NfcPatientReader implements NfcPatientReaderInterface {
  @override
  Future<PatientModel> readPatient() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw NfcPermissionException(
        'Enable NFC in device settings and try again. You can still continue by typing patient details manually.',
      );
    }

    final completer = Completer<PatientModel>();
    await NfcManager.instance.startSession(
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      alertMessageIos: 'Hold near a patient card',
      onDiscovered: (tag) async {
        try {
          final payload = await _readPayload(tag);
          final patient = PatientModel.fromPayload(payload);
          if (!patient.isValidForSend) {
            throw FormatException('Patient card is missing required fields');
          }
          if (!completer.isCompleted) {
            completer.complete(patient);
          }
          await NfcManager.instance.stopSession(
            alertMessageIos: 'Patient loaded',
          );
        } catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          await NfcManager.instance.stopSession(
            errorMessageIos: 'Could not read patient card',
          );
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 20));
  }

  Future<String> _readPayload(NfcTag tag) async {
    final message = await _readNdefMessage(tag);
    final records = message?.records ?? const <NdefRecord>[];
    if (records.isEmpty) {
      throw const FormatException('No NDEF records found');
    }
    final record = records.firstWhere(
      _isTextRecord,
      orElse: () => records.first,
    );
    return _decodeRecord(record);
  }

  Future<NdefMessage?> _readNdefMessage(NfcTag tag) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final ndef = NdefAndroid.from(tag);
        return ndef?.getNdefMessage();
      case TargetPlatform.iOS:
        final ndef = NdefIos.from(tag);
        return ndef?.readNdef();
      default:
        throw UnsupportedError('NFC is not supported on this platform');
    }
  }

  bool _isTextRecord(NdefRecord record) {
    return utf8.decode(record.type, allowMalformed: true) == 'T';
  }

  String _decodeRecord(NdefRecord record) {
    if (_isTextRecord(record) && record.payload.isNotEmpty) {
      final languageLength = record.payload.first & 0x3f;
      return utf8.decode(
        record.payload.skip(1 + languageLength).toList(),
        allowMalformed: true,
      );
    }
    return utf8.decode(record.payload, allowMalformed: true);
  }
}
