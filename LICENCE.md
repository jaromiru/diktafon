# Licence

The Diktafon source code (https://github.com/jaromiru/diktafon) is released
under the MIT License (below), with the exception of the third-party
components listed afterwards, which remain under their own licences.

## MIT License

Copyright (c) 2026 Jaromír Janisch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Third-party components

### whisper.cpp / ggml (vendored)

`native/whisper.cpp/` contains a vendored copy of
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) (including ggml),
Copyright (c) 2023–2026 The ggml authors, licensed under the MIT License.
See `native/whisper.cpp/LICENSE`.

### llama.cpp (vendored)

`native/llama.cpp/` contains a vendored copy of
[llama.cpp](https://github.com/ggml-org/llama.cpp),
Copyright (c) 2023–2026 The ggml authors, licensed under the MIT License.
See `native/llama.cpp/LICENSE`. Both engines are built against the single
ggml tree from this copy.

### Fonts (bundled)

- **Jersey 10** — Copyright 2023 The Soft Type Project Authors
  (https://github.com/scfried/soft-type-jersey), licensed under the
  SIL Open Font License, Version 1.1. See `assets/fonts/OFL-Jersey10.txt`.
- **Space Mono** — Copyright 2016 The Space Mono Project Authors
  (https://github.com/googlefonts/spacemono), licensed under the
  SIL Open Font License, Version 1.1. See `assets/fonts/OFL-SpaceMono.txt`.

### Silero VAD model (bundled)

`assets/models/ggml-silero-v5.1.2.bin` is a ggml conversion (via
[ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad)) of the
[Silero VAD](https://github.com/snakers4/silero-vad) voice-activity-detection
model, Copyright (c) 2020-present Silero Team, licensed under the MIT
License. It is distributed with this repository and inside the app.

### Whisper models (downloaded at runtime)

Speech-recognition models are not distributed with this repository or the app;
they are downloaded by the user at runtime from
[ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp) on
Hugging Face. These are ggml conversions of OpenAI's Whisper models, released
under the MIT License.

### Qwen3 models (downloaded at runtime)

Summarization models are likewise not distributed with this repository or the
app; they are downloaded by the user at runtime from the official
[Qwen GGUF repositories](https://huggingface.co/Qwen) on Hugging Face
(e.g. `Qwen/Qwen3-1.7B-GGUF`). The Qwen3 models are released by the Qwen team
under the Apache License 2.0.

### Dart/Flutter package dependencies

Packages declared in `pubspec.yaml` are fetched from pub.dev at build time and
are not vendored here. Each is distributed under its own licence; the licences
of all packages compiled into the app are bundled by Flutter and viewable
in-app via the standard licences page.
