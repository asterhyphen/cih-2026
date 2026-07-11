import 'package:cih/features/transmission_engine/logic/chunking.dart';
import 'package:cih/features/transmission_engine/logic/parity.dart';
import 'package:cih/features/transmission_engine/providers/transmission_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parity values are generated from chunks', () {
    final chunks = chunkText('abc', 2);
    final parity = generateParity(chunks);

    expect(chunks, ['ab', 'c']);
    expect(parity, isNotEmpty);
  });

  test('sending on stable network completes as delivered', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(transmissionProvider.notifier);
    await controller.sendTransmission();

    final state = container.read(transmissionProvider);
    expect(state.status, 'delivered');
    expect(state.progress, 100);
  });

  test('sending records an activity entry in the history', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(transmissionProvider.notifier);
    await controller.sendTransmission(
      payload:
          'id=40A1|name=Asha Raman|age=47|bp=132/86|hr=112|spo2=93|temp=101.2',
      networkMode: 'stable',
    );

    final state = container.read(transmissionProvider);
    expect(state.history, isNotEmpty);
    expect(state.history.first.status, 'delivered');
  });
}
