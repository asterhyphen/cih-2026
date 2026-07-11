import 'package:flutter_test/flutter_test.dart';
import 'package:cih/features/transmission_engine/logic/chunking.dart';

void main() {
  group('chunkText', () {
    test('splits text into equally sized chunks', () {
      expect(chunkText('abcdefghij', 3), ['abc', 'def', 'ghi', 'j']);
    });

    test('returns the full string when chunk size is larger', () {
      expect(chunkText('hello', 10), ['hello']);
    });
  });
}
