import 'package:cih/features/data/patient_model.dart';
import 'package:cih/features/nfc_capture/logic/nfc_patient_reader.dart';
import 'package:cih/features/nfc_capture/providers/nfc_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNfcReader implements NfcPatientReaderInterface {
  @override
  Future<PatientModel> readPatient() async {
    throw const NfcPermissionException('Enable NFC in settings to continue.');
  }
}

void main() {
  test('permission errors switch the NFC flow into a guidance state', () async {
    final container = ProviderContainer(
      overrides: [
        nfcProvider.overrideWith(() => NfcController(reader: FakeNfcReader())),
      ],
    );

    await container.read(nfcProvider.notifier).scanTag();
    final state = container.read(nfcProvider);

    expect(state.status, 'permission-required');
    expect(state.requiresPermission, isTrue);
    expect(state.message, contains('Enable NFC'));
  });
}
