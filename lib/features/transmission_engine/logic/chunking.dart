List<String> chunkText(String input, int chunkSize) {
  if (input.isEmpty || chunkSize <= 0) {
    return const <String>[];
  }

  final chunks = <String>[];
  for (var offset = 0; offset < input.length; offset += chunkSize) {
    chunks.add(
      input.substring(
        offset,
        offset + chunkSize > input.length ? input.length : offset + chunkSize,
      ),
    );
  }
  return chunks;
}

class ProtectedChunk {
  const ProtectedChunk({
    required this.index,
    required this.body,
    required this.retrievalBit,
    this.parity = false,
  });

  final int index;
  final String body;
  final int retrievalBit;
  final bool parity;
}

List<ProtectedChunk> buildProtectedChunks(
  String input, {
  int chunkSize = 18,
  int sparePieces = 2,
}) {
  final chunks = chunkText(input, chunkSize);
  final protected = <ProtectedChunk>[
    for (var index = 0; index < chunks.length; index++)
      ProtectedChunk(
        index: index,
        body: chunks[index],
        retrievalBit: _retrievalBit(chunks[index], index),
      ),
  ];

  for (var index = 0; index < sparePieces; index++) {
    protected.add(
      ProtectedChunk(
        index: chunks.length + index,
        body: 'parity-$index',
        retrievalBit: _retrievalBit(input, index),
        parity: true,
      ),
    );
  }
  return protected;
}

int _retrievalBit(String value, int salt) {
  return value.codeUnits.fold(salt, (sum, unit) => sum + unit) % 2;
}
