#!/usr/bin/env bash
# Builds the dk_whisper/dk_llama engines for iOS as two dynamic xcframeworks
# in ios/Frameworks/ (referenced by Runner.xcodeproj: linked + embedded &
# signed). Two slices each:
#   device    arm64  — ggml Metal backend, shaders embedded in the binary
#                      (GGML_METAL_EMBED_LIBRARY, the standard iOS route);
#   simulator arm64  — CPU-only: ggml's Metal path doesn't run on the
#                      simulator's Metal implementation.
# Run on a Mac with Xcode + cmake + ninja (docs/tools.md §assel-mac).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
build="$root/build/ios-native"
out="$root/ios/Frameworks"

common=(
  -DCMAKE_SYSTEM_NAME=iOS
  -DCMAKE_OSX_ARCHITECTURES=arm64
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
  -DCMAKE_BUILD_TYPE=Release
  -DGGML_NATIVE=OFF
)

cmake -G Ninja -S "$root/native" -B "$build/device" "${common[@]}" \
  -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON
ninja -C "$build/device" diktafon_whisper diktafon_llama

cmake -G Ninja -S "$root/native" -B "$build/simulator" "${common[@]}" \
  -DCMAKE_OSX_SYSROOT=iphonesimulator -DGGML_METAL=OFF
ninja -C "$build/simulator" diktafon_whisper diktafon_llama

mkdir -p "$out"
for engine in diktafon_whisper diktafon_llama; do
  for sdk in device simulator; do
    # CMake's default framework Info.plist lacks MinimumOSVersion, which
    # App Store validation requires of every embedded framework.
    plutil -replace MinimumOSVersion -string "13.0" \
      "$build/$sdk/$engine.framework/Info.plist"
  done
  rm -rf "$out/$engine.xcframework"
  xcodebuild -create-xcframework \
    -framework "$build/device/$engine.framework" \
    -framework "$build/simulator/$engine.framework" \
    -output "$out/$engine.xcframework"
done
