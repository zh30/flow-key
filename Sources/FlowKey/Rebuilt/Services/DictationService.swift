import AVFoundation
import AppKit
import Observation
import Speech

enum DictationPermission: Equatable {
    case microphone
    case speechRecognition

    var name: String {
        switch self {
        case .microphone:
            return L10n.string("Microphone")
        case .speechRecognition:
            return L10n.string("Speech Recognition")
        }
    }
}

enum DictationTextMerger {
    static func merge(prefix: String, transcript: String) -> String {
        guard prefix.isEmpty == false else { return transcript }
        guard transcript.isEmpty == false else { return prefix }

        let needsSeparator = prefix.last?.isWhitespace == false
        return prefix + (needsSeparator ? " " : "") + transcript
    }
}

@MainActor
@Observable
final class DictationService {
    enum State: Equatable {
        case idle
        case requestingPermission
        case recording(onDevice: Bool)
        case permissionDenied(DictationPermission)
        case unavailable
        case failed(String)

        var isRecording: Bool {
            if case .recording = self { return true }
            return false
        }

        var message: String? {
            switch self {
            case .idle:
                return nil
            case .requestingPermission:
                return L10n.string("Requesting access…")
            case .recording(let onDevice):
                return onDevice
                    ? L10n.string("Listening on device…")
                    : L10n.string("Listening…")
            case .permissionDenied(let permission):
                return L10n.format(
                    "Allow %@ in Privacy & Security.",
                    permission.name
                )
            case .unavailable:
                return L10n.string(
                    "Speech recognition is unavailable for this language."
                )
            case .failed(let message):
                return message
            }
        }
    }

    private(set) var state: State = .idle
    private(set) var transcript = ""

    @ObservationIgnored
    private let audioEngine = AVAudioEngine()

    @ObservationIgnored
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    @ObservationIgnored
    private var recognitionTask: SFSpeechRecognitionTask?

    @ObservationIgnored
    private var isStopping = false

    @ObservationIgnored
    private var hasInputTap = false

    func start(localeIdentifier: String) async {
        stop()
        transcript = ""
        state = .requestingPermission

        guard await speechRecognitionIsAuthorized() else {
            state = .permissionDenied(.speechRecognition)
            return
        }

        guard await microphoneIsAuthorized() else {
            state = .permissionDenied(.microphone)
            return
        }

        guard
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
            recognizer.isAvailable
        else {
            state = .unavailable
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = true

        let usesOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        if usesOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        recognitionRequest = request
        isStopping = false

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        stop()
                    }
                }

                if let error, isStopping == false {
                    finishWithError(error)
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: recordingFormat
        ) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        hasInputTap = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
            state = .recording(onDevice: usesOnDeviceRecognition)
        } catch {
            finishWithError(error)
        }
    }

    func stop() {
        isStopping = true

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if state.isRecording || state == .requestingPermission {
            state = .idle
        }
    }

    func openPrivacySettings(for permission: DictationPermission) {
        let anchor = switch permission {
        case .microphone:
            "Privacy_Microphone"
        case .speechRecognition:
            "Privacy_SpeechRecognition"
        }
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func speechRecognitionIsAuthorized() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            return status == .authorized
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func microphoneIsAuthorized() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func finishWithError(_ error: Error) {
        let message = error.localizedDescription
        stop()
        state = .failed(message)
    }
}
