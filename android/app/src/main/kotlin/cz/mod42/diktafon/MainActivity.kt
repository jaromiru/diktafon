package cz.mod42.diktafon

import android.content.Intent
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private companion object {
        // Outside the ranges Flutter plugins use for their own picks.
        const val SAVE_DOCUMENT_REQUEST = 7461
    }

    private val decodeExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    // One SAF save at a time: the pending Dart result + the file to copy
    // once the user has picked where the document lands.
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveSource: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Counterpart of MediaCodecPcmDecoder (lib/services/audio/pcm_decoder.dart):
        // decodes a memo file to raw f32le 16 kHz mono PCM for whisper.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "diktafon/pcm_decoder")
            .setMethodCallHandler { call, result ->
                if (call.method != "decodeToF32") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val input = call.argument<String>("input")
                val output = call.argument<String>("output")
                if (input == null || output == null) {
                    result.error("bad_args", "input/output paths required", null)
                    return@setMethodCallHandler
                }
                decodeExecutor.execute {
                    try {
                        decodeToF32(input, output)
                        mainHandler.post { result.success(null) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("decode_failed", e.message, null) }
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "diktafon/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Escape hatch for a permanently denied mic permission
                    // (the OS stops showing the prompt): the snackbar's action
                    // lands on the app's page in the system settings.
                    "openAppSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null)))
                        result.success(null)
                    }
                    // SAF hand-off for export archives (§8): file_selector has
                    // no save dialog on Android, so Dart stages the zip in the
                    // cache and this copies it into the document the user
                    // creates. Answers false when the user backs out.
                    "saveDocument" -> startSaveDocument(call.argument("source"),
                        call.argument("name"), call.argument("mime"), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startSaveDocument(
        source: String?, name: String?, mime: String?, result: MethodChannel.Result) {
        if (source == null || name == null) {
            result.error("bad_args", "source/name required", null)
            return
        }
        if (pendingSaveResult != null) {
            result.error("busy", "another save is in progress", null)
            return
        }
        pendingSaveResult = result
        pendingSaveSource = source
        startActivityForResult(
            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mime ?: "application/zip"
                putExtra(Intent.EXTRA_TITLE, name)
            },
            SAVE_DOCUMENT_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != SAVE_DOCUMENT_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data) // plugins' picks
            return
        }
        val result = pendingSaveResult ?: return
        val source = pendingSaveSource
        pendingSaveResult = null
        pendingSaveSource = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null || source == null) {
            result.success(false) // user backed out of the dialog
            return
        }
        // The archive can be large — copy it off the main thread.
        Thread {
            try {
                contentResolver.openOutputStream(uri)?.use { out ->
                    FileInputStream(source).use { it.copyTo(out) }
                } ?: throw IOException("cannot open $uri")
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("save_failed", e.message, null) }
            }
        }.start()
    }

    /**
     * Decodes the first audio track to mono float PCM, resampled to 16 kHz.
     *
     * Fully streaming: each decoder buffer is downmixed, resampled and
     * written straight to the output file. Accumulating the recording in
     * memory (let alone as boxed Floats) costs hundreds of MB per hour of
     * audio and OOM-kills the app on long memos — whisper's own buffer on
     * the Dart side is unavoidable, this one never was.
     */
    private fun decodeToF32(inputPath: String, outputPath: String) {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(inputPath)
            var track = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                    track = i
                    format = f
                    break
                }
            }
            require(track >= 0) { "no audio track in $inputPath" }
            extractor.selectTrack(track)

            val codec = MediaCodec.createDecoderByType(format!!.getString(MediaFormat.KEY_MIME)!!)
            codec.configure(format, null, null, 0)
            codec.start()
            try {
                var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                var pcmEncoding = AudioFormat.ENCODING_PCM_16BIT
                // The resampler locks onto the rate of the first output
                // buffer (any INFO_OUTPUT_FORMAT_CHANGED arrives before it).
                var resampler: StreamingResampleTo16k? = null

                BufferedOutputStream(FileOutputStream(outputPath), 1 shl 16).use { out ->
                    val writer = F32Writer(out)
                    val info = MediaCodec.BufferInfo()
                    var inputDone = false
                    var outputDone = false
                    while (!outputDone) {
                        if (!inputDone) {
                            val inIndex = codec.dequeueInputBuffer(10_000)
                            if (inIndex >= 0) {
                                val buffer = codec.getInputBuffer(inIndex)!!
                                val size = extractor.readSampleData(buffer, 0)
                                if (size < 0) {
                                    codec.queueInputBuffer(
                                        inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                    inputDone = true
                                } else {
                                    codec.queueInputBuffer(inIndex, 0, size, extractor.sampleTime, 0)
                                    extractor.advance()
                                }
                            }
                        }
                        when (val outIndex = codec.dequeueOutputBuffer(info, 10_000)) {
                            MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                                val outFormat = codec.outputFormat
                                sampleRate = outFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                                channels = outFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                                if (outFormat.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                                    pcmEncoding = outFormat.getInteger(MediaFormat.KEY_PCM_ENCODING)
                                }
                            }
                            MediaCodec.INFO_TRY_AGAIN_LATER -> {}
                            else -> if (outIndex >= 0) {
                                if (resampler == null) {
                                    resampler = StreamingResampleTo16k(sampleRate)
                                }
                                val buffer = codec.getOutputBuffer(outIndex)!!
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                forEachMonoSample(buffer, pcmEncoding, channels) { sample ->
                                    resampler!!.add(sample, writer::write)
                                }
                                codec.releaseOutputBuffer(outIndex, false)
                                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                    outputDone = true
                                }
                            }
                        }
                    }
                    resampler?.flush(writer::write)
                }
            } finally {
                codec.stop()
                codec.release()
            }
        } finally {
            extractor.release()
        }
    }

    /** Downmixes one decoder output buffer to mono floats, sample by sample. */
    private inline fun forEachMonoSample(
        buffer: ByteBuffer, pcmEncoding: Int, channels: Int, emit: (Float) -> Unit) {
        buffer.order(ByteOrder.nativeOrder())
        if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) {
            val floats = buffer.asFloatBuffer()
            val frame = FloatArray(channels)
            while (floats.remaining() >= channels) {
                floats.get(frame)
                var sum = 0f
                for (s in frame) sum += s
                emit(sum / channels)
            }
        } else {
            val shorts = buffer.asShortBuffer()
            val frame = ShortArray(channels)
            while (shorts.remaining() >= channels) {
                shorts.get(frame)
                var sum = 0f
                for (s in frame) sum += s / 32768f
                emit(sum / channels)
            }
        }
    }

    /** Little-endian f32 sink over a buffered stream. */
    private class F32Writer(private val out: BufferedOutputStream) {
        private val bytes = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)

        fun write(sample: Float) {
            bytes.clear()
            bytes.putFloat(sample)
            out.write(bytes.array())
        }
    }

    /**
     * Chunkless linear resample to 16 kHz: an output sample at fractional
     * source position `i * sourceRate/16000` is emitted as soon as both
     * neighbouring source samples have been seen — only the last two are
     * kept. Memos are recorded at 16 kHz, so this usually degenerates to
     * pass-through.
     */
    private class StreamingResampleTo16k(private val sourceRate: Int) {
        private val step = sourceRate.toDouble() / 16000.0
        private var nextOut = 0L // next output sample index
        private var seen = 0L // source samples consumed so far
        private var s0 = 0f // source[seen - 2]
        private var s1 = 0f // source[seen - 1]

        fun add(sample: Float, emit: (Float) -> Unit) {
            if (sourceRate == 16000) {
                emit(sample)
                return
            }
            s0 = s1
            s1 = sample
            seen++
            // Emit eagerly: every output whose interpolation pair
            // (base, base+1) is now complete has base == seen-2.
            while (true) {
                val pos = nextOut * step
                val base = pos.toLong()
                if (base + 1 >= seen) break // needs a future sample
                val frac = (pos - base).toFloat()
                emit(s0 * (1 - frac) + s1 * frac)
                nextOut++
            }
        }

        /** The tail: outputs whose `base+1` never arrived clamp to the last
         *  sample, matching a whole-file resample's edge handling. */
        fun flush(emit: (Float) -> Unit) {
            if (sourceRate == 16000 || seen == 0L) return
            val total = seen * 16000 / sourceRate
            while (nextOut < total) {
                val pos = nextOut * step
                val base = pos.toLong()
                if (base >= seen - 1) {
                    emit(s1)
                } else {
                    val frac = (pos - base).toFloat()
                    emit(s0 * (1 - frac) + s1 * frac)
                }
                nextOut++
            }
        }
    }
}
