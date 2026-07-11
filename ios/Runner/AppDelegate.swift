import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let decodeQueue = DispatchQueue(label: "cz.mod42.diktafon.pcm-decode")

  // One export at a time: the picker's delegate is retained here until it
  // calls back (UIKit keeps delegates weak).
  private var pendingSave: DocumentSaveDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiktafonSystem")
    else { return }
    let messenger = registrar.messenger()
    // Counterpart of HostCodecPcmDecoder (lib/services/audio/pcm_decoder.dart):
    // decodes a memo file to raw f32le 16 kHz mono PCM for whisper.
    FlutterMethodChannel(name: "diktafon/pcm_decoder", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "decodeToF32" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let args = call.arguments as? [String: Any],
          let input = args["input"] as? String,
          let output = args["output"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "input/output paths required",
                              details: nil))
          return
        }
        self?.decodeQueue.async {
          do {
            try AppDelegate.decodeToF32(inputPath: input, outputPath: output)
            DispatchQueue.main.async { result(nil) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "decode_failed",
                                  message: error.localizedDescription, details: nil))
            }
          }
        }
      }
    FlutterMethodChannel(name: "diktafon/system", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        switch call.method {
        // Escape hatch for a permanently denied mic permission (iOS never
        // re-prompts): the snackbar's action lands on the app's pane in the
        // system settings.
        case "openAppSettings":
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          result(nil)
        // Export-picker hand-off for archives (§8): file_selector has no
        // save dialog on iOS, so Dart stages the zip (named as it should be
        // saved) and this lets the user land a copy in Files/iCloud/….
        // Answers false when the user backs out.
        case "saveDocument":
          self?.startSaveDocument(
            source: (call.arguments as? [String: Any])?["source"] as? String,
            result: result)
        // Keeps re-downloadable bulk (the models dir, ~1-2 GB) out of
        // iCloud/device backups — App Review rejects apps that back up
        // regenerable data. Counterpart of Android's backup-rules XML (§7.1).
        case "excludeFromBackup":
          guard let path = (call.arguments as? [String: Any])?["path"] as? String
          else {
            result(FlutterError(code: "bad_args", message: "path required",
                                details: nil))
            return
          }
          do {
            var url = URL(fileURLWithPath: path)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
            result(nil)
          } catch {
            result(FlutterError(code: "exclude_failed",
                                message: error.localizedDescription, details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func startSaveDocument(source: String?, result: @escaping FlutterResult) {
    guard let source = source else {
      result(FlutterError(code: "bad_args", message: "source required", details: nil))
      return
    }
    guard pendingSave == nil else {
      result(FlutterError(code: "busy", message: "another save is in progress", details: nil))
      return
    }
    guard let presenter = rootViewController() else {
      result(FlutterError(code: "save_failed", message: "no view controller", details: nil))
      return
    }
    let url = URL(fileURLWithPath: source)
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(url: url, in: .exportToService)
    }
    let delegate = DocumentSaveDelegate { [weak self] saved in
      self?.pendingSave = nil
      result(saved)
    }
    pendingSave = delegate
    picker.delegate = delegate
    presenter.present(picker, animated: true)
  }

  private func rootViewController() -> UIViewController? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
  }

  /// Decodes the first audio track to mono float PCM, resampled to 16 kHz.
  /// AVAssetReaderAudioMixOutput does the decode, downmix and resample in
  /// one pass — the output settings *are* whisper's input format.
  private static func decodeToF32(inputPath: String, outputPath: String) throws {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inputPath))
    guard let track = asset.tracks(withMediaType: .audio).first else {
      throw NSError(domain: "diktafon", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "no audio track in \(inputPath)"])
    }
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderAudioMixOutput(audioTracks: [track], audioSettings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: 16000,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 32,
      AVLinearPCMIsFloatKey: true,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ])
    guard reader.canAdd(output) else {
      throw NSError(domain: "diktafon", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "cannot read \(inputPath) as 16 kHz mono f32"])
    }
    reader.add(output)
    guard reader.startReading() else {
      throw reader.error ?? NSError(domain: "diktafon", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "AVAssetReader failed to start"])
    }

    FileManager.default.createFile(atPath: outputPath, contents: nil)
    guard let sink = FileHandle(forWritingAtPath: outputPath) else {
      reader.cancelReading()
      throw NSError(domain: "diktafon", code: 4, userInfo: [
        NSLocalizedDescriptionKey: "cannot write \(outputPath)"])
    }
    defer { try? sink.close() }

    while let sample = output.copyNextSampleBuffer() {
      guard let block = CMSampleBufferGetDataBuffer(sample) else { continue }
      let length = CMBlockBufferGetDataLength(block)
      if length == 0 { continue }
      // The block buffer may be non-contiguous — copy, don't take a pointer.
      var data = Data(count: length)
      let status = data.withUnsafeMutableBytes {
        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length,
                                   destination: $0.baseAddress!)
      }
      guard status == kCMBlockBufferNoErr else {
        reader.cancelReading()
        throw NSError(domain: "diktafon", code: 5, userInfo: [
          NSLocalizedDescriptionKey: "sample copy failed (\(status))"])
      }
      sink.write(data)
    }
    if reader.status == .failed {
      throw reader.error ?? NSError(domain: "diktafon", code: 6, userInfo: [
        NSLocalizedDescriptionKey: "AVAssetReader failed mid-file"])
    }
  }
}

/// Completion-owning delegate for the export picker; `AppDelegate.pendingSave`
/// keeps it alive for the duration of the dialog.
private final class DocumentSaveDelegate: NSObject, UIDocumentPickerDelegate {
  private let completion: (Bool) -> Void

  init(completion: @escaping (Bool) -> Void) {
    self.completion = completion
  }

  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentsAt urls: [URL]) {
    completion(true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion(false)
  }
}
