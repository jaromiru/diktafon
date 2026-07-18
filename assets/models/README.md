# Bundled models

## `ggml-silero-v5.1.2.bin`

The [Silero VAD](https://github.com/snakers4/silero-vad) voice-activity-detection
model, v5.1.2, in ggml format (~0.85 MB). It is the conversion published by the
whisper.cpp project at
[ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad), bundled
unmodified.

**Purpose.** whisper.cpp's built-in VAD uses it to gate and segment speech
before transcription: on the small/tiny whisper tiers it trims non-speech and
suppresses hallucinations on noise; on large-v3-turbo it acts as a speech gate
only. Bundling it makes this work fully offline out of the box — unlike the
transcription/summary models, which the user downloads on request. The app
materializes it into its models directory at launch.

**It is data, not code.** The file contains neural-network weights parsed by
the ggml loader; it is never executed.

**License.** MIT, Copyright (c) 2020-present Silero Team — see the
"Silero VAD model (bundled)" section of [`LICENCE.md`](../../LICENCE.md).

## Verifying provenance

Hugging Face stores the file via git-lfs, and the pointer file publicly
declares the SHA-256 of the content. The bundled file matches it exactly:

```
$ sha256sum assets/models/ggml-silero-v5.1.2.bin
29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf

$ curl -s https://huggingface.co/ggml-org/whisper-vad/raw/main/ggml-silero-v5.1.2.bin
version https://git-lfs.github.com/spec/v1
oid sha256:29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf
size 885098
```

The ggml conversion itself can be regenerated from Silero's own published
weights (the `silero-vad` pip package) with whisper.cpp's
`models/convert-silero-vad-to-ggml.py`, present in the v1.9.1 tag this repo
vendors under `native/whisper.cpp`.
