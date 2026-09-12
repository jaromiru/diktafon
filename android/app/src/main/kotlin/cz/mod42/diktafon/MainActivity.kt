package cz.mod42.diktafon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private companion object {
        // Outside the ranges Flutter plugins use for their own picks.
        const val SAVE_DOCUMENT_REQUEST = 7461
        const val IMPORT_DOCUMENT_REQUEST = 7462
        const val MODELS_FOLDER_REQUEST = 7463
    }

    private val decodeExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    // One SAF save at a time: the pending Dart result + the file to copy
    // once the user has picked where the document lands.
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveSource: String? = null

    // The recording notification's STOP action → Dart ("stopRecording" on
    // diktafon/recording_events). Registered with the engine, so it lives
    // as long as the Flutter process does.
    private var recordingEventsChannel: MethodChannel? = null

    private val stopRecordingReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            recordingEventsChannel?.invokeMethod("stopRecording", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        recordingEventsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "diktafon/recording_events")
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(
                stopRecordingReceiver,
                IntentFilter(RecordingForegroundService.ACTION_STOP_RECORDING),
                ContextCompat.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(
                stopRecordingReceiver,
                IntentFilter(RecordingForegroundService.ACTION_STOP_RECORDING))
        }
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
                    // Model-import pick: stream the picked document into a
                    // cache staging file. file_selector's Android openFile
                    // materializes the whole document in RAM, which OOM-kills
                    // the app on gigabyte models — this copies in 64 KB
                    // chunks. Answers the staged path, or null on cancel.
                    "importModelDocument" -> startImportDocument(result)
                    // Model-import folder: one SAF tree grant covers every
                    // model in the user's backup folder — Dart lists the
                    // children, filters by size, and stages+verifies each
                    // candidate through importModelDocument's choreography.
                    "pickModelsFolder" -> startModelsFolderPick(result)
                    "listFolderModels" -> {
                        val treeUri = Uri.parse(call.argument<String>("tree")!!)
                        Thread {
                            try {
                                mainHandler.post { result.success(listFolderModels(treeUri)) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("list_failed", e.message, null) }
                            }
                        }.start()
                    }
                    "stageFolderModel" -> {
                        val treeUri = Uri.parse(call.argument<String>("tree")!!)
                        val docId = call.argument<String>("documentId")!!
                        Thread {
                            try {
                                mainHandler.post { result.success(
                                    stageFolderModel(treeUri, docId)) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("copy_failed", e.message, null) }
                            }
                        }.start()
                    }
                    // D13: microphone-type foreground service under a live
                    // capture — false (never an error) when the OS rejects
                    // the start; Dart then falls back to finalize-on-pause.
                    "startRecordingService" -> result.success(
                        startRecordingService(call.argument("title"),
                            call.argument("channelName"),
                            call.argument("stopLabel")))
                    "stopRecordingService" -> {
                        stopService(Intent(this, RecordingForegroundService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Counterpart of HostCodecAudioTranscoder (lib/services/audio/
        // audio_transcoder.dart): WAV capture → archival AAC-LC m4a (§6.4).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "diktafon/transcoder")
            .setMethodCallHandler { call, result ->
                if (call.method != "transcodeToAac") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val input = call.argument<String>("input")
                val output = call.argument<String>("output")
                val bitRate = call.argument<Int>("bitRate") ?: 48000
                if (input == null || output == null) {
                    result.error("bad_args", "input/output paths required", null)
                    return@setMethodCallHandler
                }
                decodeExecutor.execute {
                    try {
                        transcodeWavToAac(input, output, bitRate)
                        mainHandler.post { result.success(null) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("transcode_failed", e.message, null) }
                    }
                }
            }
    }

    private fun startRecordingService(
        title: String?, channelName: String?, stopLabel: String?): Boolean {
        return try {
            ContextCompat.startForegroundService(
                this,
                Intent(this, RecordingForegroundService::class.java).apply {
                    putExtra(RecordingForegroundService.EXTRA_TITLE, title)
                    putExtra(RecordingForegroundService.EXTRA_CHANNEL_NAME, channelName)
                    putExtra(RecordingForegroundService.EXTRA_STOP_LABEL, stopLabel)
                })
            true
        } catch (e: Exception) {
            // ForegroundServiceStartNotAllowedException & friends: the app
            // was not foreground enough — recording still works, it just
            // won't survive backgrounding.
            false
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

    /** Model-import pick (see "importModelDocument" in configureFlutterEngine):
     *  one SAF document at a time; the result streams to a cache staging file
     *  whose path Dart verifies (sha256) and installs. */
    private var pendingImportResult: MethodChannel.Result? = null

    /** One SAF tree grant for the model-import folder ("Import from folder"):
     *  the grant lives for this call only — Dart lists children and stages
     *  candidates by document id while the URI is still answerable. */
    private var pendingFolderResult: MethodChannel.Result? = null

    private fun startModelsFolderPick(result: MethodChannel.Result) {
        if (pendingFolderResult != null) {
            result.error("busy", "another folder pick is in progress", null)
            return
        }
        pendingFolderResult = result
        try {
            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE),
                MODELS_FOLDER_REQUEST)
        } catch (e: Exception) {
            pendingFolderResult = null
            result.error("no_picker", e.message, null)
        }
    }

    /** Children of the picked tree as {documentId, name, size} maps — Dart
     *  filters by catalog sizes and stages only the candidates. */
    private fun listFolderModels(treeUri: Uri): List<Map<String, Any>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri, DocumentsContract.getTreeDocumentId(treeUri))
        val out = mutableListOf<Map<String, Any>>()
        contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_MIME_TYPE),
            null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(3) == DocumentsContract.Document.MIME_TYPE_DIR) {
                    continue
                }
                val size = cursor.getLong(2)
                if (size <= 0) continue
                out.add(mapOf(
                    "documentId" to cursor.getString(0),
                    "name" to cursor.getString(1),
                    "size" to size))
            }
        } ?: throw IOException("cannot query $treeUri")
        return out
    }

    /** Streams one folder document into the import staging file (same slot
     *  the single-document pick uses; imports are strictly sequential). */
    private fun stageFolderModel(treeUri: Uri, documentId: String): String {
        val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
        val staged = File(cacheDir, "imported_model")
        contentResolver.openInputStream(docUri)?.use { input ->
            staged.outputStream().use { output -> input.copyTo(output, 1 shl 16) }
        } ?: throw IOException("cannot open $documentId")
        return staged.absolutePath
    }

    private fun startImportDocument(result: MethodChannel.Result) {
        if (pendingImportResult != null) {
            result.error("busy", "another import pick is in progress", null)
            return
        }
        pendingImportResult = result
        try {
            startActivityForResult(
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                },
                IMPORT_DOCUMENT_REQUEST)
        } catch (e: Exception) {
            pendingImportResult = null
            result.error("no_picker", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == MODELS_FOLDER_REQUEST) {
            val result = pendingFolderResult
            pendingFolderResult = null
            val uri = data?.data
            if (result == null || resultCode != RESULT_OK || uri == null) {
                result?.success(null) // user backed out of the dialog
                return
            }
            result.success(uri.toString())
            return
        }
        if (requestCode == IMPORT_DOCUMENT_REQUEST) {
            val result = pendingImportResult
            pendingImportResult = null
            val uri = data?.data
            if (result == null || resultCode != RESULT_OK || uri == null) {
                result?.success(null) // user backed out of the dialog
                return
            }
            // Models are gigabytes — stream, never materialize in RAM.
            Thread {
                try {
                    val staged = File(cacheDir, "imported_model")
                    contentResolver.openInputStream(uri)?.use { input ->
                        staged.outputStream().use { output ->
                            input.copyTo(output, 1 shl 16)
                        }
                    } ?: throw IOException("cannot open $uri")
                    mainHandler.post { result.success(staged.absolutePath) }
                } catch (e: Exception) {
                    mainHandler.post { result.error("copy_failed", e.message, null) }
                }
            }.start()
            return
        }
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

    /** WAV facts the encoder needs; sizes derived from the file length, not
     *  the header fields (an interrupted capture leaves those stale). */
    private class WavPcm(
        val sampleRate: Int, val channels: Int, val dataOffset: Long, val dataBytes: Long)

    private fun parseWavPcm(path: String, raf: RandomAccessFile): WavPcm {
        val length = raf.length()
        val head = ByteArray(12)
        raf.readFully(head)
        require(String(head, 0, 4) == "RIFF" && String(head, 8, 4) == "WAVE") {
            "not a WAV: $path"
        }
        var sampleRate = 0
        var channels = 0
        var offset = 12L
        while (offset + 8 <= length) {
            raf.seek(offset)
            val header = ByteArray(8)
            raf.readFully(header)
            val id = String(header, 0, 4)
            val size = ByteBuffer.wrap(header, 4, 4)
                .order(ByteOrder.LITTLE_ENDIAN).int.toLong() and 0xFFFFFFFFL
            if (id == "fmt ") {
                val fmt = ByteArray(16)
                raf.readFully(fmt)
                val data = ByteBuffer.wrap(fmt).order(ByteOrder.LITTLE_ENDIAN)
                val format = data.short.toInt() and 0xFFFF
                require(format == 1 || format == 0xFFFE) { "not PCM: $path" }
                channels = data.short.toInt()
                sampleRate = data.int
                data.int // byte rate
                data.short // block align
                val bits = data.short.toInt()
                require(bits == 16) { "only s16 PCM supported, got $bits-bit" }
            } else if (id == "data") {
                require(sampleRate > 0 && channels > 0) { "data before fmt: $path" }
                val dataBytes = (length - offset - 8).let { it - (it % 2) }
                require(dataBytes > 0) { "empty WAV: $path" }
                return WavPcm(sampleRate, channels, offset + 8, dataBytes)
            }
            offset += 8 + size + (size and 1)
        }
        throw IOException("no data chunk in $path")
    }

    /**
     * PCM WAV → AAC-LC in an mp4 container (§6.4). Counterpart of the ffmpeg
     * path on desktop; streaming like [decodeToF32] — one input buffer of
     * samples in flight at a time, nothing accumulated.
     */
    private fun transcodeWavToAac(inputPath: String, outputPath: String, bitRate: Int) {
        RandomAccessFile(inputPath, "r").use { raf ->
            val wav = parseWavPcm(inputPath, raf)
            raf.seek(wav.dataOffset)

            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC, wav.sampleRate, wav.channels)
            format.setInteger(MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            var muxerStarted = false
            var track = -1
            codec.start()
            try {
                val bytesPerFrame = 2 * wav.channels
                var remaining = wav.dataBytes
                var framesFed = 0L
                var inputDone = false
                val info = MediaCodec.BufferInfo()
                val chunk = ByteArray(8192)
                while (true) {
                    if (!inputDone) {
                        val inIndex = codec.dequeueInputBuffer(10_000)
                        if (inIndex >= 0) {
                            if (remaining == 0L) {
                                codec.queueInputBuffer(inIndex, 0, 0,
                                    framesFed * 1_000_000L / wav.sampleRate,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                val buffer = codec.getInputBuffer(inIndex)!!
                                var want = minOf(
                                    remaining, buffer.capacity().toLong(), chunk.size.toLong())
                                want -= want % bytesPerFrame
                                raf.readFully(chunk, 0, want.toInt())
                                buffer.clear()
                                buffer.put(chunk, 0, want.toInt())
                                codec.queueInputBuffer(inIndex, 0, want.toInt(),
                                    framesFed * 1_000_000L / wav.sampleRate, 0)
                                framesFed += want / bytesPerFrame
                                remaining -= want
                            }
                        }
                    }
                    when (val outIndex = codec.dequeueOutputBuffer(info, 10_000)) {
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            track = muxer.addTrack(codec.outputFormat)
                            muxer.start()
                            muxerStarted = true
                        }
                        MediaCodec.INFO_TRY_AGAIN_LATER -> {}
                        else -> if (outIndex >= 0) {
                            if (info.size > 0 &&
                                info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                                val buffer = codec.getOutputBuffer(outIndex)!!
                                muxer.writeSampleData(track, buffer, info)
                            }
                            codec.releaseOutputBuffer(outIndex, false)
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                break
                            }
                        }
                    }
                }
            } finally {
                codec.stop()
                codec.release()
                if (muxerStarted) muxer.stop()
                muxer.release()
            }
        }
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
