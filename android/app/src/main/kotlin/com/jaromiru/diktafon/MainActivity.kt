package com.jaromiru.diktafon

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
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val decodeExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val mainHandler = Handler(Looper.getMainLooper())
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
        // Escape hatch for a permanently denied mic permission (the OS stops
        // showing the prompt): the snackbar's action lands on the app's page
        // in the system settings.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "diktafon/system")
            .setMethodCallHandler { call, result ->
                if (call.method != "openAppSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null)))
                result.success(null)
            }
    }

    /** Decodes the first audio track to mono float PCM, resampled to 16 kHz. */
    private fun decodeToF32(inputPath: String, outputPath: String) {
        val extractor = MediaExtractor()
        val mono = ArrayList<Float>(1 shl 20)
        var sampleRate = 16000
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
                sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                var pcmEncoding = AudioFormat.ENCODING_PCM_16BIT

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
                            val out = codec.outputFormat
                            sampleRate = out.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channels = out.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            if (out.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                                pcmEncoding = out.getInteger(MediaFormat.KEY_PCM_ENCODING)
                            }
                        }
                        MediaCodec.INFO_TRY_AGAIN_LATER -> {}
                        else -> if (outIndex >= 0) {
                            val buffer = codec.getOutputBuffer(outIndex)!!
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)
                            appendMono(buffer, pcmEncoding, channels, mono)
                            codec.releaseOutputBuffer(outIndex, false)
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                outputDone = true
                            }
                        }
                    }
                }
            } finally {
                codec.stop()
                codec.release()
            }
        } finally {
            extractor.release()
        }

        val resampled = resampleTo16k(mono, sampleRate)
        val bytes = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        BufferedOutputStream(FileOutputStream(outputPath), 1 shl 16).use { out ->
            for (sample in resampled) {
                bytes.clear()
                bytes.putFloat(sample)
                out.write(bytes.array())
            }
        }
    }

    /** Downmixes one decoder output buffer to mono floats. */
    private fun appendMono(
        buffer: ByteBuffer, pcmEncoding: Int, channels: Int, sink: ArrayList<Float>) {
        buffer.order(ByteOrder.nativeOrder())
        if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) {
            val floats = buffer.asFloatBuffer()
            val frame = FloatArray(channels)
            while (floats.remaining() >= channels) {
                floats.get(frame)
                sink.add(frame.average().toFloat())
            }
        } else {
            val shorts = buffer.asShortBuffer()
            val frame = ShortArray(channels)
            while (shorts.remaining() >= channels) {
                shorts.get(frame)
                var sum = 0f
                for (s in frame) sum += s / 32768f
                sink.add(sum / channels)
            }
        }
    }

    /** Linear resample; memos are recorded at 16 kHz so this is usually a no-op. */
    private fun resampleTo16k(input: ArrayList<Float>, sourceRate: Int): FloatArray {
        if (sourceRate == 16000 || input.isEmpty()) return input.toFloatArray()
        val outLength = (input.size.toLong() * 16000 / sourceRate).toInt()
        val out = FloatArray(outLength)
        val step = sourceRate.toDouble() / 16000.0
        for (i in 0 until outLength) {
            val pos = i * step
            val base = pos.toInt().coerceAtMost(input.size - 1)
            val next = (base + 1).coerceAtMost(input.size - 1)
            val frac = (pos - base).toFloat()
            out[i] = input[base] * (1 - frac) + input[next] * frac
        }
        return out
    }
}
