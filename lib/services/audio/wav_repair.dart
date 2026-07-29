/// Making killed captures playable (§6.4, D13): capture writes PCM WAV, and
/// a process death mid-recording leaves the RIFF/data chunk sizes at whatever
/// the recorder wrote at start — the samples themselves are all on disk.
/// Rewriting the two size fields from the real file length turns the leftover
/// into a fully valid file.
library;

import 'dart:io';
import 'dart:typed_data';

/// The format facts recovery needs from a (possibly unfinalized) WAV file.
class WavInfo {
  const WavInfo({
    required this.durationMs,
    required this.dataBytes,
  });

  final int durationMs;
  final int dataBytes;
}

/// Walks the RIFF chunks of the WAV at [path], rewrites the RIFF and `data`
/// sizes to match the actual file length, and returns the audio's real
/// duration. Idempotent: a correctly finalized file is left byte-identical.
/// Returns null when the file is not a PCM WAV (or too short to hold any
/// audio) — the caller treats that as an unrecoverable capture.
Future<WavInfo?> repairWav(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  final length = await file.length();
  // RIFF header (12) + fmt chunk (24) + data chunk header (8): anything
  // shorter holds no samples at all.
  if (length < 44) return null;

  final raf = await file.open(mode: FileMode.append);
  try {
    await raf.setPosition(0);
    final head = await raf.read(12);
    if (String.fromCharCodes(head, 0, 4) != 'RIFF' ||
        String.fromCharCodes(head, 8, 12) != 'WAVE') {
      return null;
    }

    // Chunk walk: the recorder may emit extra chunks (LIST, fact) between
    // fmt and data — don't assume the canonical 44-byte layout.
    int? byteRate;
    var offset = 12;
    while (offset + 8 <= length) {
      await raf.setPosition(offset);
      final header = await raf.read(8);
      final id = String.fromCharCodes(header, 0, 4);
      final size = ByteData.sublistView(header, 4, 8).getUint32(0, Endian.little);
      if (id == 'fmt ') {
        if (size < 16 || offset + 8 + 16 > length) return null;
        final fmt = await raf.read(16);
        final data = ByteData.sublistView(fmt);
        final format = data.getUint16(0, Endian.little);
        if (format != 1 && format != 0xFFFE) return null; // PCM only
        byteRate = data.getUint32(8, Endian.little);
        if (byteRate == 0) return null;
      } else if (id == 'data') {
        if (byteRate == null) return null; // data before fmt — not a WAV
        final dataStart = offset + 8;
        final dataBytes = length - dataStart;
        if (dataBytes <= 0) return null;
        // An interrupted recorder leaves both sizes stale (zero, or a
        // placeholder like 0xFFFFFFFF); a clean stop leaves them exact.
        final sizes = ByteData(4);
        if (size != dataBytes) {
          sizes.setUint32(0, dataBytes, Endian.little);
          await raf.setPosition(offset + 4);
          await raf.writeFrom(sizes.buffer.asUint8List());
        }
        final riffSize = length - 8;
        await raf.setPosition(4);
        final riffField = await raf.read(4);
        if (ByteData.sublistView(riffField).getUint32(0, Endian.little) !=
            riffSize) {
          sizes.setUint32(0, riffSize, Endian.little);
          await raf.setPosition(4);
          await raf.writeFrom(sizes.buffer.asUint8List());
        }
        await raf.flush();
        return WavInfo(
          durationMs: dataBytes * 1000 ~/ byteRate,
          dataBytes: dataBytes,
        );
      }
      // Chunks are word-aligned; a stale size field can point past EOF —
      // the data chunk is by construction the last one, so walking off the
      // end just means "no data chunk found".
      offset += 8 + size + (size & 1);
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    await raf.close();
  }
}
