import Foundation
import AVFoundation
import MLX

public class SpeechRecognizer {
    public static let shared = SpeechRecognizer()
    
    private init() {}
    
    // MARK: - Speech Recognition Core
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecording = false
    private var isModelLoaded = false
    private var currentSession: RecordingSession?
    
    public enum SpeechModel {
        case tiny    // 39M parameters
        case base    // 74M parameters
        case small   // 244M parameters
        case medium  // 769M parameters
        case large    // 1550M parameters
        
        var modelName: String {
            switch self {
            case .tiny: return "whisper-tiny"
            case .base: return "whisper-base"
            case .small: return "whisper-small"
            case .medium: return "whisper-medium"
            case .large: return "whisper-large"
            }
        }
        
        var modelSize: Int64 {
            switch self {
            case .tiny: return 39_000_000
            case .base: return 74_000_000
            case .small: return 244_000_000
            case .medium: return 769_000_000
            case .large: return 1_550_000_000
            }
        }
        
        var description: String {
            switch self {
            case .tiny: return "Tiny (39M)"
            case .base: return "Base (74M)"
            case .small: return "Small (244M)"
            case .medium: return "Medium (769M)"
            case .large: return "Large (1.5B)"
            }
        }
    }
    
    private var currentModel: SpeechModel = .base
    
    // MARK: - Recording Setup
    
    public func requestPermission() async -> Bool {
        // In macOS, we use AVAudioEngine's built-in permission handling
        do {
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            
            // Try to start the engine to trigger permission request
            try audioEngine.start()
            audioEngine.stop()
            
            return true
        } catch {
            print("Error requesting microphone permission: \(error)")
            return false
        }
    }
    
    public func setupAudioSession() async throws {
        // In macOS, we don't need AVAudioSession setup
        print("Audio session configured successfully")
    }
    
    // MARK: - Model Management
    
    public func loadSpeechModel(_ model: SpeechModel) async throws {
        guard !isModelLoaded else { return }
        
        let modelName = model.modelName
        print("Loading speech recognition model: \(modelName)")
        
        // In a real implementation, this would load the actual Whisper model
        // For now, we'll simulate the loading process
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        currentModel = model
        isModelLoaded = true
        print("Speech recognition model loaded successfully")
    }
    
    public func unloadModel() {
        isModelLoaded = false
        print("Speech recognition model unloaded")
    }
    
    // MARK: - Recording Control
    
    public func startRecording() async throws -> RecordingSession {
        guard !isRecording else {
            throw SpeechError.alreadyRecording
        }
        
        guard isModelLoaded else {
            throw SpeechError.modelNotLoaded
        }
        
        try await setupAudioSession()
        
        // Initialize audio engine
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        // Configure audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        
        // Install tap on input node
        let session = RecordingSession(id: UUID().uuidString, startTime: Date())
        
        // Store session for later access
        self.currentSession = session
        
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Start audio engine
        try audioEngine?.start()
        isRecording = true
        
        print("Recording started")
        return session
    }
    
    public func stopRecording() async throws -> [SpeechSegment] {
        guard isRecording else {
            throw SpeechError.notRecording
        }
        
        // Stop audio engine
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Deactivate audio session
        // try audioSession?.setActive(false)
        
        isRecording = false
        
        print("Recording stopped")
        
        // Return processed speech segments
        return await processRecordedAudio()
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Convert audio buffer to MLX-compatible format
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        let audioData = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        
        // Add to session audio data
        guard var session = currentSession else { return }
        
        DispatchQueue.main.async {
            session.addAudioData(audioData)
            self.currentSession = session
            
            // Process in chunks for real-time recognition
            if session.audioData.count >= 16000 * 5 { // 5 seconds of audio
                Task {
                    await self.processRealTimeAudio(&session)
                    self.currentSession = session
                }
            }
        }
    }
    
    private func processRealTimeAudio(_ session: inout RecordingSession) async {
        let audioData = session.audioData
        session.clearAudioData()
        
        do {
            let text = try await performWhisperInference(audioData: audioData)
            if !text.isEmpty {
                let segment = SpeechSegment(
                    text: text,
                    startTime: session.startTime,
                    endTime: Date(),
                    confidence: 0.8,
                    language: "auto"
                )
                session.addSegment(segment)
                
                // Notify delegate or update UI
                await MainActor.run {
                    print("Real-time speech: \(text)")
                }
            }
        } catch {
            print("Real-time speech recognition error: \(error)")
        }
    }
    
    private func processRecordedAudio() async -> [SpeechSegment] {
        // In production, this would process the complete audio recording
        // For now, return mock segments
        
        let mockSegments = [
            SpeechSegment(
                text: "这是一个语音识别的示例文本",
                startTime: Date(),
                endTime: Date(),
                confidence: 0.85,
                language: "zh"
            ),
            SpeechSegment(
                text: "This is an example of speech recognition",
                startTime: Date(),
                endTime: Date(),
                confidence: 0.90,
                language: "en"
            )
        ]
        
        return mockSegments
    }
    
    // MARK: - Whisper Inference
    
    private func performWhisperInference(audioData: [Float]) async throws -> String {
        // Simulate Whisper inference
        // In production, this would:
        // 1. Preprocess audio data (normalize, resample if needed)
        // 2. Convert to mel spectrogram
        // 3. Run through Whisper encoder-decoder
        // 4. Decode output tokens
        // 5. Apply language detection and post-processing
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock transcription based on audio characteristics
        let energy = audioData.map { abs($0) }.reduce(0, +) / Float(audioData.count)
        
        if energy > 0.1 {
            return "这是语音识别的示例文本"
        } else {
            return "语音能量较低，请靠近麦克风说话"
        }
    }
    
    // MARK: - Language Detection
    
    public func detectLanguage(from audioData: [Float]) async -> String {
        // In production, this would use Whisper's built-in language detection
        // For now, return mock detection
        
        let energy = audioData.map { abs($0) }.reduce(0, +) / Float(audioData.count)
        
        // Simple heuristic based on energy patterns
        if energy > 0.15 {
            return "zh" // Chinese
        } else {
            return "en" // English
        }
    }
    
    // MARK: - Model Information
    
    public func getModelInfo() -> ModelInfo {
        return ModelInfo(
            name: currentModel.modelName,
            size: currentModel.modelSize,
            description: currentModel.description,
            isLoaded: isModelLoaded,
            supportedLanguages: getSupportedLanguages()
        )
    }
    
    private func getSupportedLanguages() -> [Language] {
        return [
            Language(code: "en", name: "English", nativeName: "English"),
            Language(code: "zh", name: "Chinese", nativeName: "中文"),
            Language(code: "ja", name: "Japanese", nativeName: "日本語"),
            Language(code: "ko", name: "Korean", nativeName: "한국어"),
            Language(code: "es", name: "Spanish", nativeName: "Español"),
            Language(code: "fr", name: "French", nativeName: "Français"),
            Language(code: "de", name: "German", nativeName: "Deutsch"),
            Language(code: "ru", name: "Russian", nativeName: "Русский"),
            Language(code: "pt", name: "Portuguese", nativeName: "Português"),
            Language(code: "it", name: "Italian", nativeName: "Italiano"),
            Language(code: "ar", name: "Arabic", nativeName: "العربية"),
            Language(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
            Language(code: "th", name: "Thai", nativeName: "ไทย"),
            Language(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt")
        ]
    }
    
    // MARK: - Performance Optimization
    
    public func optimizeForDevice() async {
        // Detect device capabilities and optimize model accordingly
        let device = Device.current
        
        if device.isAppleSilicon {
            print("Optimizing Whisper for Apple Silicon: \(device)")
            // In production, this would:
            // - Use Metal acceleration
            // - Optimize memory usage
            // - Enable quantization if supported
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        print("Whisper model optimized for current device")
    }
    
    public func getPerformanceMetrics() -> PerformanceMetrics {
        // Return mock performance metrics
        return PerformanceMetrics(
            inferenceTime: 2.0, // seconds
            memoryUsage: 800,   // MB
            deviceUtilization: 0.65, // percentage
            realTimeFactor: 0.8 // real-time processing capability
        )
    }
    
    // MARK: - Error Types
    
    public enum SpeechError: Error, LocalizedError {
        case permissionDenied
        case alreadyRecording
        case notRecording
        case modelNotLoaded
        case audioSessionFailed
        case recognitionFailed
        case deviceNotSupported
        
        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone permission denied"
            case .alreadyRecording:
                return "Already recording"
            case .notRecording:
                return "Not currently recording"
            case .modelNotLoaded:
                return "Speech recognition model not loaded"
            case .audioSessionFailed:
                return "Failed to configure audio session"
            case .recognitionFailed:
                return "Speech recognition failed"
            case .deviceNotSupported:
                return "Device not supported"
            }
        }
    }
}

// MARK: - Supporting Structures

public struct RecordingSession {
    public let id: String
    public let startTime: Date
    public private(set) var audioData: [Float] = []
    public private(set) var segments: [SpeechSegment] = []
    
    public mutating func addAudioData(_ data: [Float]) {
        audioData.append(contentsOf: data)
    }
    
    public mutating func clearAudioData() {
        audioData.removeAll()
    }
    
    public mutating func addSegment(_ segment: SpeechSegment) {
        segments.append(segment)
    }
}

public struct SpeechSegment {
    public let text: String
    public let startTime: Date
    public let endTime: Date
    public let confidence: Double
    public let language: String
}

public struct ModelInfo {
    public let name: String
    public let size: Int64
    public let description: String
    public let isLoaded: Bool
    public let supportedLanguages: [Language]
}

public struct Language {
    public let code: String
    public let name: String
    public let nativeName: String
}

public struct PerformanceMetrics {
    public let inferenceTime: Double
    public let memoryUsage: Int
    public let deviceUtilization: Double
    public let realTimeFactor: Double
}

// MARK: - Audio Utilities

public class AudioProcessor {
    public static let shared = AudioProcessor()
    
    private init() {}
    
    public func normalizeAudio(_ audioData: [Float]) -> [Float] {
        guard !audioData.isEmpty else { return [] }
        
        let maxValue = audioData.map { abs($0) }.max() ?? 1.0
        guard maxValue > 0 else { return audioData }
        
        return audioData.map { $0 / maxValue }
    }
    
    public func applyNoiseReduction(_ audioData: [Float]) -> [Float] {
        // Simple noise reduction - in production, use more sophisticated algorithms
        let threshold: Float = 0.01
        return audioData.map { abs($0) < threshold ? 0 : $0 }
    }
    
    public func resampleAudio(_ audioData: [Float], from sampleRate: Int, to targetSampleRate: Int) -> [Float] {
        if sampleRate == targetSampleRate {
            return audioData
        }
        
        // Simple linear interpolation - in production, use proper resampling
        let ratio = Double(sampleRate) / Double(targetSampleRate)
        let targetCount = Int(Double(audioData.count) / ratio)
        
        var resampled: [Float] = []
        for i in 0..<targetCount {
            let sourceIndex = Double(i) * ratio
            let lowerIndex = Int(sourceIndex)
            let upperIndex = min(lowerIndex + 1, audioData.count - 1)
            let fraction = sourceIndex - Double(lowerIndex)
            
            let interpolatedValue = audioData[lowerIndex] * (1 - Float(fraction)) + audioData[upperIndex] * Float(fraction)
            resampled.append(interpolatedValue)
        }
        
        return resampled
    }
}