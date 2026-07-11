import 'dart:convert';

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
    this.parityGroup = -1,
  });

  final int index;
  final String body;
  final int retrievalBit;
  final bool parity;
  final int parityGroup;
}

List<ProtectedChunk> buildProtectedChunks(
  String input, {
  int chunkSize = 18,
  int sparePieces = 2,
}) {
  final chunks = chunkText(input, chunkSize);
  if (chunks.isEmpty) {
    return const <ProtectedChunk>[];
  }

  final dataChunks = <ProtectedChunk>[
    for (var index = 0; index < chunks.length; index++)
      ProtectedChunk(
        index: index,
        body: chunks[index],
        retrievalBit: _retrievalBit(chunks[index], index),
      ),
  ];

  final parityChunks = <ProtectedChunk>[];
  if (sparePieces > 0) {
    final groups = <List<ProtectedChunk>>[];
    for (var groupIndex = 0; groupIndex < sparePieces; groupIndex++) {
      groups.add(<ProtectedChunk>[]);
    }
    for (var index = 0; index < dataChunks.length; index++) {
      groups[index % sparePieces].add(dataChunks[index]);
    }

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final parityBody = _buildParityChunk(groups[groupIndex]);
      parityChunks.add(
        ProtectedChunk(
          index: dataChunks.length + groupIndex,
          body: parityBody,
          retrievalBit: _retrievalBit(parityBody, groupIndex),
          parity: true,
          parityGroup: groupIndex,
        ),
      );
    }
  }

  return [...dataChunks, ...parityChunks];
}

String reconstructPayload(
  Iterable<ProtectedChunk> availableChunks, {
  required int expectedDataChunkCount,
}) {
  final availableDataChunks =
      availableChunks.where((chunk) => !chunk.parity).toList()
        ..sort((a, b) => a.index.compareTo(b.index));
  final parityChunks = availableChunks.where((chunk) => chunk.parity).toList();
  final recoveredByIndex = <int, ProtectedChunk>{};

  for (final chunk in availableDataChunks) {
    recoveredByIndex[chunk.index] = chunk;
  }

  final parityCount = parityChunks.length;
  for (final parityChunk in parityChunks) {
    if (parityCount == 0) {
      continue;
    }

    final groupIndices = <int>[
      for (var index = 0; index < expectedDataChunkCount; index++)
        if (index % parityCount == parityChunk.parityGroup) index,
    ];
    final missingIndex = groupIndices.firstWhere(
      (index) => !recoveredByIndex.containsKey(index),
      orElse: () => -1,
    );
    if (missingIndex < 0) {
      continue;
    }

    final survivingChunks = groupIndices
        .where(
          (index) =>
              index != missingIndex && recoveredByIndex.containsKey(index),
        )
        .map((index) => recoveredByIndex[index]!)
        .toList();
    if (survivingChunks.isEmpty) {
      continue;
    }

    final reconstructedBody = _recoverMissingChunk(
      parityChunk.body,
      survivingChunks,
    );
    recoveredByIndex[missingIndex] = ProtectedChunk(
      index: missingIndex,
      body: reconstructedBody,
      retrievalBit: _retrievalBit(reconstructedBody, missingIndex),
    );
  }

  if (recoveredByIndex.length < expectedDataChunkCount) {
    throw StateError('Not enough chunks to reconstruct payload');
  }

  final reconstructed = StringBuffer();
  for (var index = 0; index < expectedDataChunkCount; index++) {
    final chunk = recoveredByIndex[index];
    if (chunk == null) {
      throw StateError('Not enough chunks to reconstruct payload');
    }
    reconstructed.write(chunk.body);
  }
  return reconstructed.toString();
}

String _buildParityChunk(List<ProtectedChunk> dataChunks) {
  if (dataChunks.isEmpty) {
    return '';
  }

  final bytes = <int>[];
  for (final chunk in dataChunks) {
    final utf8Bytes = utf8.encode(chunk.body);
    for (var i = 0; i < utf8Bytes.length; i++) {
      if (i >= bytes.length) {
        bytes.add(utf8Bytes[i]);
      } else {
        bytes[i] ^= utf8Bytes[i];
      }
    }
  }
  return utf8.decode(bytes, allowMalformed: true);
}

String _recoverMissingChunk(
  String parityBody,
  List<ProtectedChunk> survivingChunks,
) {
  final bytes = utf8.encode(parityBody);
  var recovered = <int>[...bytes];
  for (final survivingChunk in survivingChunks) {
    final chunkBytes = utf8.encode(survivingChunk.body);
    for (var i = 0; i < chunkBytes.length; i++) {
      if (i < recovered.length) {
        recovered[i] ^= chunkBytes[i];
      }
    }
  }
  return utf8.decode(recovered, allowMalformed: true);
}

int _retrievalBit(String value, int salt) {
  return value.codeUnits.fold(salt, (sum, unit) => sum + unit) % 2;
}
